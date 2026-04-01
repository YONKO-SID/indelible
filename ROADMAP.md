# INDELIBLE - Hackathon Roadmap & Technical Plan

**Hackathon Submission Target:** April 24-26  
**Current Date:** March 29, 2026  
**Timeline:** 4 Weeks (26 Days)

---

## 📋 Executive Summary

INDELIBLE is a **Forensics as a Service (FaaS)** platform providing compression-resistant forensic watermarking and automated piracy tracking for mid-tier sports organizations and independent creators.

### Core Value Proposition
- **Mathematically robust** watermarking using classical signal processing (not expensive neural networks)
- **Low server overhead** via DWT-DCT + QIM pipeline
- **High accessibility** for creators who can't afford enterprise DRM solutions
- **Cryptographic proof of ownership** with HMAC signatures and Reed-Solomon error correction

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INDELIBLE ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │   Flutter    │────▶│   FastAPI    │────▶│   Python     │                │
│  │   Frontend   │     │   API Layer  │     │   Core Engine│                │
│  │   (Mobile)   │◀────│   (Backend)  │◀────│   (DSP)      │                │
│  └──────────────┘     └──────────────┘     └──────────────┘                │
│         │                   │                      │                        │
│         ▼                   ▼                      ▼                        │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │   Firebase   │     │   BK-Tree    │     │   FFmpeg     │                │
│  │   Auth +     │     │   Index      │     │   Video I/O  │                │
│  │   Firestore  │     │   (pHash)    │     │              │                │
│  └──────────────┘     └──────────────┘     └──────────────┘                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

DATA FLOW:
1. User uploads video → Flutter → FastAPI /protect
2. FastAPI saves to temp → Python Core extracts frames (FFmpeg)
3. DWT-DCT-QIM watermarking on keyframes
4. Generate pHash → Store in BK-Tree
5. Payload hash → Firestore (mock blockchain)
6. Return proof to Flutter UI
```

---

## 📁 Current Project State (As of Mar 29)

### ✅ What Exists

```
indelible/
├── backend/
│   ├── watermark.py          # ⚠️ BASIC: Simple DWT-QIM (no DCT, no HMAC, no RS)
│   ├── test.jpg              # Test image
│   ├── watermarked_final.png # Output from watermark.py
│   └── [DWT band visualizations]
├── lib/
│   ├── main.dart             # ⚠️ STUB: Just runs IndelibleApp
│   ├── src/
│   │   ├── app.dart          # ⚠️ STUB: MaterialApp with LoginScreen
│   │   ├── screens/
│   │   │   ├── login_screen.dart  # ⚠️ BROKEN: Nested MaterialApp, syntax error
│   │   │   └── home_screen.dart   # ⚠️ EMPTY
│   │   ├── services/         # 📁 EMPTY
│   │   ├── widgets/          # 📁 EMPTY
│   │   └── config/           # 📁 EMPTY
│   └── firebase_options.dart # ✅ Exists (Firebase configured)
├── pubspec.yaml              # ⚠️ MINIMAL: Only flutter + cupertino_icons
├── DEVELOPMENT_GUIDE.md      # ✅ Generic guide
├── README.md                 # ⚠️ MINIMAL
└── ROADMAP.md                # This file
```

### ❌ What's Missing (Critical Gaps)

| Component | Status | Priority |
|-----------|--------|----------|
| DCT integration in watermark.py | Missing | 🔴 Critical |
| HMAC signature generation | Missing | 🔴 Critical |
| Reed-Solomon error correction | Missing | 🔴 Critical |
| Watermark extraction logic | Missing | 🔴 Critical |
| FastAPI backend | Missing | 🔴 Critical |
| Flutter UI (login, home, upload) | Missing | 🟡 High |
| Firebase Auth integration | Missing | 🟡 High |
| BK-Tree indexing | Missing | 🟡 High |
| Video processing (FFmpeg) | Missing | 🟢 Medium |
| pHash generation | Missing | 🟢 Medium |

---

## 📅 Phase Breakdown

### **PHASE 0: Project Setup & Cleanup** (Mar 29 - Mar 30)
**Goal:** Fix broken code, establish proper project structure

| Task | File | Action |
|------|------|--------|
| Fix login_screen.dart syntax | `lib/src/screens/login_screen.dart` | Remove nested MaterialApp |
| Update pubspec.yaml | `pubspec.yaml` | Add firebase_core, flutter_riverpod, http, file_picker |
| Create backend structure | `backend/core/`, `backend/api/`, `backend/tests/` | mkdir |
| Create requirements.txt | `backend/requirements.txt` | Add all Python deps |

---

### **PHASE 1: Cryptographic Core** (Mar 31 - Apr 6)
**Goal:** Refactor watermark.py into production-ready engine with full embed/extract cycle

| Day | Task | Deliverable | Success Criteria |
|-----|------|-------------|------------------|
| 1-2 | Refactor DWT-DCT | `core/watermark.py` | DWT → DCT on LL band, separate embed/extract functions |
| 3-4 | QIM Engine | `core/qim.py` | Tunable delta, survives JPEG 50-90 quality |
| 5-6 | Payload + Crypto | `core/payload.py` | CreatorID\|Timestamp\|HMAC + Reed-Solomon encoding |
| 7   | Integration Test | `tests/test_phase1.py` | embed → JPEG compress → extract → HMAC verify ✓ |

#### Technical Specification - Phase 1

**Current watermark.py Issues:**
```python
# ❌ CURRENT: No DCT, hardcoded bits, no extraction, no crypto
LL_flattened[pixel_idx] = current_val - (current_val % 2) - EMBEDDING_STRENGTH

