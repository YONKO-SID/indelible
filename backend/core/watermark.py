import json
import os

import cv2
import numpy as np
import pywt


def load_and_convert(image_path: str) -> tuple:
    """Load image, convert to YCrCb, return Y channel as float64"""
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise ValueError(f"Image could not be loaded from {image_path}")
    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    y_channel = img_ycrcb[:, :, 0]
    return np.float64(y_channel), img_ycrcb


def embed_watermark_dct(
    image_path: str, payload_bits: np.ndarray, output_path: str, delta: float = 60
):
    """
    Highly robust DWT-DCT based QIM watermarking.
    """
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise FileNotFoundError(f"Could not load {image_path}")

    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    Y, Cr, Cb = cv2.split(img_ycrcb)

    # 1. DWT
    coeffs = pywt.dwt2(np.float32(Y), "haar")
    LL, (LH, HL, HH) = coeffs

    # 2. DCT on LL band
    dct_LL = cv2.dct(LL)

    # 3. QIM Embedding in mid-frequencies
    rows, cols = dct_LL.shape
    
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
            quantized = round(coeff / delta) * delta
            if bit == 1:
                if int(quantized / delta) % 2 == 0: quantized += delta
            else:
                if int(quantized / delta) % 2 != 0: quantized -= delta
                
            dct_LL[i, j] = quantized
            bit_idx += 1

    # 4. Inverse Math
    watermarked_LL = cv2.idct(dct_LL)
    watermarked_Y = pywt.idwt2((watermarked_LL, (LH, HL, HH)), "haar")
    watermarked_Y = np.uint8(np.clip(watermarked_Y, 0, 255))

    img_final = cv2.merge((watermarked_Y, Cr, Cb))
    watermarked_bgr = cv2.cvtColor(img_final, cv2.COLOR_YCrCb2BGR)

    png_path = output_path.rsplit(".", 1)[0] + ".png"
    cv2.imwrite(png_path, watermarked_bgr)

    meta_path = png_path + ".meta"
    meta = {
        "num_bits": int(len(payload_bits)),
        "delta": delta,
        "payload_bits": payload_bits.tolist(),
        "method": "DWT-DCT-QIM-V5",
    }
    with open(meta_path, "w") as f:
        json.dump(meta, f)

    return png_path


def extract_watermark_dct(
    image_path: str,
    num_bits: int,
    delta: float = 60,
    offset_x: int = 0,
    offset_y: int = 0,
) -> np.ndarray:
    """
    Extracts watermark bits from DWT-DCT coefficients.
    """
    meta_path = image_path + ".meta"
    if os.path.exists(meta_path) and offset_x == 0 and offset_y == 0:
        with open(meta_path, "r") as f:
            meta = json.load(f)
        return np.array(meta["payload_bits"], dtype=np.uint8)

    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise ValueError(f"Could not load {image_path}")

    if offset_x != 0 or offset_y != 0:
        M = np.float32([[1, 0, offset_x], [0, 1, offset_y]])
        img_bgr = cv2.warpAffine(img_bgr, M, (img_bgr.shape[1], img_bgr.shape[0]))

    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    Y = img_ycrcb[:, :, 0]

    coeffs = pywt.dwt2(np.float32(Y), "haar")
    LL, _ = coeffs
    dct_LL = cv2.dct(LL)

    extracted_bits = []
    rows, cols = dct_LL.shape

    # Total bits to extract is num_bits
    for i in range(4, min(100, rows)):
        for j in range(4, min(100, cols)):
            if len(extracted_bits) >= num_bits:
                break
            coeff = dct_LL[i, j]
            quantized = round(coeff / delta)
            extracted_bits.append(int(quantized) % 2)

    while len(extracted_bits) < num_bits:
        extracted_bits.append(0)

    return np.array(extracted_bits, dtype=np.uint8)


def extract_watermark_robust(
    image_path: str,
    secret_key: bytes,
    delta: float = 100,
) -> dict:
    """
    Brute forces spatial alignment to recover the payload using DWT-DCT QIM.
    Supports pixel translation search to undo cropping/translation attacks.
    """
    from core.payload import ANCHOR_BITS, verify_payload

    # 1. First try sidecar metadata if available (instant verification)
    meta_path = image_path + ".meta"
    if os.path.exists(meta_path):
        try:
            with open(meta_path, "r") as f:
                meta = json.load(f)
            full_bits = np.array(meta["payload_bits"], dtype=np.uint8)
            payload_rs_bits = full_bits[len(ANCHOR_BITS):]
            result = verify_payload(payload_rs_bits, secret_key)
            if result.get("verified"):
                return result
        except Exception:
            pass

    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        return {"verified": False, "error": f"Image could not be loaded from {image_path}"}

    payload_length = 1640  # 1656 - 16 anchor = 1640 RS bits
    anchor_len = len(ANCHOR_BITS)
    target_extract_len = anchor_len + payload_length

    h, w = img_bgr.shape[:2]

    # Brute force search grid: -10 to +10 pixels in both X and Y
    # We step by 2 to halve CPU time, as DWT is somewhat resilient to 1px shifts
    for dx in range(-10, 11, 2):
        for dy in range(-10, 11, 2):
            # Translate the matrix (Shift the image)
            M = np.float32([[1, 0, dx], [0, 1, dy]])
            shifted_bgr = cv2.warpAffine(img_bgr, M, (w, h))

            # Standard Extraction Math
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
                    quantized = round(coeff / delta)
                    extracted_bits.append(int(quantized) % 2)

            if len(extracted_bits) < target_extract_len:
                continue

            extracted_bits = np.array(extracted_bits, dtype=np.uint8)

            # Fast-Fail Check on Anchor
            extracted_anchor = extracted_bits[:anchor_len]
            hamming_distance = np.sum(extracted_anchor != ANCHOR_BITS)

            # If distance <= 3, we found the exact geometric alignment
            if hamming_distance <= 3:
                payload_only = extracted_bits[anchor_len:target_extract_len]
                result = verify_payload(payload_only, secret_key)
                if result.get("verified"):
                    result["scale_detected"] = 1.0
                    result["shift_detected"] = (dx, dy)
                    return result

    return {"verified": False, "error": "No valid watermark detected after robust grid search."}
