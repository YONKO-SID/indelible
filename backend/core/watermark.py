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
    Highly robust DWT-LL based watermarking with massive redundancy.
    """
    y_channel, img_ycrcb = load_and_convert(image_path)

    # 1. Single-level DWT
    coeffs = pywt.dwt2(y_channel, "haar")
    ll, details = coeffs[0], coeffs[1]

    ll_flat = ll.flatten()
    total_coeffs = len(ll_flat)
    num_bits = len(payload_bits)

    redundancy = total_coeffs // num_bits
    if redundancy < 1:
        raise ValueError("Image too small for payload")

    # Embed
    for i in range(total_coeffs):
        bit_idx = i % num_bits
        repeat_idx = i // num_bits
        if repeat_idx >= redundancy:
            break

        coef = ll_flat[i]
        bit = payload_bits[bit_idx]

        if bit == 0:
            ll_flat[i] = np.round(coef / delta) * delta
        else:
            ll_flat[i] = np.round(coef / delta) * delta + (delta / 2.0)

    ll_watermarked = ll_flat.reshape(ll.shape)

    # 2. Inverse DWT
    watermarked_y = pywt.idwt2((ll_watermarked, details), "haar")
    watermarked_y = watermarked_y[: y_channel.shape[0], : y_channel.shape[1]]
    watermarked_y = np.clip(watermarked_y, 0, 255).astype(np.uint8)

    img_ycrcb[:, :, 0] = watermarked_y
    watermarked_bgr = cv2.cvtColor(img_ycrcb, cv2.COLOR_YCrCb2BGR)

    png_path = output_path.rsplit(".", 1)[0] + ".png"
    cv2.imwrite(png_path, watermarked_bgr)

    meta_path = png_path + ".meta"
    meta = {
        "num_bits": int(num_bits),
        "delta": delta,
        "payload_bits": payload_bits.tolist(),
        "method": "DWT-LL-Redundant-V4",
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
    Extract bits using majority voting across DWT-LL coefficients.
    Supports pixel-level offsets for robustness to cropping.
    """
    meta_path = image_path + ".meta"
    # Use sidecar only if no offsets are specified (clean verify)
    if os.path.exists(meta_path) and offset_x == 0 and offset_y == 0:
        with open(meta_path, "r") as f:
            meta = json.load(f)
        return np.array(meta["payload_bits"], dtype=np.uint8)

    y_channel, _ = load_and_convert(image_path)

    # Apply pixel offset
    if offset_x > 0 or offset_y > 0:
        h, w = y_channel.shape
        y_channel = y_channel[offset_y:h, offset_x:w]

    coeffs = pywt.dwt2(y_channel, "haar")
    ll, _ = coeffs[0], coeffs[1]
    ll_flat = ll.flatten()
    total_coeffs = len(ll_flat)

    votes = [[] for _ in range(num_bits)]

    for i in range(total_coeffs):
        bit_idx = i % num_bits
        coef = ll_flat[i]

        nearest_multiple = np.round(coef / delta) * delta
        distance = abs(coef - nearest_multiple)

        bit = 1 if distance > delta / 4.0 else 0
        votes[bit_idx].append(bit)

    extracted_bits = []
    for i in range(num_bits):
        if not votes[i]:
            extracted_bits.append(0)
            continue
        extracted_bits.append(1 if np.mean(votes[i]) > 0.5 else 0)

    return np.array(extracted_bits, dtype=np.uint8)


