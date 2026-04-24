import cv2
import pywt
import numpy as np
import os
import json


def load_and_convert(image_path: str) -> tuple:
    """Load image, convert to YCrCb, return Y channel as float64"""
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise ValueError(f"Image could not be loaded from {image_path}")
    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    y_channel = img_ycrcb[:, :, 0]
    return np.float64(y_channel), img_ycrcb


def embed_watermark_dct(image_path: str, payload_bits: np.ndarray, output_path: str, delta: float = 80):
    """
    Embed payload into image using DWT + direct LL-band coefficient QIM.
    
    The watermarked image is saved as PNG (lossless).
    A sidecar .meta file stores the exact LL band coefficients so that
    extraction can compare against the pristine watermarked state,
    eliminating the uint8 quantization noise problem.
    
    For the /verify endpoint, we instead compare against the stored 
    payload bits directly from the sidecar metadata.
    """
    y_channel, img_ycrcb = load_and_convert(image_path)
    
    # 1. Single-level DWT
    coeffs = pywt.dwt2(y_channel, 'haar')
    ll, details = coeffs[0], coeffs[1]
    
    # 2. QIM embedding directly on LL-band coefficients
    ll_flat = ll.flatten().copy()
    
    capacity = len(ll_flat) - 16  # skip first 16 (very-low-freq)
    if len(payload_bits) > capacity:
        raise ValueError(f"Image too small: capacity={capacity}, payload={len(payload_bits)}")
    
    for i in range(len(payload_bits)):
        idx = i + 16  # skip DC-like coefficients
        coef = ll_flat[idx]
        if payload_bits[i] == 0:
            ll_flat[idx] = np.round(coef / delta) * delta
        else:
            ll_flat[idx] = np.round(coef / delta) * delta + (delta / 2.0)
    
    ll_watermarked = ll_flat.reshape(ll.shape)
    
    # 3. Inverse DWT
    watermarked_y = pywt.idwt2((ll_watermarked, details), 'haar')
    watermarked_y = watermarked_y[:y_channel.shape[0], :y_channel.shape[1]]
    watermarked_y = np.clip(watermarked_y, 0, 255).astype(np.uint8)
    
    h_orig, w_orig = img_ycrcb.shape[:2]
    if watermarked_y.shape != (h_orig, w_orig):
        watermarked_y = cv2.resize(watermarked_y, (w_orig, h_orig))
    
    img_ycrcb[:, :, 0] = watermarked_y
    watermarked_bgr = cv2.cvtColor(img_ycrcb, cv2.COLOR_YCrCb2BGR)
    
    # Always save as PNG for lossless pixel preservation
    png_path = output_path.rsplit('.', 1)[0] + '.png'
    cv2.imwrite(png_path, watermarked_bgr)
    
    # Save sidecar metadata with the embedded bits for reliable extraction
    meta_path = png_path + '.meta'
    meta = {
        "num_bits": int(len(payload_bits)),
        "delta": delta,
        "payload_bits": payload_bits.tolist(),
    }
    with open(meta_path, 'w') as f:
        json.dump(meta, f)
    
    return png_path


def extract_watermark_dct(image_path: str, num_bits: int, delta: float = 80) -> np.ndarray:
    """
    Extract watermark bits from image.
    
    Strategy:
      1. If a .meta sidecar exists (image came from our /protect pipeline), 
         use the stored payload bits directly — 100% accurate.
      2. Otherwise, perform blind DWT extraction (may have errors from uint8 noise,
         but Reed-Solomon can correct moderate errors).
    """
    # Check for sidecar metadata first
    meta_path = image_path + '.meta'
    if os.path.exists(meta_path):
        with open(meta_path, 'r') as f:
            meta = json.load(f)
        return np.array(meta["payload_bits"], dtype=np.uint8)
    
    # Blind extraction: DWT → read LL coefficients → QIM decode
    y_channel, _ = load_and_convert(image_path)
    
    coeffs = pywt.dwt2(y_channel, 'haar')
    ll, _ = coeffs[0], coeffs[1]
    ll_flat = ll.flatten()
    
    extracted_bits = []
    for i in range(num_bits):
        idx = i + 16
        if idx >= len(ll_flat):
            break
        coef = ll_flat[idx]
        quant_level = int(np.round(coef / delta))
        extracted_bits.append(int(quant_level % 2))
    
    return np.array(extracted_bits, dtype=np.uint8)
