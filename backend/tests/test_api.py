import pytest
from fastapi.testclient import TestClient
from main import app
import os
import cv2
import numpy as np
import shutil

client = TestClient(app)

@pytest.fixture
def test_image(tmp_path):
    img_path = str(tmp_path / "test_api_img.png")
    img = np.ones((256, 256, 3), dtype=np.uint8) * 200
    cv2.imwrite(img_path, img)
    return img_path

def test_protect_endpoint(test_image):
    with open(test_image, "rb") as f:
        response = client.post(
            "/protect",
            data={"user_uid": "test_user_123"},
            files={"file": ("test_api_img.png", f, "image/png")}
        )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "protected"
    assert "download_url" in data
    assert "creator_fingerprint" in data
    
    # Ensure it's in the outputs folder
    filename = data["download_url"].split("/")[-1]
    assert os.path.exists(os.path.join("outputs", filename))

def test_verify_endpoint(test_image):
    # First protect it to get a watermarked image
    with open(test_image, "rb") as f:
        res1 = client.post(
            "/protect",
            data={"user_uid": "test_user_123"},
            files={"file": ("test_api_img.png", f, "image/png")}
        )
    
    protected_filename = res1.json()["download_url"].split("/")[-1]
    protected_path = os.path.join("outputs", protected_filename)
    
    # Now verify it
    with open(protected_path, "rb") as f:
        res2 = client.post(
            "/verify",
            files={"file": (protected_filename, f, "image/png")}
        )
        
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["status"] == "match_found"
    assert data2["proof_report"]["hmac_verified"] is True
