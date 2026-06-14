import os

import cv2
import numpy as np
import pywt
from core.payload import create_payload, verify_payload
from core.watermark import embed_watermark_dct, extract_watermark_dct, extract_watermark_robust


def run_attack(image_path, attack_type, intensity=None):
    img = cv2.imread(image_path)
    attacked_path = f"attacked_{attack_type}.png"

    if attack_type == "jpeg":
        quality = intensity or 50
        cv2.imwrite(attacked_path, img, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
        # Reload as png for consistent processing
        img_attacked = cv2.imread(attacked_path)
        cv2.imwrite(attacked_path, img_attacked)
    elif attack_type == "blur":
        ksize = intensity or 5
        img_attacked = cv2.GaussianBlur(img, (ksize, ksize), 0)
        cv2.imwrite(attacked_path, img_attacked)
    elif attack_type == "crop":
        percent = intensity or 10
        h, w = img.shape[:2]
        h_crop = int(h * (percent / 100))
        w_crop = int(w * (percent / 100))
        img_attacked = img[h_crop : h - h_crop, w_crop : w - w_crop]
        # Resize back to original to keep alignment (DWT-LL is sensitive to this)
        img_attacked = cv2.resize(img_attacked, (w, h))
        cv2.imwrite(attacked_path, img_attacked)
    elif attack_type == "noise":
        std = intensity or 10
        noise = np.random.normal(0, std, img.shape).astype(np.int16)
        img_attacked = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        cv2.imwrite(attacked_path, img_attacked)

    return attacked_path


def test_robustness():
    # 1. Setup
    SECRET_KEY = b"test_secret"
    creator_fp = "INDL-TEST-0001"
    payload_str, _, rs_bits = create_payload(creator_fp, SECRET_KEY)

    # Create a dummy image
    dummy_img = np.zeros((512, 512, 3), dtype=np.uint8)
    cv2.putText(
        dummy_img,
        "Indelible Test",
        (50, 250),
        cv2.FONT_HERSHEY_SIMPLEX,
        2,
        (255, 255, 255),
        3,
    )
    cv2.imwrite("test_input.png", dummy_img)

    # 2. Embed
    print("Embedding watermark...")
    # delta=100 for higher robustness
    watermarked_path = embed_watermark_dct(
        "test_input.png", rs_bits, "test_watermarked.png", delta=100
    )

    # 3. Attacks
    attacks = [
        ("original", None),
        ("jpeg", 50),
        ("jpeg", 20),
        ("blur", 5),
        ("noise", 10),
        ("crop", 5),
        ("crop", 10),
    ]

    results = []
    for name, intensity in attacks:
        if name == "original":
            path = watermarked_path
            # Also remove .meta for original to force real blind verification
            if os.path.exists(path + ".meta"):
                os.remove(path + ".meta")
        else:
            path = run_attack(watermarked_path, name, intensity)
            # Remove .meta to force blind extraction
            if os.path.exists(path + ".meta"):
                os.remove(path + ".meta")

        # 4. Robust Extract & Verify
        result = extract_watermark_robust(path, SECRET_KEY, delta=100)
        verified = result.get("verified", False)
        best_ber = 1.0
        num_bits = len(rs_bits)

        if verified:
            # Re-extract with the detected parameters to compute BER for the report
            scale = result.get("scale_detected", 1.0)
            dx_offset, dy_offset = result.get("shift_detected", (0, 0))

            img_bgr = cv2.imread(path)
            h, w = img_bgr.shape[:2]
            h_restored = int(h * scale)
            w_restored = int(w * scale)
            img_restored = cv2.resize(img_bgr, (w_restored, h_restored), interpolation=cv2.INTER_CUBIC)

            base_dy = (h - h_restored) // 2
            base_dx = (w - w_restored) // 2
            dy = base_dy + dy_offset
            dx = base_dx + dx_offset

            canvas = np.zeros((h, w, 3), dtype=np.uint8)
            canvas[dy : dy + h_restored, dx : dx + w_restored] = img_restored

            img_ycrcb = cv2.cvtColor(canvas, cv2.COLOR_BGR2YCrCb)
            y_channel = np.float64(img_ycrcb[:, :, 0])

            coeffs = pywt.dwt2(y_channel, "haar")
            ll, _ = coeffs[0], coeffs[1]
            ll_h, ll_w = ll.shape

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

                    orig_idx = r * ll_w + c
                    bit_idx = orig_idx % num_bits

                    nearest_multiple = np.round(coef / 100) * 100
                    distance = abs(coef - nearest_multiple)

                    bit = 1 if distance > 25 else 0
                    votes[bit_idx].append(bit)

            extracted_bits = []
            for i in range(num_bits):
                if not votes[i]:
                    extracted_bits.append(0)
                    continue
                extracted_bits.append(1 if np.mean(votes[i]) > 0.5 else 0)

            extracted_bits = np.array(extracted_bits, dtype=np.uint8)
            best_ber = np.mean(extracted_bits != rs_bits)
        else:
            # If not verified, try to extract at original scale (1.0, 0, 0) just to print a BER baseline
            try:
                img_bgr = cv2.imread(path)
                img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
                y_channel = np.float64(img_ycrcb[:, :, 0])
                coeffs = pywt.dwt2(y_channel, "haar")
                ll, _ = coeffs[0], coeffs[1]
                ll_flat = ll.flatten()
                extracted_bits = []
                for i in range(num_bits):
                    coef = ll_flat[i]
                    nearest_multiple = np.round(coef / 100) * 100
                    distance = abs(coef - nearest_multiple)
                    extracted_bits.append(1 if distance > 25 else 0)
                extracted_bits = np.array(extracted_bits, dtype=np.uint8)
                best_ber = np.mean(extracted_bits != rs_bits)
            except Exception:
                best_ber = 1.0

        status = "PASS" if verified else "FAIL"
        results.append(
            f"| {name:10} | {str(intensity):10} | {status:6} | {best_ber:.2%} |"
        )

    print("\nRobustness Report (DWT-LL Redundant + Grid Search):")
    print("| Attack     | Intensity  | Status | Best BER |")
    print("|------------|------------|--------|----------|")
    for r in results:
        print(r)


if __name__ == "__main__":
    test_robustness()
