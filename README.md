# WaspadaAI

AI-powered scam & hoax detector built with Flutter + Gemini 1.5 Flash.
Created for Google Juara Vibe Coding competition.

## Stack
- Flutter (Material 3)
- Provider (state management)
- Google Fonts — Plus Jakarta Sans
- Gemini 1.5 Flash via Firebase Cloud Functions
- Lottie animations

## Quick Start
```bash
flutter pub get
flutter run
```

## Switch to Production
In `lib/main.dart`, set:
```dart
const bool kUseMock = false;
const String kFirebaseUrl = 'https://YOUR-REGION-PROJECT.cloudfunctions.net/analyzeContent';
```

## Lottie Assets
Download from lottiefiles.com and place in `assets/lottie/`:
- `scanning.json` — for loading state
- `success.json`  — for safe result
- `danger.json`   — for danger result
