import hashlib
import hmac
from datetime import datetime , timezone

import cv2
import numpy as np
import pywt
import reedsolo

# --- CONFIGURATION ---
import os
from dotenv import load_dotenv
load_dotenv()

# Prefer environment-provided secret, fallback to built-in test key for local dev.
_SECRET = os.getenv("SECRET_KEY", "indelible_hackathon_key")
if _SECRET == "indelible_hackathon_key":
    # runtime warning for dev mode
    print("[WARN] Using bundled fallback SECRET_KEY — do not use in production.")
SECRET_KEY = _SECRET.encode()

DELTA = 30  # QIM Quantization Step Size
INPUT_IMAGE = "test_source.png"
OUTPUT_IMAGE = "watermarked_final.png"

# Initialize Reed-Solomon Codec
# 32 ECC symbols can correct up to 16 completely corrupted bytes.
rs = reedsolo.RSCodec(32)

# 16-bit static synchronization anchor (Hex: 0xAAAA)
ANCHOR_BITS = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], dtype=np.uint8)

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
    timestamp = datetime.now(timezone.utc).isoformat()
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

    # payload_bits is RS-encoded output
    full_payload = np.concatenate((ANCHOR_BITS, payload_bits))
    return full_payload, len(payload_bits)


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

    # Calculate available capacity (skipping the first 4 rows/cols for visual fidelity)
    max_row = min(100, rows)
    max_col = min(100, cols)
    capacity = (max_row - 4) * (max_col - 4)
    
    if capacity < len(payload_bits):
        raise ValueError("Image LL band too small for payload!")

    # Tile the payload to fill the entire capacity
    repeats = int(np.ceil(capacity / len(payload_bits)))
    tiled_bits = np.tile(payload_bits, repeats)[:capacity]
    
    bit_idx = 0
    for i in range(4, max_row):
        for j in range(4, max_col):
            bit = tiled_bits[bit_idx]
            coeff = dct_LL[i, j]
            
            # QIM Math
            quantized = round(coeff / DELTA) * DELTA
            if bit == 1:
                if int(quantized / DELTA) % 2 == 0: quantized += DELTA
            else:
                if int(quantized / DELTA) % 2 != 0: quantized -= DELTA
                
            dct_LL[i, j] = quantized
            bit_idx += 1

    # 4. Inverse Math
    watermarked_LL = cv2.idct(dct_LL)
    watermarked_Y = pywt.idwt2((watermarked_LL, (LH, HL, HH)), "haar")
    watermarked_Y = np.uint8(np.clip(watermarked_Y, 0, 255))

    img_final = cv2.cvtColor(cv2.merge((watermarked_Y, Cr, Cb)), cv2.COLOR_YCrCb2BGR)
    cv2.imwrite(output_path, img_final)
    print(f"[+] Watermarked image saved as {output_path}")


def extract_watermark_robust(image_path, payload_length):
    """Brute forces spatial alignment to recover the tiled payload."""
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        return {"verified": False, "error": "Image read failure"}

    anchor_len = len(ANCHOR_BITS)
    target_extract_len = anchor_len + payload_length
    
    # Brute force search grid: -10 to +10 pixels in both X and Y
    # We step by 2 to halve the CPU time, as DWT is somewhat resilient to 1px shifts
    for dx in range(-10, 11, 2):
        for dy in range(-10, 11, 2):
            
            # 1. Translate the matrix (Shift the image)
            M = np.float32([[1, 0, dx], [0, 1, dy]])
            shifted_bgr = cv2.warpAffine(img_bgr, M, (img_bgr.shape[1], img_bgr.shape[0]))
            
            # 2. Standard Extraction Math
            img_ycrcb = cv2.cvtColor(shifted_bgr, cv2.COLOR_BGR2YCrCb)
            Y = img_ycrcb[:, :, 0]
            
            coeffs = pywt.dwt2(np.float32(Y), "haar")
            LL, _ = coeffs
            dct_LL = cv2.dct(LL)
            
            extracted_bits = []
            rows, cols = dct_LL.shape
            
            for i in range(4, min(100, rows)):
                for j in range(4, min(100, cols)):
                    if len(extracted_bits) >= target_extract_len:
                        break
                    coeff = dct_LL[i, j]
                    quantized = round(coeff / DELTA)
                    extracted_bits.append(int(quantized) % 2)
                    
            if len(extracted_bits) < target_extract_len:
                continue

            extracted_bits = np.array(extracted_bits, dtype=np.uint8)
            
            # 3. The Fast-Fail Check
            extracted_anchor = extracted_bits[:anchor_len]
            hamming_distance = np.sum(extracted_anchor != ANCHOR_BITS)
            
            # If distance <= 3, we found the exact geometric alignment
            if hamming_distance <= 3:
                print(f"[+] Alignment lock found at shift (x:{dx}, y:{dy})")
                payload_only = extracted_bits[anchor_len:target_extract_len]
                
                # Pass to Reed-Solomon/HMAC verification
                result_str = verify_payload(payload_only, payload_length)
                if "[V] SUCCESS" in result_str:
                    return {
                        "verified": True, 
                        "shift_detected": (dx, dy),
                        "raw_result": result_str
                    }

    return {"verified": False, "error": "No alignment lock found"}


# --- EXECUTION ---
# --- EXECUTION ---
if __name__ == "__main__":
    print("=== INDELIBLE CORE ENGINE TEST ===")

    # 1. Generate the Cryptographic Payload
    # Note: my_bits now includes the 16-bit anchor prepended to it
    my_bits, rs_bit_length = generate_payload("Sid_Hackathon_2026")

    # 2. Embed it into the image with redundancy tiling
    embed_watermark(INPUT_IMAGE, my_bits)

    # 3. Test extraction with spatial brute-forcing
    print("\n[+] Extracting payload from protected image...")
    result = extract_watermark_robust(OUTPUT_IMAGE, rs_bit_length)
    
    # 4. Print the final verification dictionary
    print("\n[+] Final Output:")
    print(result)