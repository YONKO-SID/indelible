import pytest
import numpy as np
from core.payload import create_payload, verify_payload

def test_payload_creation_and_verification():
    secret_key = b"test_secret_key"
    creator_id = "INDL-TEST-1234"

    # Create payload
    payload_str, payload_bits, rs_encoded_bits = create_payload(creator_id, secret_key)
    
    assert creator_id in payload_str
    assert isinstance(rs_encoded_bits, np.ndarray)
    
    # Verify exact match
    result = verify_payload(rs_encoded_bits, secret_key)
    assert result["verified"] is True
    assert result["creator_id"] == creator_id

def test_payload_corruption_recovery():
    secret_key = b"test_secret_key"
    creator_id = "INDL-TEST-1234"

    _, _, rs_encoded_bits = create_payload(creator_id, secret_key)
    
    # Corrupt 10 bits
    corrupted_bits = rs_encoded_bits.copy()
    for i in range(10):
        corrupted_bits[i] = 1 - corrupted_bits[i]
        
    result = verify_payload(corrupted_bits, secret_key)
    # Reed-Solomon should recover it
    assert result["verified"] is True
    assert result["creator_id"] == creator_id

def test_payload_invalid_signature():
    secret_key = b"test_secret_key"
    wrong_key = b"wrong_key"
    creator_id = "INDL-TEST-1234"

    _, _, rs_encoded_bits = create_payload(creator_id, secret_key)
    
    result = verify_payload(rs_encoded_bits, wrong_key)
    assert result["verified"] is False
    assert result.get("error") == "HMAC mismatch"
