import cv2
import numpy as np
import pywt

# --- 1. CONFIGURATION ---
INPUT_IMAGE = "test.jpg"
OUTPUT_IMAGE = "watermarked_final.png"
EMBEDDING_STRENGTH = 1.0

# Simulate a 64-bit random watermark ID (e.g., representing OrgID: 0xa1b2c3d4e5f6g7h8)
np.random.seed(42)  # Keep seed the same for predictable testing
watermark_bits = np.random.randint(0, 2, 64)
print(f"Embedding Watermark (Binary): {''.join(map(str, watermark_bits))}")

# --- 2. THE PIPELINE (DECODE & EMBED) ---

# image in color (RGB), then convert to YCbCr space
img_color = cv2.imread(INPUT_IMAGE)
if img_color is None:
    print(f"Error: Could not find {INPUT_IMAGE}")
    exit()

img_ycrcb = cv2.cvtColor(img_color, cv2.COLOR_BGR2YCrCb)
Y, Cr, Cb = cv2.split(img_ycrcb)
Y_float = np.float32(Y)  # Math requires float32 data

# DWT on the Y-channel (Luminance)
coeffs2 = pywt.dwt2(Y_float, "haar")
LL, (LH, HL, HH) = coeffs2

# Embed the 64 bits into 64 unique pixels in the robust LL band.
# We skip the very first pixel to avoid major visual shifts.
height, width = LL.shape
num_bits = len(watermark_bits)

if num_bits > (height * width) - 1:
    print("Error: Image is too small to embed 64 bits.")
    exit()

# Flatten the LL band matrix to make embedding in a linear loop simple
LL_flattened = LL.flatten()

# We only modify the first 64 pixels (excluding index 0)
for i in range(num_bits):
    pixel_idx = i + 1  # Skip index 0
    current_val = LL_flattened[pixel_idx]
    target_bit = watermark_bits[i]

    # Simple QIM logic: Enforce even for 0, odd for 1
    # We shift the value based on the embedding strength
    if target_bit == 0:
        # Hide '0': Make the nearest smaller even number
        new_val = current_val - (current_val % 2) - EMBEDDING_STRENGTH
    else:
        # Hide '1': Make the nearest larger odd number
        new_val = current_val + 1 - (current_val % 2) + EMBEDDING_STRENGTH

    LL_flattened[pixel_idx] = new_val

# Reshape the modified LL band back to its original matrix dimensions
LL_modified = LL_flattened.reshape((height, width))

# --- 4. THE ASSEMBLY (INVERSE-DWT & RECONSTRUCT) ---

# Run the Inverse 2D Discrete Wavelet Transform (IDWT) using the modified LL band
coeffs2_modified = LL_modified, (LH, HL, HH)
Y_modified_float = pywt.idwt2(coeffs2_modified, "haar")

# Convert back to standard unit8 [0-255] luminance
Y_modified = np.uint8(np.clip(Y_modified_float, 0, 255))

# Merge the modified Y-channel back with the original Cb and Cr channels
img_ycrcb_final = cv2.merge((Y_modified, Cr, Cb))

# Convert back to original color space (BGR) and save
img_final = cv2.cvtColor(img_ycrcb_final, cv2.COLOR_YCrCb2BGR)
cv2.imwrite(OUTPUT_IMAGE, img_final)

print(f"Watermarking complete. Final 'protected' file saved as {OUTPUT_IMAGE}.")