# ✅ TARGET: DCT on LL band, QIM with delta, HMAC+RS payload
dct_coeffs = cv2.dct(np.float32(ll_band))
qim_embed(dct_coeffs, rs_encoded_payload, delta=50)
```

**DWT-DCT Pipeline (Refactored):**
```python
# core/watermark.py
import cv2
import pywt
import numpy as np

def load_and_convert(image_path: str) -> tuple:
    """Load image, convert to YCrCb, return Y channel as float32"""
    img_bgr = cv2.imread(image_path)
    img_ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    y_channel = img_ycrcb[:, :, 0]
    return np.float32(y_channel), img_ycrcb

def dwt_decompose(y_channel: np.ndarray) -> tuple:
    """2D DWT decomposition, return LL band and all coefficients"""
    coeffs = pywt.dwt2(y_channel, 'haar')
    ll_band, (lh, hl, hh) = coeffs
    return ll_band, coeffs

def dct_transform(ll_band: np.ndarray) -> np.ndarray:
    """Apply DCT to LL band for compression robustness"""
    return cv2.dct(ll_band)

def embed_watermark_dct(dct_coeffs: np.ndarray, payload_bits: np.ndarray, delta: float = 50) -> np.ndarray:
    """QIM embedding into DCT coefficients (mid-frequency region)"""
    # Skip DC coefficient (index 0,0), embed in mid-frequencies
    height, width = dct_coeffs.shape
    bit_idx = 0
    for i in range(height):
        for j in range(width):
            if i == 0 and j == 0:  # Skip DC
                continue
            if bit_idx >= len(payload_bits):
                break
            # QIM: even = 0, odd = 1 (with delta quantization)
            coef = dct_coeffs[i, j]
            if payload_bits[bit_idx] == 0:
                dct_coeffs[i, j] = round(coef / delta) * delta
            else:
                dct_coeffs[i, j] = round(coef / delta) * delta + delta / 2
            bit_idx += 1
    return dct_coeffs

def extract_watermark_dct(dct_coeffs: np.ndarray, num_bits: int, delta: float = 50) -> np.ndarray:
    """Extract watermark bits from DCT coefficients"""
    extracted_bits = []
    height, width = dct_coeffs.shape
    bit_idx = 0
    for i in range(height):
        for j in range(width):
            if i == 0 and j == 0:
                continue
            if bit_idx >= num_bits:
                break
            coef = dct_coeffs[i, j]
            # QIM decoding: check if nearest quantization level is even or odd
            quant_level = round(coef / delta)
            extracted_bits.append(quant_level % 2)
            bit_idx += 1
    return np.array(extracted_bits)
