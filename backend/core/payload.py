import hashlib
import hmac
from datetime import datetime

import numpy as np
import reedsolo


ANCHOR_BITS = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0], dtype=np.uint8)


def string_to_bits(s: str) -> np.ndarray:
    bytes_val = s.encode("utf-8")
    bits = np.unpackbits(np.frombuffer(bytes_val, dtype=np.uint8))
    return bits


def bytes_to_bits(b: bytes) -> np.ndarray:
    return np.unpackbits(np.frombuffer(b, dtype=np.uint8))


def bits_to_bytes(bits: np.ndarray) -> bytes:
    if len(bits) % 8 != 0:
        bits = np.pad(bits, (0, 8 - len(bits) % 8), "constant")
    return np.packbits(bits).tobytes()


def create_payload(creator_id: str, secret_key: bytes) -> tuple:
    """
    Create payload: CreatorID | Timestamp | HMAC
    Returns: (payload_string, payload_bits, full_block_bits)
    """
    # Pad creator_id to exactly 24 characters to ensure fixed block length
    creator_id_padded = creator_id.ljust(24)
    # Use second-resolution timestamp to save characters (19 chars vs 26 chars)
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S")
    message = f"{creator_id_padded}|{timestamp}"
    # Use first 16 bytes of HMAC-SHA256 (32 hex characters vs 64 hex characters)
    signature = hmac.new(secret_key, message.encode("utf-8"), hashlib.sha256).digest()[:16]

    # Full payload string
    payload_string = f"{message}|{signature.hex()}"
    payload_bits = string_to_bits(payload_string)

    # Reed-Solomon encoding for error correction
    rs = reedsolo.RSCodec(nsym=128)  # 128 parity symbols (upgraded for higher blur/crop resilience)
    rs_encoded = rs.encode(bytearray(payload_string.encode("utf-8")))
    rs_encoded_bits = bytes_to_bits(bytes(rs_encoded))

    # Prepend anchor bits to the RS bits
    full_block = np.concatenate([ANCHOR_BITS, rs_encoded_bits])

    return payload_string, payload_bits, full_block


def verify_payload(extracted_bits: np.ndarray, secret_key: bytes) -> dict:
    """
    Decode RS, verify HMAC, return verification result
    """
    if len(extracted_bits) == 1320:
        extracted_bits = extracted_bits[16:]
        nsym_val = 96
    elif len(extracted_bits) == 1656:
        extracted_bits = extracted_bits[16:]
        nsym_val = 128
    else:
        # Backward compatibility or fallback guessing
        if len(extracted_bits) == 1304:
            nsym_val = 96
        elif len(extracted_bits) == 1640:
            nsym_val = 128
        else:
            nsym_val = 128

    rs = reedsolo.RSCodec(nsym=nsym_val)
    try:
        decoded_bytes = rs.decode(bytearray(bits_to_bytes(extracted_bits)))
        # Reedsolo returns a tuple (decoded, decoded_full, erasures) in some versions
        if isinstance(decoded_bytes, tuple):
            decoded_bytes = decoded_bytes[0]
        decoded_string = decoded_bytes.decode("utf-8", errors="ignore")
    except Exception as e:
        return {"verified": False, "error": f"RS decode failed: {str(e)}"}

    # Parse payload
    parts = decoded_string.split("|")
    if len(parts) != 3:
        return {"verified": False, "error": "Invalid payload format"}

    creator_id, timestamp, received_hmac = parts
    creator_id_clean = creator_id.strip()

    # Try verifying with padded creator_id (new scheme)
    creator_id_padded = creator_id_clean.ljust(24)
    expected_message_padded = f"{creator_id_padded}|{timestamp}"
    expected_hmac_padded = hmac.new(
        secret_key, expected_message_padded.encode("utf-8"), hashlib.sha256
    ).digest()[:16].hex()

    if hmac.compare_digest(received_hmac, expected_hmac_padded):
        return {"verified": True, "creator_id": creator_id_clean, "timestamp": timestamp}

    # Try verifying with original/unpadded creator_id (legacy scheme)
    expected_message_legacy = f"{creator_id_clean}|{timestamp}"
    expected_hmac_legacy = hmac.new(
        secret_key, expected_message_legacy.encode("utf-8"), hashlib.sha256
    ).digest()[:16].hex()

    if hmac.compare_digest(received_hmac, expected_hmac_legacy):
        return {"verified": True, "creator_id": creator_id_clean, "timestamp": timestamp}

    return {"verified": False, "error": "HMAC mismatch"}
