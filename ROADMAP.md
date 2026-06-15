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
| **Phase 6** | Automated Testing & Cloud Deployment | ✅ Complete |
| **Phase 7** | Automated Watchdog (pHash + BK-Tree) | ✅ Complete |
| **Phase 8** | Adversarial Robustness & Blockchain | ✅ Complete |
| **Phase 9** | Premium UX Shell & Onboarding GPU Paint | ✅ Complete |
| **Phase 10** | Bento-Grid Dashboard & Custom Painted Charts | ✅ Complete |
| **Phase 11** | Staging Diagnostics & Timezone Consistency | ✅ Complete |

---

## Phase 8: Adversarial Robustness & Blockchain ✅ (Final Upgrade)

### Deliverables
- `core/watermark.py` — High-Redundancy DWT-LL Redundant engine + scale search
- `core/payload.py` — Reed-Solomon (nsym=128) + 24-char padded payload upgrade
- `core/blockchain.py` — Simulated Polygon anchoring system
- `tests/test_robustness.py` — Automated evaluation suite

### Technical Details
- **High Redundancy:** Watermark is embedded into *every* available coefficient of the LL subband, enabling majority-vote recovery.
- **Robust Alignment & Grid Search:** Verification performs a grid search scaling from 0.80 to 1.00 and translation offsets `[-1, 0, 1]` with black center-canvas restoration, neutralizing cropping and re-alignment attacks.
- **Fast-Fail Anchor Check:** Prepended a static 16-bit anchor to fast-fail grid alignments if Hamming distance > 4.
- **Tuned ECC (nsym=128):** Upgraded Reed-Solomon parity to 128 bytes to handle coefficient dampening from Gaussian Blur (kernel 5x5).
- **Blockchain Anchoring:** Each protection event creates an immutable record in `blockchain_registry.json`, simulating a mainnet deployment.
- **Robustness Results:** 100% recovery (0% - 1.21% BER) against JPEG 20/50, noise 10, crop 5%/10%, and blur 5x5.

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

## Phase 6: Automated Testing & Cloud Deployment ✅

### Deliverables
- `tests/test_watermark.py`, `test_payload.py`, `test_api.py` — Pytest suite
- `Dockerfile` — Containerized backend
- Railway Deployment — Permanent HTTPS endpoint

### Technical Details
- **Mathematical Extraction Fix:** Replaced naive modulo math in QIM extraction with absolute geometric distance to quantization multiples.
- **Dockerization:** Packaged `ffmpeg`, `libgl1`, and headless OpenCV to remove GUI dependencies on the cloud.
- **Permanent Tunneling:** Replaced ephemeral ngrok/localtunnel with Railway's permanent edge network.

---

## Phase 7: Automated Watchdog & pHash Scaling ✅

### Deliverables
- `core/bktree_index.py` — pHash similarity search using BK-Tree
- `core/monitoring_daemon.py` — Async background monitoring task
- `/alerts` API — Real-time notification endpoint

### Technical Details
- **pHash Indexing:** Integrated `imagehash.phash` to create a perceptual signature for every protected asset.
- **BK-Tree Search:** Implemented a Burkhard-Keller tree to enable $O(\log N)$ fuzzy matching across the global registry.
- **Watchdog Daemon:** Created a background process that simulates an internet-wide crawler, using pHash as a fast-filter before running heavy DWT verification.
- **Enterprise Logic:** Integrated subscription tier checks (`Enterprise` vs `Basic`) to trigger automatic Gemini-based DMCA drafting.

---

## Phase 9: Premium UX Shell & Onboarding GPU Paint ✅

### Deliverables
- `lib/src/screens/intro_screens/intro_screen1.dart` — Stateful `RadarShieldPainter`
- `lib/src/screens/intro_screens/intro_screen2.dart` — Stateful `FrequencyWavePainter`
- `lib/src/screens/intro_screens/intro_screen3.dart` — Stateful `CryptoProofPainter`
- `lib/src/app.dart` — Route configuration adjustment

### Technical Details
- **GPU-Accelerated Custom Painting**: Replaced heavy/static onboarding assets with custom vector math lines, grids, arcs, and nodes painted directly to the Skia/Impeller canvas using an `AnimationController` at 60-120 FPS.
- **Signal Wave Model**: Synthesized approximation, watermark, and details band wave formulas dynamically phase-shifting on the second onboarding slide.
- **Connected Proof Ledger**: Modeled a Merkle tree connection grid on the third onboarding slide, utilizing linear interpolation (`Offset.lerp`) to feed glowing verification data packets through paths.
- **Routing Loop Resolution**: Set `/splash` as `initialRoute` and mapped `'/'` directly to `AuthGate()` to isolate the onboarding sequence and fix the vault screen refresh/reload loop on icon taps.
- **Deprecation Updates**: Converted standard color opacity configurations to `color.withValues(alpha: ...)` to ensure strict compatibility with the latest Flutter stable release.

---

## Phase 10: Bento-Grid Dashboard & Custom Painted Charts ✅

### Deliverables
- `lib/src/screens/dashboard_screen.dart` — Fully updated dashboard UI shell and paint logic
- `lib/src/app.dart` — Added `/dashboard` route mapping
- `lib/src/screens/layouts/dashboard_layout.dart` — Connected drawer tiles to the dashboard route
- `lib/src/screens/sections/left_sidebar.dart` — Integrated desktop navigation sidebar click actions

### Technical Details
- **Bento-Grid Visual Structure**: Arranged key widgets as rounded dashboard cells matching mockup alignments, including a large main card with diagonal arrows, circular gauges, and activity bars.
- **Custom painted gauges**: Designed `BentoCircularGaugePainter` drawing circular segments to represent the success rates of verification events.
- **Custom weekly bar chart**: Implemented a responsive weekly activity monitor utilizing `BarChartPainter` that highlights high-performance days, includes custom coordinate positioning, and renders interactive tooltip layers directly on the canvas.
- **Ambiguous Namespace Handling**: Resolved compiler errors by implementing specific namespace hides on sections.
## Phase 11: Staging Diagnostics & Timezone Consistency ✅

### Deliverables
- `backend/main.py` — Timezone formatting correction & clean imports

### Technical Details
- **Double Timezone Fixed**: Corrected the timestamp encoding in endpoints (e.g. `/logs` and `/crawl-scan`) from appending raw `+ "Z"` (generating invalid `+00:00Z` suffixes) to using `.replace("+00:00", "Z")`, preventing client-side `FormatException` crashes in Flutter/Dart.
- **Clean Imports & Compliance**: Formatted datetime and timezone imports according to PEP 8 standards, and validated that the robust watermark extractor (`extract_watermark_robust`) signatures match call sites with required `SECRET_KEY` parameters.

---

## Future Roadmap (Post-Hackathon)

| Feature | Technology | Impact |
|---------|-----------|--------|
| Real blockchain anchoring | Polygon + Solidity | Immutable proof ledger |
| Global Web Crawler | Distributed Scrapy | Real internet-wide monitoring |
| Distributed processing | Celery + Redis | Parallel video watermarking |
| Mobile-native file handling | `path_provider` + `dio` | Replace `dart:html` web-only code |
| Production auth | Proper OAuth2 Client IDs | Replace mock Google Sign-In |

---

**Build complete. Ready for judges.** 🏆
