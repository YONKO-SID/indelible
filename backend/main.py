import os
import shutil
import tempfile
import time

import cv2
import numpy as np
from core.watermark import (
    embed_watermark,
    extract_watermark,
    generate_payload,
    verify_payload,
)
from storage.firebase import save_proof
from fastapi import BackgroundTasks, FastAPI, File, UploadFile
from fastapi.responses import FileResponse, JSONResponse

app = FastAPI(
    title="INDELIBLE Forensic API",
    description="Digital rights management via DWT-DCT watermarking",
    version="1.0.0",
)


def cleanup_files(*file_paths):
    """Deletes temporary files from the OS."""
    for path in file_paths:
        try:
            os.remove(path)
            print(f"[-] Burned temp file: {path}")
        except OSError:
            pass


@app.post("/protect")
async def protect(background_tasks: BackgroundTasks, file: UploadFile = File(...)):
    """
    Upload media for watermark protection.

    Embeds cryptographic payload using DWT-DCT-QIM pipeline.
    Returns watermarked file with proof metadata.
    """
    # 1. Stage the Input (Secure Temp File)
    with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as temp_input:
        shutil.copyfileobj(file.file, temp_input)
        input_path = temp_input.name

    # 2. Stage the Output
    output_path = input_path.replace(".png", "_protected.png")
    creator_id = "demo_user_hackathon"

    try:
        # 3. Generate and embed cryptographic payload
        payload_bits, bit_length = generate_payload(creator_id)
        embed_watermark(input_path, payload_bits, output_path=output_path)

        # 4. Mock Ledger Proof
        proof = {
            "status": "protected",
            "creatorId": creator_id,
            "mediaId": file.filename,
            "payloadHash": f"0x{hash(creator_id):x}"[:12],
            "timestamp": int(time.time()),
            "bitLength": bit_length,
        }

        # 5. Return proof + queue cleanup
        background_tasks.add_task(cleanup_files, input_path, output_path)
        return JSONResponse(content=proof)

    except Exception as e:
        cleanup_files(input_path)
        return JSONResponse(
            status_code=500, content={"error": f"Watermarking failed: {str(e)}"}
        )


@app.post("/verify")
async def verify(background_tasks: BackgroundTasks, file: UploadFile = File(...)):
    """
    Submit suspect media for forensic verification.

    Extracts watermark bits, decodes Reed-Solomon, verifies HMAC.
    Returns proof report with creator identity.
    """
    # 1. Stage the Input
    with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as temp_input:
        shutil.copyfileobj(file.file, temp_input)
        input_path = temp_input.name

    try:
        # 2. Extract watermark bits (assuming demo payload length)
        demo_bit_length = 320  # From generate_payload
        extracted_bits = extract_watermark(input_path, demo_bit_length)

        # 3. Verify HMAC signature
        verification_result = verify_payload(extracted_bits, demo_bit_length)

        # 4. Return proof report
        is_verified = "[V] SUCCESS" in verification_result
        return JSONResponse(
            content={
                "status": "verified" if is_verified else "no_match",
                "verification": verification_result,
                "confidence": 100.0 if is_verified else 0.0,
                "timestamp": int(time.time()),
            }
        )

    except Exception as e:
        return JSONResponse(
            status_code=500, content={"error": f"Verification failed: {str(e)}"}
        )


@app.get("/health")
async def health_check():
    """API health check endpoint"""
    return {"status": "operational", "engine": "DWT-DCT-QIM", "version": "1.0.0"}
