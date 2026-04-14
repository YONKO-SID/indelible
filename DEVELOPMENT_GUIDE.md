## PROJECT GUIDE

### 1. Project Structure

```
indelible/
├── backend/
│   ├── watermark.py
│   └── ...
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── ...
│   └── ...
└── ...
```

### 2. Tech Stack

- **Frontend**: Flutter
- **Backend**: Python
- **Database**: Firebase
- **Storage**: Firebase Storage
- **Authentication**: Firebase Authentication

### 3. Development Workflow

1. **Setup**: Install Flutter and Firebase CLI
2. **Backend**: Implement watermark.py and Firebase functions
3. **Frontend**: Build Flutter app with Firebase integration
4. **Testing**: Test watermark embedding and extraction
5. **Deployment**: Deploy to Firebase

### 4. Key Features

- **Watermark Embedding**: Embed 64-bit watermark into images
- **Watermark Extraction**: Extract watermark from images
- **Watermark Verification**: Verify watermark integrity
- **Watermark Removal**: Remove watermark from images
- **Watermark Detection**: Detect watermark in images

### 5. API Endpoints

- `POST /api/watermark/embed`: Embed watermark into image
- `POST /api/watermark/extract`: Extract watermark from image
- `POST /api/watermark/verify`: Verify watermark integrity
- `POST /api/watermark/remove`: Remove watermark from image
- `POST /api/watermark/detect`: Detect watermark in image

### 6. Testing

```bash
# Test watermark embedding
python backend/watermark.py --input test.jpg --output watermarked.jpg --embed

# Test watermark extraction
python backend/watermark.py --input watermarked.jpg --output extracted.jpg --extract

# Test watermark verification
python backend/watermark.py --input watermarked.jpg --verify

# Test watermark removal
python backend/watermark.py --input watermarked.jpg --output removed.jpg --remove

# Test watermark detection
python backend/watermark.py --input watermarked.jpg --detect
```

### 7. Deployment

```bash
# Deploy to Firebase
firebase deploy
```

### 8. Troubleshooting

```bash
# Common issues
# - Firebase authentication errors: Check firebase_options.dart
# - Watermark extraction errors: Check watermark.py for correct embedding
# - API errors: Check Firebase Cloud Functions logs
```

### 9. Best Practices

- Use Firebase Authentication for user management
- Use Firebase Storage for image storage
- Use Firebase Cloud Functions for backend logic
- Use Flutter for frontend development
- Use Python for watermark implementation
- Use Docker for containerization
- Use CI/CD for automated testing and deployment

### 10. Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs/)
- [Python Documentation](https://docs.python.org/3/)


### 11. Function overview

-(lib/src/screens/login_screen.dart) - Loginscreen widget controls the entire login and signup process
-(src/services/firebase_service.dart) - Firebase service for authentication and storage
-(src/config/firebase_config.dart) - Firebase configuration for authentication and storage
-(lib/src/screens/sections/stats_grid.dart) - Grid layout component that displays the monitoring engine stats (Watermark Persistence, etc)
-(lib/src/screens/sections/quick_actions.dart) - Dashboard buttons component containing the Protect Asset and Verify Asset actions
-(lib/src/screens/sections/recent_activity_list.dart) - Feed component that displays recent security alerts and system events
-(lib/src/screens/sections/recent_assets_list.dart) - Horizontal scrolling gallery component spotlighting recently protected digital assets
-(backend/storage/firebase.py) - Backend python script configured to interface with Firebase. Contains fallback architecture to mock saving proofs if `serviceAccountKey.json` is missing.

### 12. User Flow Diagram

```mermaid
graph TD
    A([Launch App]) --> B{Authenticated?}
    B -- Yes ----> E[HomeScreen / Dashboard]
    B -- No --> C[Login / Signup Screen]
    C --> D[Firebase Authentication]
    D -- Success --> E
    
    E --> F{Quick Actions}
    
    F -- Protect Asset --> G[Select & Upload Image/Video]
    G --> H((FastAPI Backend))
    H --> I[Embed Forensic DWT-DCT Watermark]
    I --> J[(Save Cryptographic Proof to Firebase)]
    J --> K[Download Protected Asset]
    
    F -- Verify Asset --> L[Upload Asset for Verification]
    L --> M((FastAPI Backend))
    M --> N[Extract & Decode Hidden Hash]
    N --> O[(Check Integrity against Firebase)]
    O --> P[Display Verification Pass/Fail]
    
    K --> Q[Update Recent Assets & Feed]
    P --> Q
```