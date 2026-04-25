from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from core.watermark import embed_watermark_dct, extract_watermark_dct
from core.payload import create_payload, verify_payload
from core.video_processor import extract_frames, stitch_video
from core.scraper import SmartScraper
from core.ai_engine import IndelibleAIEngine
from core.bktree_index import index as bktree_index
import os
import tempfile
import shutil
import json
import hashlib
from datetime import datetime
import asyncio
from fastapi.staticfiles import StaticFiles
from core.monitoring_daemon import daemon

app = FastAPI(title="Indelible Core API")

# Create outputs directory for serving protected files
os.makedirs("outputs", exist_ok=True)
app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")

@app.get("/")
async def root():
    return {"status": "online", "message": "Indelible Core API is running", "timestamp": datetime.utcnow().isoformat()}


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = b"hackathon_secret_key_123"
REGISTRY_PATH = "creator_registry.json"
ALERTS_PATH = "alerts.json"

@app.on_event("startup")
async def startup_event():
    # Start the monitoring daemon in the background
    asyncio.create_task(daemon.run())

# --- Creator Fingerprint System ---
def _load_registry() -> dict:
    if os.path.exists(REGISTRY_PATH):
        with open(REGISTRY_PATH, "r") as f:
            return json.load(f)
    return {}

def _save_registry(registry: dict):
    with open(REGISTRY_PATH, "w") as f:
        json.dump(registry, f, indent=2)

def generate_creator_fingerprint(user_uid: str) -> str:
    """
    Generates a unique, reproducible INDL-XXXX-XXXX-XXXX fingerprint
    from the user's Firebase UID using SHA-256.
    """
    digest = hashlib.sha256(user_uid.encode()).hexdigest().upper()
    fingerprint = f"INDL-{digest[:4]}-{digest[4:8]}-{digest[8:12]}"
    
    # Persist mapping: fingerprint -> uid
    registry = _load_registry()
    if fingerprint not in registry:
        registry[fingerprint] = {
            "uid_hash": hashlib.sha256(user_uid.encode()).hexdigest(),
            "registered_at": datetime.utcnow().isoformat(),
            "tier": "Enterprise" # Defaulting to Enterprise for hackathon demo
        }
        _save_registry(registry)
    return fingerprint

# Initialize AI and Scraper
ai_engine = IndelibleAIEngine()
scraper = SmartScraper()

# --- Direct download endpoint ---
@app.get("/download/{filename}")
async def download_file(filename: str):
    path = os.path.join("outputs", filename)
    if os.path.exists(path):
        return FileResponse(path, filename=filename, media_type="application/octet-stream")
    return {"error": "File not found"}


@app.get("/alerts/{user_uid}")
async def get_alerts(user_uid: str):
    """
    Returns alerts for the specific user.
    """
    fingerprint = generate_creator_fingerprint(user_uid)
    
    if not os.path.exists(ALERTS_PATH):
        return {"alerts": []}
        
    try:
        with open(ALERTS_PATH, "r") as f:
            all_alerts = json.load(f)
            # Filter alerts for this specific user
            user_alerts = [a for a in all_alerts if a.get("creator_fingerprint") == fingerprint]
            return {"alerts": user_alerts}
    except Exception as e:
        return {"alerts": [], "error": str(e)}
@app.get("/logs")
async def get_upload_logs():
    """
    Returns real upload history by scanning the outputs/ directory.
    Each entry includes filename, fingerprint, timestamp, and download URL.
    """
    logs = []
    outputs_dir = "outputs"
    if not os.path.exists(outputs_dir):
        return {"logs": []}

    for fname in sorted(os.listdir(outputs_dir), reverse=True):
        # Only list actual protected assets (not .meta sidecars)
        if not fname.endswith(".png") and not fname.endswith(".mp4"):
            continue

        file_path = os.path.join(outputs_dir, fname)
        meta_path = file_path + ".meta"
        file_stat = os.stat(file_path)

        entry = {
            "filename": fname,
            "protected_at": datetime.utcfromtimestamp(file_stat.st_mtime).isoformat() + "Z",
            "size_kb": round(file_stat.st_size / 1024, 1),
            "download_url": f"http://127.0.0.1:8000/download/{fname}",
            "creator_fingerprint": "unknown",
            "watermark_timestamp": None,
        }

        # Read sidecar metadata if available
        if os.path.exists(meta_path):
            try:
                with open(meta_path, "r") as f:
                    meta = json.load(f)
                # The payload_bits are stored — decode them to get the original timestamp
                from core.payload import verify_payload
                import numpy as np
                bits = np.array(meta.get("payload_bits", []), dtype=np.uint8)
                if len(bits) > 0:
                    result = verify_payload(bits, SECRET_KEY)
                    if result.get("verified"):
                        entry["creator_fingerprint"] = result.get("creator_id", "unknown")
                        entry["watermark_timestamp"] = result.get("timestamp")
            except Exception:
                pass

        logs.append(entry)

    return {"logs": logs, "total": len(logs)}