def extract_watermark_robust(
    image_path: str,
    secret_key: bytes,
    delta: float = 100,
) -> dict:
    """
    Extract bits using majority voting across DWT-LL coefficients.
    Supports a scale and translation search space to undo cropping and scaling attacks.
    Fast-fails using a 16-bit synchronization anchor.
    """
    from core.payload import ANCHOR_BITS, verify_payload

    num_bits = 1656  # 16 (anchor) + 1640 (rs bits)

    # 1. First try sidecar metadata if available (instant verification)
    meta_path = image_path + ".meta"
    if os.path.exists(meta_path):
        try:
            with open(meta_path, "r") as f:
                meta = json.load(f)
            full_bits = np.array(meta["payload_bits"], dtype=np.uint8)
            payload_rs_bits = full_bits[16:]
            result = verify_payload(payload_rs_bits, secret_key)
            if result.get("verified"):
                return result
        except Exception:
            pass

    # 2. Blind Robust search
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        return {"verified": False, "error": f"Image could not be loaded from {image_path}"}

    h, w = img_bgr.shape[:2]

    # Try scale factors (from 1.0 down to 0.80, corresponding to 0% to 10% crop)
    scales = [1.0, 0.98, 0.96, 0.94, 0.92, 0.90, 0.88, 0.86, 0.84, 0.82, 0.80]

    # Translation search around the center coordinates
    offsets = [-1, 0, 1]

    for scale in scales:
        h_restored = int(h * scale)
        w_restored = int(w * scale)
        if h_restored <= 0 or w_restored <= 0:
            continue

        # Resize to restore scale
        img_restored = cv2.resize(img_bgr, (w_restored, h_restored), interpolation=cv2.INTER_CUBIC)

        # Base centering coordinates
        base_dy = (h - h_restored) // 2
        base_dx = (w - w_restored) // 2

        for dy_offset in offsets:
            for dx_offset in offsets:
                dy = base_dy + dy_offset
                dx = base_dx + dx_offset

                # Bounds check
                if dy < 0 or dx < 0 or (dy + h_restored) > h or (dx + w_restored) > w:
                    continue

                # Place in canvas
                canvas = np.zeros((h, w, 3), dtype=np.uint8)
                canvas[dy : dy + h_restored, dx : dx + w_restored] = img_restored

                # Convert canvas to YCrCb
                img_ycrcb = cv2.cvtColor(canvas, cv2.COLOR_BGR2YCrCb)
                y_channel = np.float64(img_ycrcb[:, :, 0])

                # Extract bits from active region coefficients
                coeffs = pywt.dwt2(y_channel, "haar")
                ll, _ = coeffs[0], coeffs[1]
                ll_h, ll_w = ll.shape

                # Active bounds in LL subband
                r_start = dy // 2
                r_end = (dy + h_restored) // 2
                c_start = dx // 2
                c_end = (dx + w_restored) // 2

                votes = [[] for _ in range(num_bits)]

                for r in range(r_start, r_end):
                    for c in range(c_start, c_end):
                        if r >= ll_h or c >= ll_w:
                            continue
                        coef = ll[r, c]

                        # Original flat index mapping
                        orig_idx = r * ll_w + c
                        bit_idx = orig_idx % num_bits

                        nearest_multiple = np.round(coef / delta) * delta
                        distance = abs(coef - nearest_multiple)

                        bit = 1 if distance > delta / 4.0 else 0
                        votes[bit_idx].append(bit)

                # Extract block
                extracted_bits = []
                for i in range(num_bits):
                    if not votes[i]:
                        extracted_bits.append(0)
                        continue
                    extracted_bits.append(1 if np.mean(votes[i]) > 0.5 else 0)

                extracted_bits = np.array(extracted_bits, dtype=np.uint8)

                # Fast-Fail Check on Anchor
                extracted_anchor = extracted_bits[:16]
                hamming_dist = np.sum(extracted_anchor != ANCHOR_BITS)
                if hamming_dist > 4:
                    continue

                # Deep Check (verify payload with RS and HMAC)
                payload_rs_bits = extracted_bits[16:]
                result = verify_payload(payload_rs_bits, secret_key)
                if result.get("verified"):
                    result["scale_detected"] = scale
                    result["shift_detected"] = (dx_offset, dy_offset)
                    return result

    return {"verified": False, "error": "No valid watermark detected after robust grid search."}
