import pytest
import numpy as np
import cv2
import os
from core.watermark import embed_watermark_dct, extract_watermark_dct

@pytest.fixture
def dummy_image(tmp_path):
    img_path = str(tmp_path / "dummy.png")
    # Create a 256x256 gray-ish image
    img = np.ones((256, 256, 3), dtype=np.uint8) * 128
    cv2.imwrite(img_path, img)
    return img_path

def test_watermark_embedding_and_blind_extraction(dummy_image, tmp_path):
    output_path = str(tmp_path / "watermarked.png")
    
    # 50 random bits
    np.random.seed(42)
    payload_bits = np.random.randint(0, 2, 50, dtype=np.uint8)
    
    # Embed
    final_path = embed_watermark_dct(dummy_image, payload_bits, output_path, delta=80)
    assert os.path.exists(final_path)
    
    # Normally it extracts using the .meta file.
    # We want to test BLIND extraction, so we delete the .meta file!
    meta_path = final_path + ".meta"
    if os.path.exists(meta_path):
        os.remove(meta_path)
        
    # Extract
    extracted_bits = extract_watermark_dct(final_path, num_bits=50, delta=80)
    
    # Because of quantization noise when saving to uint8, a few bits might flip.
    # We just want to ensure it's mostly correct (e.g. > 90% accuracy)
    accuracy = np.mean(extracted_bits == payload_bits)
    assert accuracy > 0.90, f"Blind extraction accuracy too low: {accuracy}"
