# INDELIBLE

**Forensics as a Service (FaaS) — Digital Rights Management for Independent Creators**

INDELIBLE is a compression-resistant forensic watermarking platform that provides mathematically robust proof of ownership for digital media. Built for mid-tier sports organizations and independent creators who cannot afford enterprise-grade DRM solutions.

---

## Project Overview

### Problem
Digital content creators lack affordable tools to prove ownership of their media. Existing watermarking solutions are either trivial to remove (visible overlays) or computationally expensive (neural network-based), making them inaccessible to independent creators.

### Solution
INDELIBLE uses classical signal processing — Discrete Wavelet Transform (DWT), Discrete Cosine Transform (DCT), and Quantization Index Modulation (QIM) — to embed cryptographic watermarks directly into image/video frequency domains. These watermarks survive JPEG compression, cropping, and quality reduction while remaining visually imperceptible.

### Key Properties
- **Compression-resistant**: Watermark survives JPEG compression at quality 50+
- **Visually imperceptible**: No visible artifacts on watermarked media
- **Cryptographically verifiable**: HMAC-SHA256 signatures prove authenticity
- **Error-corrected**: Reed-Solomon encoding recovers watermarks from degraded copies
- **Fast search indexed**: BK-Tree with perceptual hashing enables O(log N) similarity search

---

## Architecture

### System Components

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │────▶│   FastAPI    │────▶│   Python     │
│   Frontend   │     │   API Layer  │     │   Core Engine│
│   (Mobile)   │◀────│   (Backend)  │◀────│   (DSP)      │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │
       ▼                    ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Firebase   │     │   BK-Tree    │     │   FFmpeg     │
│   Auth +     │     │   Index      │     │   Video I/O  │
│   Firestore  │     │   (pHash)    │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Data Flow

1. User uploads media through Flutter app
2. FastAPI receives file, saves to temporary storage
3. Python Core Engine extracts keyframes via FFmpeg scene detection
4. DWT-DCT-QIM pipeline embeds cryptographic payload into each keyframe
5. Perceptual hashes (pHash) generated and indexed in BK-Tree
6. Payload hash recorded to Firestore (mock blockchain ledger)
7. Protected media returned to user with proof report

---

## Technology Stack

### Frontend (Flutter)
- Framework: Flutter 3.x (Dart 3.9+)
- State Management: Flutter Riverpod
- Authentication: Firebase Auth (Email/Password, Google Sign-In)
- Database: Cloud Firestore (mock blockchain ledger)
- Fonts: Space Grotesk (headlines), Inter (body), Space Mono (code)

### Backend (Python)
- API: FastAPI with Uvicorn
- Signal Processing: OpenCV, PyWavelets, NumPy
- Cryptography: HMAC-SHA256, Reed-Solomon (reedsolo)
- Video Processing: FFmpeg (via subprocess)
- Indexing: imagehash (pHash), pybktree (BK-Tree)
- Database: Firebase Admin SDK (Firestore writes)

---

## Project Structure

```
indelible/
├── lib/                                    # Flutter application
│   ├── main.dart                           # Entry point, Firebase initialization
│   └── src/
│       ├── config/
│       │   └── themes/
│       │       └── app_colors.dart         # Global color palette
│       ├── screens/
│       │   ├── sections/                   # Reusable UI sections
│       │   │   ├── top_app_bar.dart        # Top navigation bar
│       │   │   ├── hero_section.dart       # Welcome/status section
│       │   │   └── stats_grid.dart         # System metrics grid
│       │   ├── login_screen.dart           # Authentication screen
│       │   ├── home_screen.dart            # Main dashboard
│       │   └── dashboard_screen.dart       # Detailed asset view
│       ├── services/
│       │   └── auth_service.dart           # Firebase authentication logic
│       └── widgets/                        # Small reusable components
├── backend/                                # Python watermarking engine
│   ├── watermark.py                        # DWT-QIM prototype (legacy)
│   ├── requirements.txt                    # Python dependencies
│   └── tests/                              # Backend test suite
├── designs/                                # HTML design references
├── pubspec.yaml                            # Flutter dependencies
└── analysis_options.yaml                   # Dart linting rules
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.9+ ([installation guide](https://docs.flutter.dev/get-started/install))
- Python 3.10+
- Firebase project with Auth enabled
- FFmpeg installed and in PATH

### Frontend Setup

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Configure Firebase
# - Install Firebase CLI: npm install -g firebase-tools
# - Run: flutterfire configure
# - Select your Firebase project

# 3. Run the app
flutter run
```

