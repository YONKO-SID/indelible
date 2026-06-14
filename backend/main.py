import asyncio
import hashlib
import json
import os
import shutil
import tempfile
from datetime import datetime

from core.ai_engine import IndelibleAIEngine
from core.bktree_index import index as bktree_index
from core.monitoring_daemon import daemon
from core.payload import create_payload, verify_payload
from core.scraper import SmartScraper
from core.video_processor import extract_frames, stitch_video
from core.watermark import embed_watermark_dct, extract_watermark_dct, extract_watermark_robust
from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

# Load environment variables from backend/.env (do not commit secrets)
load_dotenv()

app = FastAPI(title="Indelible Core API")

# Create outputs directory for serving protected files
os.makedirs("outputs", exist_ok=True)
app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")


@app.get("/")
async def root():
    return {
        "status": "online",
        "message": "Indelible Core API is running",
        "timestamp": datetime.utcnow().isoformat(),
    }


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = os.getenv("SECRET_KEY", "development_secret_key").encode()
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
            "tier": "Enterprise",  # Defaulting to Enterprise for hackathon demo
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
        return FileResponse(
            path, filename=filename, media_type="application/octet-stream"
        )
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
            user_alerts = [
                a for a in all_alerts if a.get("creator_fingerprint") == fingerprint
            ]
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
            "protected_at": datetime.utcfromtimestamp(file_stat.st_mtime).isoformat()
            + "Z",
            "size_kb": round(file_stat.st_size / 1024, 1),
            "download_url": f"/download/{fname}",
            "creator_fingerprint": "unknown",
            "watermark_timestamp": None,
        }

        # Read sidecar metadata if available
        if os.path.exists(meta_path):
            try:
                with open(meta_path, "r") as f:
                    meta = json.load(f)
                # The payload_bits are stored — decode them to get the original timestamp
                import numpy as np
                from core.payload import verify_payload

                bits = np.array(meta.get("payload_bits", []), dtype=np.uint8)
                if len(bits) > 0:
                    result = verify_payload(bits, SECRET_KEY)
                    if result.get("verified"):
                        entry["creator_fingerprint"] = result.get(
                            "creator_id", "unknown"
                        )
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
    is_video = file.filename.lower().endswith(".mp4")
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
            final_file = embed_watermark_dct(temp_in, rs_bits, temp_out, delta=100)

        # Save to static outputs folder so user can download it
        ext = ".mp4" if is_video else ".png"
        out_filename = f"protected_{file.filename.rsplit('.', 1)[0]}{ext}"
        final_out_path = os.path.join("outputs", out_filename)
        shutil.copy2(final_file, final_out_path)

        # Copy sidecar metadata for verification
        meta_src = final_file + ".meta"
        if os.path.exists(meta_src):
            shutil.copy2(meta_src, final_out_path + ".meta")

        # Add to BKTree index (if image)
        if not is_video:
            bktree_index.add_asset(final_out_path, creator_fp)

        # 4. Anchor to Blockchain for Immutable Proof
        from core.blockchain import anchor_to_blockchain

        payload_hash = hashlib.sha256(payload_str.encode()).hexdigest()
        bc_entry = anchor_to_blockchain(payload_hash, creator_fp)

        return {
            "status": "protected",
            "creator_fingerprint": creator_fp,
            "payload_hash": payload_hash[:16],
            "timestamp": datetime.utcnow().isoformat(),
            "blockchain_tx": bc_entry["tx_hash"],
            "blockchain_status": bc_entry["status"],
            "download_url": f"/download/{out_filename}",
            "rs_bits_embedded": len(rs_bits),
            "message": "Asset protected with High-Redundancy DWT-LL + QIM and anchored to Polygon blockchain.",
        }
    except Exception as e:
        return {"error": str(e)}
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


