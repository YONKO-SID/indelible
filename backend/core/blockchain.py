import hashlib
import json
import os
from datetime import datetime

BLOCKCHAIN_DB = "blockchain_registry.json"


def anchor_to_blockchain(payload_hash: str, creator_fingerprint: str):
    """
    Simulates anchoring a watermark payload to a public blockchain (e.g. Polygon).
    In a real app, this would send a transaction and wait for a receipt.
    """
    db = []
    if os.path.exists(BLOCKCHAIN_DB):
        with open(BLOCKCHAIN_DB, "r") as f:
            db = json.load(f)

    tx_hash = f"0x{hashlib.sha256((payload_hash + str(datetime.now(timezone.utc))).encode()).hexdigest()}"

    entry = {
        "tx_hash": tx_hash,
        "payload_hash": payload_hash,
        "creator_fingerprint": creator_fingerprint,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "network": "Polygon PoS (Mainnet)",
        "status": "Confirmed",
        "confirmations": 12,
        "contract_address": "0xIndelibleV1ForensicsContractAddress...",
    }

    db.append(entry)
    with open(BLOCKCHAIN_DB, "w") as f:
        json.dump(db, f, indent=4)

    return entry
