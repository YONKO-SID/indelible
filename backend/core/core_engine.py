import hashlib
import hmac
from datetime import datetime

import cv2
import numpy as np
import pywt
import reedsolo

# --- CONFIGURATION ---
SECRET_KEY = b"indelible_hackathon_key"

DELTA = 30  # QIM Quantization Step Size
INPUT_IMAGE = "test.jpg"
OUTPUT_IMAGE = "watermarked_final.png"

# Initialize Reed-Solomon Codec
# 32 ECC symbols can correct up to 16 completely corrupted bytes.
rs = reedsolo.RSCodec(32)


# --- UTILITIES ---
def bytes_to_bits(byte_data):
    """Converts bytes to a flat numpy array of 1s and 0s."""
    return np.unpackbits(np.frombuffer(byte_data, dtype=np.uint8))


def bits_to_bytes(bit_array):
    """Converts a flat numpy array of 1s and 0s back to bytes."""
    return np.packbits(bit_array).tobytes()


# --- MODULE 1: CRYPTOGRAPHY & PAYLOAD ---
def generate_payload(creator_id: str):
    """Generates an HMAC signed, Reed-Solomon encoded binary payload."""
    timestamp = datetime.utcnow().isoformat()
    message = f"{creator_id}|{timestamp}"

    # Generate HMAC Signature (first 16 chars to save space)
    signature = hmac.new(SECRET_KEY, message.encode(), hashlib.sha256).hexdigest()[:16]
    full_payload_str = f"{message}|{signature}"

    print(f"[+] Raw Payload: {full_payload_str}")

    # Encode with Reed-Solomon
    rs_encoded_bytes = rs.encode(full_payload_str.encode("utf-8"))

    # Convert to flat bit array for embedding
    payload_bits = bytes_to_bits(rs_encoded_bytes)
    print(f"[+] Encoded length: {len(payload_bits)} bits")

    return payload_bits, len(payload_bits)


def verify_payload(extracted_bits, payload_length):
    """Decodes RS, verifies HMAC, and returns the original data."""
    # Truncate any garbage bits extracted from the end of the matrix
    extracted_bits = extracted_bits[:payload_length]
    extracted_bytes = bits_to_bytes(extracted_bits)

    try:
        # RS Decode (This is where Lagrange Interpolation fixes the corrupted bytes)
        decoded_bytes = rs.decode(extracted_bytes)[0]
        decoded_str = decoded_bytes.decode("utf-8")
    except reedsolo.ReedSolomonError:
        return "[!] Error: Payload too corrupted to recover."

    # Parse and Verify
    parts = decoded_str.split("|")
    if len(parts) != 3:
        return "[!] Error: Invalid payload structure."

    creator_id, timestamp, received_sig = parts
    expected_message = f"{creator_id}|{timestamp}"
    expected_sig = hmac.new(
        SECRET_KEY, expected_message.encode(), hashlib.sha256
    ).hexdigest()[:16]

    if hmac.compare_digest(received_sig, expected_sig):
        return f"[V] SUCCESS! Verified Creator: {creator_id} at {timestamp}"
    else:
        return "[!] Error: HMAC Signature Forgery Detected."


# --- MODULE 2: DWT-DCT WATERMARK ENGINE ---
def embed_watermark(image_path, payload_bits, output_path=None):
    """Embeds bits into the mid-frequencies of the Y-channel."""
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise FileNotFoundError(f"Could not load {image_path}")

    if output_path is None:
        output_path = OUTPUT_IMAGE

    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    Y, Cr, Cb = cv2.split(img_ycrcb)

    # 1. DWT
    coeffs = pywt.dwt2(np.float32(Y), "haar")
    LL, (LH, HL, HH) = coeffs

    # 2. DCT on LL band
    dct_LL = cv2.dct(LL)

    # 3. QIM Embedding in mid-frequencies
    rows, cols = dct_LL.shape
    bit_idx = 0

    # Start at (4,4) to skip the highly sensitive DC/low frequencies
    for i in range(4, min(100, rows)):
        for j in range(4, min(100, cols)):
            if bit_idx >= len(payload_bits):
                break

            bit = payload_bits[bit_idx]
            coeff = dct_LL[i, j]

            # Quantization Index Modulation
            quantized = round(coeff / DELTA) * DELTA
            if bit == 1:
                if int(quantized / DELTA) % 2 == 0:
                    quantized += DELTA
            else:
                if int(quantized / DELTA) % 2 != 0:
                    quantized -= DELTA

            dct_LL[i, j] = quantized
            bit_idx += 1

    # 4. Inverse Math
    watermarked_LL = cv2.idct(dct_LL)
    watermarked_Y = pywt.idwt2((watermarked_LL, (LH, HL, HH)), "haar")
    watermarked_Y = np.uint8(np.clip(watermarked_Y, 0, 255))

    img_final = cv2.cvtColor(cv2.merge((watermarked_Y, Cr, Cb)), cv2.COLOR_YCrCb2BGR)
    cv2.imwrite(output_path, img_final)
    print(f"[+] Watermarked image saved as {output_path}")


def extract_watermark(image_path, payload_length):
    """Extracts bits from the mid-frequencies using QIM."""
    img_bgr = cv2.imread(image_path)
    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    Y, Cr, Cb = cv2.split(img_ycrcb)

    coeffs = pywt.dwt2(np.float32(Y), "haar")
    LL, _ = coeffs
    dct_LL = cv2.dct(LL)

    extracted_bits = []
    rows, cols = dct_LL.shape

    for i in range(4, min(100, rows)):
        for j in range(4, min(100, cols)):
            if len(extracted_bits) >= payload_length:
                break

            coeff = dct_LL[i, j]
            quantized = round(coeff / DELTA)
            extracted_bits.append(int(quantized) % 2)

    return np.array(extracted_bits, dtype=np.uint8)


# --- EXECUTION ---
if __name__ == "__main__":
    print("=== INDELIBLE CORE ENGINE TEST ===")

    # 1. Generate the Cryptographic Payload
    my_bits, bit_length = generate_payload("Sid_Hackathon_2026")

    # 2. Embed it into the image
    embed_watermark(INPUT_IMAGE, my_bits)

    # 3. Simulate uploading/downloading by reading the newly saved image
    print("\n[+] Extracting payload from protected image...")
    recovered_bits = extract_watermark(OUTPUT_IMAGE, bit_length)

    # 4. Verify the math
    result = verify_payload(recovered_bits, bit_length)
    print(result)
