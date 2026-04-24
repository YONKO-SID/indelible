# INDELIBLE — Hackathon Roadmap & Technical Plan

**Hackathon Submission:** April 24–26, 2026  
**Status:** ✅ COMPLETE — Ready for Submission

---

## Phase Summary

| Phase | Goal | Status |
|-------|------|--------|
| **Phase 1** | Cryptographic Core (DWT+QIM+HMAC+RS) | ✅ Complete |
| **Phase 2** | Video Pipeline & FFmpeg | ✅ Complete |
| **Phase 3** | FastAPI + Flutter Bridge | ✅ Complete |
| **Phase 4** | AI Threat Intelligence (Stretch Goal) | ✅ Complete |
| **Phase 5** | Creator Identity & Verification Loop | ✅ Complete |

---

## Phase 1: Cryptographic Core ✅

### Deliverables
- `core/watermark.py` — DWT + QIM embed/extract with .meta sidecar
- `core/payload.py` — HMAC-SHA256 signing + Reed-Solomon (nsym=64) encoding

### Technical Details
- **Payload:** `CreatorFingerprint|Timestamp|HMAC` → RS-encoded → 1400 bits
- **Embedding:** 1-level Haar DWT → QIM on LL subband coefficients (delta=80)
- **Output:** PNG (lossless) + JSON `.meta` sidecar for reliable extraction

### Trials & Lessons
| Attempt | Approach | BER | Result |
|---------|----------|-----|--------|
| 1 | Full-band DCT, 1 bit/coeff | 40.2% | ❌ uint8 noise |
| 2 | 2-level DWT, block-DCT | N/A | ❌ Insufficient capacity |
| 3 | 1-level DWT, 10 bits/block | 26.9% | ❌ Still too high |
| 4 | Higher delta (200–2000) | 40–46% | ❌ Noise is pixel-domain |
| **5** | **DWT+QIM + .meta sidecar** | **0%** | **✅ Verified** |

---

## Phase 2: Video Pipeline ✅

### Deliverables
- `core/video_processor.py` — FFmpeg 1-FPS extraction + audio-preserving stitching

### Pipeline
```
MP4 input → FFmpeg (1 fps) → N frames → watermark each → FFmpeg stitch → MP4 output
```

---

## Phase 3: FastAPI + Flutter Bridge ✅

### Deliverables
- `main.py` — FastAPI server with `/protect`, `/verify`, `/scan-piracy`, `/download`
- `quick_actions.dart` — Multipart upload + `dart:html` download + Firebase UID passing

### Endpoints
| Endpoint | Method | Input | Output |
|----------|--------|-------|--------|
| `/protect` | POST | file + user_uid | fingerprint, download_url, blockchain_tx |
| `/verify` | POST | file | match status, HMAC proof report |
| `/scan-piracy` | POST | url | AI analysis, DMCA legal draft |
| `/download/{f}` | GET | — | FileResponse (octet-stream) |

---

## Phase 4: AI Threat Intelligence ✅ (Stretch Goal)

### Deliverables
- `core/ai_engine.py` — Gemini 2.5 Flash zero-shot piracy classifier + DMCA generator
- `core/scraper.py` — httpx + BeautifulSoup4 web scraper with fallback

### Pipeline
```
URL → Scraper → Image → Gemini Vision → is_pirated? → Auto-generate DMCA notice
```

---

## Phase 5: Creator Identity ✅

### Deliverables
- `generate_creator_fingerprint()` in `main.py`
- `creator_registry.json` persistent storage

### How It Works
```
Firebase UID → SHA-256 → "INDL-A7F3-9BC2-E1D4" → stored in registry
```

During `/verify`, the backend iterates all registered fingerprints, computes each one's RS bit count, and attempts extraction until HMAC verification succeeds.

---

## Future Roadmap (Post-Hackathon)

| Feature | Technology | Impact |
|---------|-----------|--------|
| Real blockchain anchoring | Polygon + Solidity | Immutable proof ledger |
| Vector similarity search | Milvus / Pinecone | Sub-ms search across 10M+ frames |
| Distributed processing | Celery + Redis | Parallel video watermarking |
| Mobile-native file handling | `path_provider` + `dio` | Replace `dart:html` web-only code |
| Production auth | Proper OAuth2 Client IDs | Replace mock Google Sign-In |

---

**Build complete. Ready for judges.** 🏆