@app.post("/verify")
async def verify_asset(file: UploadFile = File(...)):
    is_video = file.filename.lower().endswith(".mp4")
    temp_dir = tempfile.mkdtemp()
    temp_in = os.path.join(temp_dir, file.filename)

    try:
        with open(temp_in, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Check if we have a .meta sidecar for this file in outputs/
        possible_meta = os.path.join("outputs", file.filename + ".meta")
        if os.path.exists(possible_meta):
            shutil.copy2(possible_meta, temp_in + ".meta")
        else:
            # Also try prefixing with "protected_"
            alt_meta = os.path.join("outputs", f"protected_{file.filename}.meta")
            if os.path.exists(alt_meta):
                shutil.copy2(alt_meta, temp_in + ".meta")

        frames_to_check = [temp_in]

        if is_video:
            frames_dir = os.path.join(temp_dir, "frames")
            os.makedirs(frames_dir, exist_ok=True)
            frames_to_check = extract_frames(temp_in, frames_dir)

        verification = {"verified": False}

        for frame in frames_to_check:
            # Use delta=50 for video frames and delta=100 for single images
            delta_to_use = 50 if is_video else 100
            result = extract_watermark_robust(frame, SECRET_KEY, delta=delta_to_use)
            if result.get("verified"):
                verification = result
                break

        if verification.get("verified"):
            has_transform = (verification.get("scale_detected", 1.0) != 1.0 or verification.get("shift_detected", (0, 0)) != (0, 0))
            strength = "ULTRA" if has_transform else "HIGH"
            return {
                "status": "match_found",
                "confidence": 0.99,
                "proof_report": {
                    "creator_fingerprint": verification["creator_id"],
                    "original_timestamp": verification["timestamp"],
                    "hmac_verified": True,
                    "forensic_strength": strength,
                },
            }
        else:
            return {
                "status": "no_match",
                "confidence": 0.0,
                "proof_report": {
                    "error": "No valid DWT-DCT payload detected in asset.",
                },
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
            takedown_notice = ai_engine.generate_takedown_notice(
                "Creator_001", url, mock_proof_hash
            )

        return {
            "status": "scan_complete",
            "ai_analysis": ai_result,
            "legal_notice_draft": takedown_notice,
        }
    except Exception as e:
        return {"error": str(e)}


@app.get("/blockchain/{tx_hash}")
async def get_blockchain_record(tx_hash: str):
    """
    Returns the immutable blockchain record for a specific transaction.
    """
    if not os.path.exists("blockchain_registry.json"):
        return {"error": "Blockchain registry not found"}

    try:
        with open("blockchain_registry.json", "r") as f:
            records = json.load(f)
            for r in records:
                if r["tx_hash"] == tx_hash:
                    return r
            return {"error": "Transaction not found"}
    except Exception as e:
        return {"error": str(e)}


@app.get("/crawl-scan")
async def crawl_scan(user_uid: str = "anonymous"):
    """
    Simulates scanning popular public image-hosting sites for leaked assets.
    Uses pHash matching against the BK-Tree index of all protected assets.
    
    In production this would spawn real HTTP crawl tasks. Here we scan a
    curated list of mock "leaked" images seeded in dummy_pirate_web/ plus
    simulate plausible public-forum URL patterns for the demo.
    """
    import glob
    import httpx
    import io
    import imagehash
    from PIL import Image as PILImage

    creator_fp = generate_creator_fingerprint(user_uid)
    results = []
    alerts_written = 0

    # ── 1. Local dummy-pirate-web folder (the existing testing harness) ──
    pirate_dir = "dummy_pirate_web"
    if os.path.exists(pirate_dir):
        image_paths = glob.glob(os.path.join(pirate_dir, "*.png")) + \
                      glob.glob(os.path.join(pirate_dir, "*.jpg"))
        for img_path in image_paths[:10]:  # cap at 10 per scan
            try:
                matches = bktree_index.find_matches(img_path, tolerance=8)
                if matches:
                    dist, fp = matches[0]
                    verify_result = extract_watermark_robust(img_path, SECRET_KEY, delta=80)
                    if verify_result.get("verified"):
                        source_url = f"https://forums.example.com/t/leaked/{os.path.basename(img_path)}"
                        results.append({
                            "source_url": source_url,
                            "matched_asset": os.path.basename(img_path),
                            "creator_fingerprint": verify_result.get("creator_id", fp),
                            "phash_distance": dist,
                            "confidence": "HIGH",
                            "timestamp": datetime.utcnow().isoformat() + "Z",
                            "status": "confirmed_leak",
                        })
                        # Write alert if this belongs to the requesting user
                        if verify_result.get("creator_id") == creator_fp:
                            alerts = json.load(open("alerts.json", "r")) if os.path.exists("alerts.json") else []
                            alert_id = datetime.utcnow().strftime("%Y%m%d%H%M%S") + str(alerts_written)
                            alerts.append({
                                "id": alert_id,
                                "creator_fingerprint": creator_fp,
                                "timestamp": datetime.utcnow().isoformat(),
                                "source_url": source_url,
                                "confidence": "HIGH",
                                "tier": "Enterprise",
                                "dmca_draft": None,
                                "status": "unread",
                            })
                            with open("alerts.json", "w") as af:
                                json.dump(alerts, af, indent=2)
                            alerts_written += 1
            except Exception as e:
                pass

    # ── 2. Simulate scanning public forum CDN thumbnails ──
    MOCK_FORUM_URLS = [
        "https://i.imgur.com/placeholder1.jpg",
        "https://preview.redd.it/placeholder2.jpg",
        "https://cdn.discordapp.com/placeholder3.png",
        "https://pbs.twimg.com/media/placeholder4.jpg",
        "https://attachments.f95zone.to/placeholder5.png",
    ]
    # We don't actually download from these real URLs in the demo — we simulate matches
    # based on how many assets are registered in the BK-Tree.
    registered_count = len(bktree_index._tree) if hasattr(bktree_index, '_tree') else 0
    if registered_count == 0:
        # Try to infer from outputs directory
        registered_count = len([f for f in os.listdir("outputs") if f.endswith(".png")])

    # Return combined result
    return {
        "scan_complete": True,
        "sites_checked": len(MOCK_FORUM_URLS) + (1 if os.path.exists(pirate_dir) else 0),
        "protected_assets_indexed": registered_count,
        "leaks_found": len(results),
        "leaks": results,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


@app.get("/dashboard-stats")
async def dashboard_stats():
    """
    Returns weekly activity counts for the dashboard bar chart.
    Groups /logs entries by day-of-week and counts watermarking events per day.
    """
    from collections import defaultdict

    logs_resp = await get_upload_logs()
    logs = logs_resp.get("logs", [])

    # Bucket by day-of-week (Mon=0..Sun=6)
    day_counts = defaultdict(int)
    for entry in logs:
        try:
            ts = entry.get("protected_at", "")
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            day_counts[dt.weekday()] += 1
        except Exception:
            pass

    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    bars = [float(day_counts.get(i, 0)) for i in range(7)]

    # Ensure we always have non-trivial data when assets exist
    total = sum(bars)
    if total == 0 and logs:
        # spread evenly if timestamps can't be parsed
        per_day = len(logs) / 7
        bars = [per_day] * 7

    return {
        "labels": days,
        "bars": bars,
        "total_events": int(total) or len(logs),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
