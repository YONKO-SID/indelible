import os
import shutil
import time
import asyncio
import cv2
import numpy as np
from core.watermark import embed_watermark_dct, extract_watermark_dct
from core.payload import create_payload
from core.bktree_index import index as bktree_index
from core.monitoring_daemon import daemon

import logging
logging.basicConfig(level=logging.INFO)

# Setup
SECRET_KEY = b"hackathon_secret_key_123"
TEST_IMG = "test_source.png"
PROTECTED_IMG = "test_protected.png"
PIRATE_DIR = "dummy_pirate_web"

async def test_watchdog_pipeline():
    print("--- Starting Watchdog Pipeline Test ---")
    
    # 1. Create a source image with some texture for better DWT stability
    img = np.random.randint(0, 255, (512, 512, 3), dtype=np.uint8)
    cv2.putText(img, "REAL CONTENT", (50, 250), cv2.FONT_HERSHEY_SIMPLEX, 2, (255, 255, 255), 4)
    cv2.imwrite(TEST_IMG, img)
    
    # 2. Protect it
    print("Step 1: Protecting asset...")
    fingerprint = "INDL-TEST-DAEMON-123"
    _, _, rs_bits = create_payload(fingerprint, SECRET_KEY)
    embed_watermark_dct(TEST_IMG, rs_bits, PROTECTED_IMG, delta=80)
    
    # 3. Add to index
    print("Step 2: Adding to BKTree index...")
    bktree_index.add_asset(PROTECTED_IMG, fingerprint)
    
    # 4. Simulate Piracy
    print("Step 3: Simulating piracy (copying to dummy pirate web)...")
    pirate_copy = os.path.join(PIRATE_DIR, "stolen_content.png")
    shutil.copy2(PROTECTED_IMG, pirate_copy)
    
    # 5. Run one scan cycle manually
    print("Step 4: Running daemon scan cycle...")
    # Manually run the extraction to see BER
    print(f"DEBUG: Payload bits length: {len(rs_bits)}")
    extracted = extract_watermark_dct(pirate_copy, num_bits=len(rs_bits), delta=80)
    errors = np.sum(extracted != rs_bits)
    print(f"DEBUG: Blind extraction BER: {errors/len(rs_bits)*100:.2f}% ({errors} errors)")
    
    await daemon.scan_cycle()
    
    # 6. Check alerts
    print("Step 5: Verifying alerts...")
    if os.path.exists("alerts.json"):
        with open("alerts.json", "r") as f:
            import json
            alerts = json.load(f)
            found = False
            for a in alerts:
                if a["creator_fingerprint"] == fingerprint:
                    print(f"MATCH FOUND! ID: {a['id']}, Source: {a['source_url']}")
                    found = True
            if not found:
                print("Alert not found for fingerprint.")
    else:
        print("alerts.json does not exist.")

    # Cleanup
    # os.remove(TEST_IMG)
    # os.remove(PROTECTED_IMG)
    print("--- Test Finished ---")

if __name__ == "__main__":
    asyncio.run(test_watchdog_pipeline())
