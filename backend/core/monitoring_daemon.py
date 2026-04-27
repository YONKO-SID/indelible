import asyncio
import os
import glob
import shutil
import json
import logging
from datetime import datetime
from PIL import Image
import imagehash

from core.bktree_index import index as bktree_index
from core.watermark import extract_watermark_dct
from core.payload import verify_payload
from core.ai_engine import IndelibleAIEngine

logger = logging.getLogger("IndelibleDaemon")

PIRATE_DIR = "dummy_pirate_web"
PROCESSED_DIR = os.path.join(PIRATE_DIR, "processed")
ALERTS_FILE = "alerts.json"
REGISTRY_FILE = "creator_registry.json"
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY environment variable not set. Create backend/.env with SECRET_KEY and do not commit it.")
SECRET_KEY = SECRET_KEY.encode()


# Initialize directories
os.makedirs(PIRATE_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)

class MonitoringDaemon:
    def __init__(self):
        self.is_running = False
        self.ai_engine = IndelibleAIEngine()

    def _load_alerts(self):
        if os.path.exists(ALERTS_FILE):
            try:
                with open(ALERTS_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                return []
        return []

    def _save_alerts(self, alerts):
        with open(ALERTS_FILE, "w") as f:
            json.dump(alerts, f, indent=4)

    def _get_creator_tier(self, fingerprint: str):
        if os.path.exists(REGISTRY_FILE):
            try:
                with open(REGISTRY_FILE, "r") as f:
                    registry = json.load(f)
                    if fingerprint in registry:
                        return registry[fingerprint].get("tier", "Basic")
            except Exception:
                pass
        return "Basic"

    async def scan_cycle(self):
        """Scans the dummy pirate web folder for new images."""
        images = glob.glob(os.path.join(PIRATE_DIR, "*.*"))
        # Filter out directories
        images = [img for img in images if os.path.isfile(img)]
        
        if not images:
            return

        logger.info(f"Daemon found {len(images)} new files to scan.")
        
        for img_path in images:
            try:
                filename = os.path.basename(img_path)
                logger.info(f"Scanning {filename} with pHash filter...")
                
                # 1. pHash Fast Filter
                matches = bktree_index.find_matches(img_path, tolerance=5)
                
                if matches:
                    closest_dist, possible_fingerprint = matches[0]
                    logger.info(f"⚠️ pHash match found! Dist: {closest_dist}. Suspected owner: {possible_fingerprint}")
                    
                    # 2. Heavy DWT Extraction (Cryptographic Proof)
                    # For the demo, we use 1408 bits which matches our RS-64 payload
                    extracted_bits = extract_watermark_dct(img_path, num_bits=1408, delta=80)
                    verify_result = verify_payload(extracted_bits, SECRET_KEY)
                    
                    if verify_result.get("verified"):
                        actual_fingerprint = verify_result.get("creator_id")
                        logger.info(f"🚨 DWT Cryptographic proof successful for {actual_fingerprint}")
                        
                        # 3. Check Subscription & Route Action
                        tier = self._get_creator_tier(actual_fingerprint)
                        dmca_draft = None
                        
                        if tier == "Enterprise":
                            logger.info("Enterprise tier detected. Generating DMCA...")
                            # Since this is a background daemon, we use mock reasoning for the DMCA to save API calls, 
                            # or we can call Gemini. Let's call Gemini.
                            try:
                                # Mock reasoning to save API latency in background
                                mock_reasoning = f"Cryptographic watermark (HMAC-SHA256) extracted and verified with 100% confidence matching creator {actual_fingerprint}."
                                dmca_draft = self.ai_engine.generate_takedown_notice(
                                    creator_id=actual_fingerprint,
                                    reasoning=mock_reasoning,
                                    platform_url=f"https://pirate.mock.web/{filename}"
                                )
                            except Exception as e:
                                logger.error(f"Failed to generate DMCA: {e}")
                                dmca_draft = "Failed to generate DMCA draft."
                        
                        # 4. Generate Alert
                        alerts = self._load_alerts()
                        alert = {
                            "id": datetime.utcnow().strftime("%Y%m%d%H%M%S"),
                            "creator_fingerprint": actual_fingerprint,
                            "timestamp": datetime.utcnow().isoformat(),
                            "source_url": f"https://pirate.mock.web/{filename}",
                            "confidence": "100%",
                            "tier": tier,
                            "dmca_draft": dmca_draft,
                            "status": "unread"
                        }
                        alerts.append(alert)
                        self._save_alerts(alerts)
                        logger.info(f"Alert generated and saved for {actual_fingerprint}")
                    else:
                        logger.info("DWT extraction failed. False positive from pHash.")
                else:
                    logger.debug(f"No pHash matches for {filename}. Ignored.")
            except Exception as e:
                logger.error(f"Error processing {img_path}: {e}")
            finally:
                # Move to processed folder
                try:
                    dest = os.path.join(PROCESSED_DIR, os.path.basename(img_path))
                    shutil.move(img_path, dest)
                except Exception as e:
                    logger.error(f"Failed to move processed file: {e}")

    async def run(self):
        self.is_running = True
        logger.info("Automated Monitoring Daemon started.")
        while self.is_running:
            try:
                await self.scan_cycle()
            except Exception as e:
                logger.error(f"Daemon scan cycle error: {e}")
            await asyncio.sleep(15) # Scan every 15 seconds

    def stop(self):
        self.is_running = False
        logger.info("Automated Monitoring Daemon stopped.")

daemon = MonitoringDaemon()
