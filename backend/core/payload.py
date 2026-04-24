import hmac
import hashlib
import reedsolo
from datetime import datetime
import numpy as np

def string_to_bits(s: str) -> np.ndarray:
    bytes_val = s.encode('utf-8')
    bits = np.unpackbits(np.frombuffer(bytes_val, dtype=np.uint8))
    return bits

def bytes_to_bits(b: bytes) -> np.ndarray:
    return np.unpackbits(np.frombuffer(b, dtype=np.uint8))

def bits_to_bytes(bits: np.ndarray) -> bytes:
    if len(bits) % 8 != 0:
        bits = np.pad(bits, (0, 8 - len(bits) % 8), 'constant')
    return np.packbits(bits).tobytes()

def create_payload(creator_id: str, secret_key: bytes) -> tuple:
    """
    Create payload: CreatorID | Timestamp | HMAC
    Returns: (payload_string, payload_bits, rs_encoded_bits)
    """
    timestamp = datetime.utcnow().isoformat()
    message = f"{creator_id}|{timestamp}"
    signature = hmac.new(secret_key, message.encode('utf-8'), hashlib.sha256).digest()
    
    # Full payload string
    payload_string = f"{message}|{signature.hex()}"
    payload_bits = string_to_bits(payload_string)
    
    # Reed-Solomon encoding for error correction
    rs = reedsolo.RSCodec(nsym=64)  # 64 parity symbols
    rs_encoded = rs.encode(bytearray(payload_string.encode('utf-8')))
    rs_encoded_bits = bytes_to_bits(bytes(rs_encoded))
    
    return payload_string, payload_bits, rs_encoded_bits

def verify_payload(extracted_bits: np.ndarray, secret_key: bytes) -> dict:
    """
    Decode RS, verify HMAC, return verification result
    """
    rs = reedsolo.RSCodec(nsym=64)
    try:
        decoded_bytes = rs.decode(bytearray(bits_to_bytes(extracted_bits)))
        # Reedsolo returns a tuple (decoded, decoded_full, erasures) in some versions
        if isinstance(decoded_bytes, tuple):
            decoded_bytes = decoded_bytes[0]
        decoded_string = decoded_bytes.decode('utf-8', errors='ignore')
    except Exception as e:
        return {"verified": False, "error": f"RS decode failed: {str(e)}"}
    
    # Parse payload
    parts = decoded_string.split('|')
    if len(parts) != 3:
        return {"verified": False, "error": "Invalid payload format"}
    
    creator_id, timestamp, received_hmac = parts
    
    # Verify HMAC
    expected_message = f"{creator_id}|{timestamp}"
    expected_hmac = hmac.new(secret_key, expected_message.encode('utf-8'), hashlib.sha256).hexdigest()
    
    if hmac.compare_digest(received_hmac, expected_hmac):
        return {
            "verified": True,
            "creator_id": creator_id,
            "timestamp": timestamp
        }
    return {"verified": False, "error": "HMAC mismatch"}