### Backend Setup

```bash
# 1. Create Python virtual environment
cd backend
python -m venv .venv

# 2. Activate environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run FastAPI server
uvicorn api.main:app --reload
```

---

## Development Workflow

### Code Organization Principles

1. **Single Responsibility**: Each file handles one concern (colors, auth, UI sections)
2. **Reusable Sections**: UI components in `sections/` are composed into screens
3. **Configuration Separation**: App-wide settings live in `config/`, not scattered across files
4. **Service Layer**: Business logic isolated in `services/`, not embedded in screens

### Naming Conventions

- **Files**: snake_case (e.g., `app_colors.dart`, `auth_service.dart`)
- **Classes**: PascalCase (e.g., `TopAppBar`, `HeroSection`)
- **Variables**: camelCase (e.g., `userName`, `isSelected`)
- **Constants**: UPPER_SNAKE_CASE for static values, camelCase for class properties

### Building New Features

1. Define the requirement in plain English (write comments first)
2. List the data inputs needed
3. Sketch the widget tree on paper
4. Implement from smallest widget upward
5. Test the integration

---

## Core Algorithms

### Watermark Embedding Pipeline

```
Input Image → YCrCb Conversion → Extract Y Channel
    → DWT (Haar Wavelet) → Extract LL Band
    → DCT on LL Band → QIM Embedding → Inverse DCT
    → Inverse DWT → Merge Channels → Watermarked Image
```

### Quantization Index Modulation (QIM)

Each bit of the payload is embedded into a DCT coefficient:
- Bit 0: Quantize coefficient to nearest even multiple of delta
- Bit 1: Quantize coefficient to nearest odd multiple of delta

This creates robust embedding that survives JPEG compression because JPEG operates on the same DCT domain.

### Payload Structure

```
CreatorID | Timestamp | HMAC-SHA256 Signature
(32 bytes)  (8 bytes)   (32 bytes)
```

The entire payload is Reed-Solomon encoded to recover from bit errors in compressed/degraded copies.

---

## API Endpoints

### POST /protect

Upload media for watermark protection.

**Request**: multipart/form-data with video file  
**Response**: JSON with payload hash, creator ID, timestamp, frame count

### POST /verify

Submit suspect media for forensic verification.

**Request**: multipart/form-data with suspect file  
**Response**: JSON with match status, confidence score, matched frames, proof report

---

## Project Roadmap

### Phase 1: Cryptographic Core (In Progress)
- [x] Basic DWT-QIM pipeline (`watermark.py`)
- [x] Color palette architecture (`app_colors.dart`)
- [x] Login screen with Firebase Auth
- [ ] DCT integration for compression robustness
- [ ] HMAC-SHA256 payload signing
- [ ] Reed-Solomon error correction encoding
- [ ] Watermark extraction and verification

### Phase 2: Video Pipeline & Indexing (Planned)
- [ ] FFmpeg scene detection wrapper
- [ ] Video watermarker (keyframe processing)
- [ ] Perceptual hash (pHash) generation
- [ ] BK-Tree index for similarity search
- [ ] Frame buffer optimization

### Phase 3: API & Flutter Bridge (Planned)
- [ ] FastAPI application structure
- [ ] /protect endpoint with multipart upload
- [ ] /verify endpoint with BK-Tree search
- [ ] Firebase Admin SDK integration
- [ ] Flutter API service layer
- [ ] Upload progress indicators
- [ ] Proof report screen

### Phase 4: Demo & Submission (Planned)
- [ ] Mock blockchain ledger (Firestore)
- [ ] Demo asset creation (pirated videos)
- [ ] End-to-end demo recording
- [ ] Pitch deck preparation

---

## Learning Resources

- **DEVELOPMENT_GUIDE.md** — Project setup and workflow documentation
- **ROADMAP.md** — Detailed 26-day hackathon plan with technical specifications

---

## License

This project is developed for educational and hackathon purposes. Not intended for production use without further security review.

---

## Acknowledgments

- DWT-DCT watermarking based on classical signal processing research
- QIM embedding algorithm inspired by Chen et al. "Quantization Index Modulation for Digital Watermarking"
- Design inspiration from forensic/cybersecurity dashboard aesthetics