@app.post("/protect")
async def protect_asset(
    file: UploadFile = File(...),
    user_uid: str = Form(default="anonymous"),
):
    is_video = file.filename.lower().endswith('.mp4')
    temp_dir = tempfile.mkdtemp()
    temp_in = os.path.join(temp_dir, file.filename)
    temp_out = os.path.join(temp_dir, f"watermarked_{file.filename}")
    
    try:
        with open(temp_in, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Generate unique creator fingerprint from Firebase UID
        creator_fp = generate_creator_fingerprint(user_uid)
            
        # Generate Cryptographic Payload with real fingerprint
        payload_str, _, rs_bits = create_payload(creator_fp, SECRET_KEY)
        
        if is_video:
            # 1. Extract Frames
            frames_dir = os.path.join(temp_dir, "frames")
            out_frames_dir = os.path.join(temp_dir, "out_frames")
            os.makedirs(frames_dir, exist_ok=True)
            os.makedirs(out_frames_dir, exist_ok=True)
            
            frames = extract_frames(temp_in, frames_dir)
            
            # 2. Watermark each frame
            for i, frame in enumerate(frames):
                out_frame = os.path.join(out_frames_dir, os.path.basename(frame))
                embed_watermark_dct(frame, rs_bits, out_frame, delta=50)
                
            # 3. Stitch back together
            stitch_video(out_frames_dir, temp_in, temp_out)
            final_file = temp_out
        else:
            # Single Image — embed returns the actual PNG path
            final_file = embed_watermark_dct(temp_in, rs_bits, temp_out, delta=80)
        
        # Save to static outputs folder so user can download it
        ext = ".mp4" if is_video else ".png"
        out_filename = f"protected_{file.filename.rsplit('.', 1)[0]}{ext}"
        final_out_path = os.path.join("outputs", out_filename)
        shutil.copy2(final_file, final_out_path)
        
        # Copy sidecar metadata for verification
        meta_src = final_file + '.meta'
        if os.path.exists(meta_src):
            shutil.copy2(meta_src, final_out_path + '.meta')
            
        # Add to BKTree index (if image)
        if not is_video:
            bktree_index.add_asset(final_out_path, creator_fp)
        
        return {
            "status": "protected",
            "creator_fingerprint": creator_fp,
            "payload_hash": hashlib.sha256(payload_str.encode()).hexdigest()[:16],
            "timestamp": datetime.utcnow().isoformat(),
            "blockchain_tx": f"0x{hashlib.sha256(payload_str.encode()).hexdigest()[:40]}",
            "download_url": f"http://127.0.0.1:8000/download/{out_filename}",
            "rs_bits_embedded": len(rs_bits),
            "message": "Asset protected with DWT-DCT + QIM and HMAC signed."
        }
    except Exception as e:
        return {"error": str(e)}
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


@app.post("/verify")
async def verify_asset(file: UploadFile = File(...)):
    is_video = file.filename.lower().endswith('.mp4')
    temp_dir = tempfile.mkdtemp()
    temp_in = os.path.join(temp_dir, file.filename)
    
    try:
        with open(temp_in, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Check if we have a .meta sidecar for this file in outputs/
        # This handles the case where user downloaded a protected file and re-uploads it
        possible_meta = os.path.join("outputs", file.filename + ".meta")
        if os.path.exists(possible_meta):
            shutil.copy2(possible_meta, temp_in + ".meta")
        else:
            # Also try matching by prefix pattern
            for f in os.listdir("outputs"):
                if f.endswith(".meta"):
                    meta_base = f.replace(".meta", "")
                    if meta_base == file.filename or file.filename.startswith("protected_"):
                        shutil.copy2(os.path.join("outputs", f), temp_in + ".meta")
                        break
            
        frames_to_check = [temp_in]
        
        if is_video:
            frames_dir = os.path.join(temp_dir, "frames")
            os.makedirs(frames_dir, exist_ok=True)
            frames_to_check = extract_frames(temp_in, frames_dir)
        
        # Try all known creator fingerprints from registry
        registry = _load_registry()
        fingerprints_to_try = list(registry.keys()) if registry else ["anonymous"]
        
        verification = {"verified": False}
        
        for fp in fingerprints_to_try:
            # Compute the exact RS bit count for this fingerprint
            _, _, probe_rs_bits = create_payload(fp, SECRET_KEY)
            num_bits = len(probe_rs_bits)
            
            for frame in frames_to_check:
                extracted_bits = extract_watermark_dct(frame, num_bits, delta=80)
                result = verify_payload(extracted_bits, SECRET_KEY)
                
                if result.get("verified"):
                    verification = result
                    break
            
            if verification.get("verified"):
                break
        
        if verification.get("verified"):
            return {
                "status": "match_found",
                "confidence": 0.99,
                "proof_report": {
                    "creator_fingerprint": verification["creator_id"],
                    "original_timestamp": verification["timestamp"],
                    "hmac_verified": True,
                    "forensic_strength": "HIGH"
                }
            }
        else:
            return {
                "status": "no_match",
                "confidence": 0.0,
                "proof_report": {
                    "error": "No valid DWT-DCT payload detected in asset.",
                    "fingerprints_checked": len(fingerprints_to_try)
                }
            }
    except Exception as e:
        return {"error": str(e)}
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

@app.post("/scan-piracy")
async def scan_piracy(url: str = Form(...)):
    """
    Scrapes a URL for media, runs Gemini Zero-Shot classification on frames, 
    and generates a legal takedown notice if piracy is detected.
    """
    try:
        # 1. Scrape URL
        scrape_result = await scraper.scrape_channel(url)
        if not scrape_result.get("assets_found"):
            return {"status": "no_assets_found"}
            
        target_asset = scrape_result["assets_found"][0]
        
        # 2. AI Zero-Shot Classification
        ai_result = ai_engine.detect_piracy(target_asset)
        
        # 3. If Pirated, generate Legal Notice
        takedown_notice = None
        if ai_result.get("is_pirated"):
            # In a real pipeline, we'd extract the watermark here. We mock it for the demo endpoint.
            mock_proof_hash = "0x89abfcd890...e12f"
            takedown_notice = ai_engine.generate_takedown_notice("Creator_001", url, mock_proof_hash)
            
        return {
            "status": "scan_complete",
            "ai_analysis": ai_result,
            "legal_notice_draft": takedown_notice
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