```

**Payload Structure with HMAC + Reed-Solomon:**
```python
# core/payload.py
import hmac
import hashlib
import reedsolo
from datetime import datetime

def create_payload(creator_id: str, secret_key: bytes) -> tuple:
    """
    Create payload: CreatorID | Timestamp | HMAC
    Returns: (payload_string, payload_bits, rs_encoded_bits)
    """
    timestamp = datetime.utcnow().isoformat()
    message = f"{creator_id}|{timestamp}"
    signature = hmac.new(secret_key, message.encode(), hashlib.sha256).digest()
    
    # Full payload string
    payload_string = f"{message}|{signature.hex()}"
    
    # Convert to bits
    payload_bits = string_to_bits(payload_string)
    
    # Reed-Solomon encoding for error correction
    rs = reedsolo.RSCodec(nsym=64)  # 64 parity symbols
    rs_encoded = rs.encode(bytes_from_bits(payload_bits))
    rs_encoded_bits = bytes_to_bits(rs_encoded)
    
    return payload_string, payload_bits, rs_encoded_bits

def verify_payload(extracted_bits: np.ndarray, secret_key: bytes) -> dict:
    """
    Decode RS, verify HMAC, return verification result
    """
    # Reed-Solomon decode (corrects errors)
    rs = reedsolo.RSCodec(nsym=64)
    try:
        decoded_bytes = rs.decode(bits_to_bytes(extracted_bits))
        decoded_string = bits_to_string(bytes_to_bits(decoded_bytes))
    except reedsolo.ReedSolomonError:
        return {"verified": False, "error": "RS decode failed"}
    
    # Parse payload
    parts = decoded_string.split('|')
    if len(parts) != 3:
        return {"verified": False, "error": "Invalid payload format"}
    
    creator_id, timestamp, received_hmac = parts
    
    # Verify HMAC
    expected_message = f"{creator_id}|{timestamp}"
    expected_hmac = hmac.new(secret_key, expected_message.encode(), hashlib.sha256).hexdigest()
    
    if hmac.compare_digest(received_hmac, expected_hmac):
        return {
            "verified": True,
            "creator_id": creator_id,
            "timestamp": timestamp
        }
    return {"verified": False, "error": "HMAC mismatch"}
```

---

### **PHASE 2: Video Pipeline & Indexing** (Apr 7 - Apr 13)
**Goal:** Handle .mp4 files with scene detection and build high-speed search index

| Day | Task | Deliverable | Success Criteria |
|-----|------|-------------|------------------|
| 8-9 | FFmpeg Scene Detection | `core/video_processor.py` | Extracts frames where scene change > 0.3 |
| 10-11 | Video Watermarker | `core/video_watermarker.py` | Watermark keyframes, stitch with original audio |
| 12-13 | pHash + BK-Tree | `core/indexer.py`, `core/bktree_index.py` | 64-bit pHash, O(log N) Hamming search |
| 14 | Integration Test | `tests/test_phase2.py` | Video → watermark → alter → verify match |

#### Technical Specification - Phase 2

**FFmpeg Scene Detection:**
```python
# core/video_processor.py
import subprocess
import os

def extract_keyframes(video_path: str, output_dir: str, threshold: float = 0.3) -> list:
    """
    Extract frames where scene changes using FFmpeg
    Returns list of extracted frame paths
    """
    os.makedirs(output_dir, exist_ok=True)
    
    cmd = [
        'ffmpeg', '-i', video_path,
        '-vf', f'select=gt(scene\,{threshold})',
        '-vsync', 'vfr',
        '-qscale:v', '2',
        os.path.join(output_dir, 'frame_%04d.png')
    ]
    subprocess.run(cmd, check=True)
    
    # Get list of extracted frames
    frames = sorted([f for f in os.listdir(output_dir) if f.endswith('.png')])
    return [os.path.join(output_dir, f) for f in frames]

