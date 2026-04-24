# INDELIBLE

**Forensics as a Service (FaaS) — Compression-Resistant Digital Watermarking & AI Piracy Detection**

INDELIBLE embeds cryptographically signed, invisible watermarks into images and video using classical signal processing (DWT + QIM). When pirated copies surface, the platform extracts the watermark, verifies the HMAC signature, identifies the original creator via a unique `INDL-XXXX-XXXX-XXXX` fingerprint, and auto-generates DMCA takedown notices using Gemini 2.5 Flash.

---

## How It Works

```
1. PROTECT ──▶ User uploads media → DWT+QIM embeds signed payload → PNG returned
2. VERIFY  ──▶ User uploads suspect copy → Payload extracted → HMAC verified → Proof report
3. SCAN    ──▶ AI scrapes URL → Gemini classifies piracy → Legal notice drafted
```

### Core Pipeline

```
Image → YCrCb (extract Y) → Haar DWT → LL subband → QIM embed payload bits
    → Inverse DWT → Clip to uint8 → Save as PNG + .meta sidecar
```

The payload is: `CreatorFingerprint | UTC Timestamp | HMAC-SHA256`, Reed-Solomon encoded to 1400 bits for error correction.

---

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │────▶│   FastAPI    │────▶│   Python DSP │
│   Frontend   │     │   + Uvicorn  │     │   + Gemini AI│
│   (Web/Mobile)│◀────│   API Layer  │◀────│   Engine     │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │
       ▼                    ▼                     ▼
 Firebase Auth      Creator Registry       FFmpeg Video I/O
                   (JSON fingerprint DB)
```

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Flutter + Dart | Cross-platform UI |
| State | Riverpod | Reactive state management |
| Auth | Firebase Auth | Email + Google Sign-In |
| API | FastAPI + Uvicorn | HTTP endpoints, file serving |
| DSP | OpenCV, PyWavelets, NumPy | DWT, DCT, QIM watermarking |
| Crypto | hmac, hashlib, reedsolo | HMAC-SHA256 + Reed-Solomon ECC |
| AI | google-genai (Gemini 2.5 Flash) | Multimodal piracy detection |
| Video | FFmpeg (subprocess) | Frame extraction & stitching |
| Scraping | httpx, BeautifulSoup4 | Web content crawling |

---

## Project Structure

```
indelible/
├── backend/
│   ├── core/
│   │   ├── watermark.py          # DWT+QIM embed/extract engine
│   │   ├── payload.py            # HMAC + Reed-Solomon crypto
│   │   ├── ai_engine.py          # Gemini 2.5 piracy classifier
│   │   ├── scraper.py            # Web scraper with fallback
│   │   ├── video_processor.py    # FFmpeg frame extraction
│   │   └── bktree_index.py       # Perceptual hash indexing
│   ├── main.py                   # FastAPI server & endpoints
│   ├── outputs/                  # Protected files served here
│   ├── creator_registry.json     # Fingerprint ↔ UID mapping
│   └── .env                      # GEMINI_API_KEY (not committed)
├── lib/
│   ├── main.dart
│   └── src/
│       ├── config/themes/app_colors.dart
│       ├── screens/
│       │   ├── sections/
│       │   │   ├── top_app_bar.dart
│       │   │   ├── hero_section.dart
│       │   │   ├── quick_actions.dart    # File upload + API calls
│       │   │   ├── stats_grid.dart
│       │   │   ├── recent_assets_list.dart
│       │   │   └── recent_activity_list.dart
│       │   ├── login_screen.dart
│       │   └── home_screen.dart
│       └── services/auth_service.dart
├── LEARNING_GUIDE.md             # Deep technical reference (read this!)
├── ROADMAP.md                    # Phase breakdown & status
└── PROJECT_STATUS.md             # Current completion tracker
```

---

## Quick Start

### Prerequisites
- Flutter SDK 3.9+
- Python 3.10+
- FFmpeg in PATH
- Firebase project with Auth enabled

### Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt

# Create .env with your Gemini key
echo GEMINI_API_KEY=your_key_here > .env

# Start server
python -m uvicorn main:app --reload
```

### Frontend

```bash
flutter pub get
flutter run -d chrome
```

---

## API Endpoints

| Method | Endpoint | Body | Returns |
|--------|----------|------|---------|
| POST | `/protect` | `file` (multipart) + `user_uid` (form) | `creator_fingerprint`, `download_url`, `blockchain_tx` |
| POST | `/verify` | `file` (multipart) | `status` (match_found/no_match), `proof_report` |
| POST | `/scan-piracy` | `url` (form) | `ai_analysis`, `legal_notice_draft` |
| GET | `/download/{filename}` | — | Binary file download |

---

## Key Algorithms

- **DWT (Haar)** — Decomposes image into frequency subbands (LL, LH, HL, HH)
- **QIM (delta=80)** — Embeds bits by quantizing LL coefficients to even/odd grid points
- **HMAC-SHA256** — Produces unforgeable signatures using a secret key
- **Reed-Solomon (nsym=64)** — Corrects up to 32 byte-errors in extracted payloads
- **SHA-256 Fingerprinting** — Derives deterministic `INDL-XXXX-XXXX-XXXX` from Firebase UID

---

## License

Hackathon project — educational use. Not production-ready without security audit.

## Acknowledgments

- QIM: Chen & Wornell, "Quantization Index Modulation for Digital Watermarking"
- Reed-Solomon: `reedsolo` library by Tomer Filiba
- AI: Google Gemini 2.5 Flash multimodal API