def stitch_video(frames_dir: str, original_audio: str, output_path: str, fps: int = 24):
    """
    Stitch watermarked frames back into video with original audio
    """
    # Create video from frames
    temp_video = os.path.join(frames_dir, 'temp_video.mp4')
    cmd = [
        'ffmpeg', '-framerate', str(fps),
        '-i', os.path.join(frames_dir, 'frame_%04d.png'),
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
        temp_video
    ]
    subprocess.run(cmd, check=True)
    
    # Combine with audio
    cmd = [
        'ffmpeg', '-i', temp_video, '-i', original_audio,
        '-c:v', 'copy', '-c:a', 'aac',
        output_path
    ]
    subprocess.run(cmd, check=True)
```

**BK-Tree for Similarity Search:**
```python
# core/bktree_index.py
from pybktree import BKTree

def hamming_distance(hash1: str, hash2: str) -> int:
    """Calculate Hamming distance between two hex hash strings"""
    int1, int2 = int(hash1, 16), int(hash2, 16)
    return bin(int1 ^ int2).count('1')

class FrameIndex:
    def __init__(self):
        self.tree = BKTree(hamming_distance)
        self.frame_data = {}  # hash -> metadata
    
    def add_frame(self, frame_hash: str, metadata: dict):
        """Add frame hash to index with metadata"""
        self.tree.insert(frame_hash)
        self.frame_data[frame_hash] = metadata
    
    def search(self, query_hash: str, max_distance: int = 10) -> list:
        """Find all frames within Hamming distance threshold"""
        results = self.tree.query(query_hash, max_distance)
        return [
            {
                "hash": r[1],
                "distance": r[0],
                "metadata": self.frame_data.get(r[1], {})
            }
            for r in results
        ]
```

---

### **PHASE 3: FastAPI & Flutter Bridge** (Apr 14 - Apr 20)
**Goal:** Connect Python engine to internet, integrate Flutter frontend

| Day | Task | Deliverable | Success Criteria |
|-----|------|-------------|------------------|
| 15-16 | FastAPI Setup | `api/main.py`, `api/endpoints.py` | /protect and /verify endpoints working |
| 17-18 | Firebase Admin | `api/firebase_client.py` | Firestore writes for mock blockchain |
| 19-21 | Flutter Services | `lib/src/services/api_service.dart` | Multipart upload/verify with progress |
| 22-23 | Flutter UI | `home_screen.dart`, `proof_report_screen.dart` | Upload, progress, results display |

#### API Endpoints Specification

**POST /protect**
```
Request: multipart/form-data with video file
Response: {
    "status": "protected",
    "payload_hash": "a3f5...8c2d",
    "creator_id": "user_123",
    "timestamp": "2026-04-15T14:30:00Z",
    "frame_count": 47,
    "blockchain_tx": "mock_tx_hash_for_demo"
}
```

**POST /verify**
```
Request: multipart/form-data with suspect video
Response: {
    "status": "match_found" | "no_match",
    "confidence": 0.94,
    "matched_frames": [
        {
            "original_hash": "a3f5...8c2d",
            "suspect_hash": "a3f5...9d1e",
            "hamming_distance": 3,
            "extracted_payload": "user_123|2026-04-15T14:30:00Z|hmac_sig"
        }
    ],
    "proof_report": {
        "creator_id": "user_123",
        "original_timestamp": "2026-04-15T14:30:00Z",
        "hmac_verified": true,
        "forensic_strength": "HIGH"
    }
}
```

---

### **PHASE 4: Mocking & Pitch** (Apr 21 - Apr 26)
**Goal:** Fake enterprise features for demo, record submission

| Day | Task | Deliverable | Notes |
|-----|------|-------------|-------|
| 22 | Mock Blockchain | Firestore schema + UI display | Show "Tx Hash" in Proof Report |
| 23 | Demo Assets | 3 pirated videos | Crop + quality reduce from protected output |
| 24-26 | Recording | Demo video, pitch deck | Freeze code, submit |

#### Demo Script (for recording)
1. **Scene 1:** Login as creator "SportsChannel_Pro"
2. **Scene 2:** Upload highlight reel → "Protecting..." progress → Success with hash
3. **Scene 3:** Show "Blockchain Tx" in Firestore viewer
4. **Scene 4:** Upload pirated version (cropped, lower quality)
5. **Scene 5:** System instantly matches → Proof Report with 94% confidence
6. **Scene 6:** Show HMAC verification, creator ID, timestamp

---

## 🔮 Future Roadmap (Post-Hackathon)

### 1. Distributed Infrastructure (Celery + Redis)
```
Current: Synchronous FastAPI (blocks on video processing)
Future: 
    FastAPI → Redis Queue → Celery Workers → S3 Storage
    - Parallel video processing
    - Progress webhooks to Flutter
    - Horizontal scaling for enterprise load
```

### 2. Immutable Ledger (Polygon + Web3.py)
```
Current: Firestore mock "blockchain"
Future:
    Solidity Smart Contract on Polygon Mainnet
    - storeProof(bytes32 payloadHash, uint256 timestamp)
    - getProof(bytes32 payloadHash) returns (creatorId, timestamp, txHash)
    - Web3.py integration in FastAPI
    - Real cryptographic anchoring, not mock
```

### 3. Vector Database (Milvus / Pinecone)
```
Current: Local pybktree (single machine, limited scale)
Future:
    Milvus Cloud or Pinecone
    - Sub-millisecond Hamming search across 10M+ frames
    - Distributed index sharding
    - Auto-scaling for enterprise sports orgs
```

### 4. AI Threat Intelligence (Gemini API)
```
Future Pipeline:
    Web Scraper Fleet → Gemini Zero-Shot Classifier → pHash Filter → BK-Tree
    
    Gemini Prompt:
    "Is this video likely to contain pirated sports content? 
     Answer YES/NO with confidence score."
    
    - Filters out non-sports media before expensive pHash pipeline
    - Reduces server costs by 60-70%
    - Automated takedown notice generation
```

---

## 🎯 Success Metrics for Hackathon

| Metric | Target | Stretch Goal |
|--------|--------|--------------|
| Watermark survival after JPEG (quality=50) | 95% bit recovery | 99% |
| BK-Tree search latency (10K frames) | < 100ms | < 50ms |
| Video processing time (1 min clip) | < 30 sec | < 15 sec |
| Demo proof report accuracy | 90%+ confidence | 95%+ |
| Pitch deck completeness | All slides | + live demo |

---

## ⚠️ Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| QIM delta tuning fails | Watermark visible or lost to compression | Start with delta=50, test JPEG 50-90 quality range |
| FFmpeg scene detection misses frames | Watermark gaps in video | Lower threshold to 0.2, add manual frame sampling |
| BK-Tree too slow | Demo lag | Pre-build index, limit to 10K frames for demo |
| Firebase Auth delays | Can't login in demo | Add mock "Demo Login" button with hardcoded user |
| API upload timeout | Video too large | Chunked upload, show progress, 100MB limit for demo |

---

## 🚀 Immediate Next Steps (TODAY - Mar 29)

### Priority 1: Fix Broken Code
1. **Fix login_screen.dart** - Remove nested MaterialApp, syntax error
2. **Run `flutter pub get`** - Ensure Flutter builds

### Priority 2: Backend Setup
1. **Create folder structure** - `backend/core/`, `backend/api/`, `backend/tests/`
2. **Create requirements.txt** - Install Python dependencies
3. **Create virtual environment** - `python -m venv .venv`

### Priority 3: Phase 1 Implementation
1. **Refactor watermark.py** - Add DCT, separate embed/extract functions
2. **Create payload.py** - HMAC + Reed-Solomon encoding
3. **Test on sample image** - Verify embed → JPEG → extract cycle

---

## 📞 Team Coordination

| Role | Responsibility | Handoff Points |
|------|----------------|----------------|
| Backend (You) | Python core, FastAPI | API endpoints ready by Apr 20 |
| Frontend (Teammate) | Flutter UI, Firebase | Needs /protect and /verify specs |
| Pitch (Together) | Demo recording, slides | Code freeze Apr 24 |

---

**Good luck. Build robust. Win the hackathon.** 🏆
