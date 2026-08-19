# mock_mobile

Native Flutter client for the Edumimi mock exam portal (JAMB, WAEC, NECO practice).

## Stack

- **Flutter** — Android & iOS
- **Riverpod** — state management
- **go_router** — navigation
- **Dio** — HTTP client
- **flutter_secure_storage** — auth token persistence
- **hive_flutter** — offline question cache, in-progress sessions, submit queue
- **connectivity_plus** — online/offline detection and sync
- **flutter_math_fork** + **flutter_html** — LaTeX and HTML question rendering
- **webview_flutter** — Paystack checkout
- **socket_io_client** — Study Squad community chat
- **firebase_messaging** — streak reminder push notifications

## Architecture

```
lib/
  core/          theme, network, storage, offline, widgets, router
  features/      auth, dashboard, exams, payments, community, push, leaderboard, results, profile, shell
  shared/models/ API models
```

## Run

```bash
cd mock_mobile
flutter pub get

# Production API + web URLs (see .env.example for all dart-defines)
flutter run --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com

# Build + install profile, then launch from home screen (if flutter run hangs on ptrace):
flutter build ios --profile --dart-define=MOCK_API_URL=https://api.edumimi.com

# Release builds (store deploy)
flutter build appbundle --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com

flutter build ios --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com

# Point at your NestJS API (default: localhost:3000)
flutter run \
  --dart-define=MOCK_API_URL=http://10.0.2.2:3000   # Android emulator

# Optional Firebase push (replace with your Firebase project values)
flutter run \
  --dart-define=MOCK_API_URL=http://10.0.2.2:3000 \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_APP_ID=your-app-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id
```

## Features

- Auth, dashboard, practice catalog, timed exam sessions, leaderboard, scores
- Offline question cache, in-progress resume, queued submit sync
- Rich LaTeX/HTML questions and comprehension passages
- Paystack package checkout + payment verification
- Study Squad community chat (REST history + Socket.IO live messages)
- FCM streak reminders (toggle in profile)
- Play Store release guide: see [PLAYSTORE.md](PLAYSTORE.md)

## Notes

- Login works without Cloudflare Turnstile when `MOCK_TURNSTILE_SECRET_KEY` is unset (local dev).
- Mobile clients send `X-Mock-Client: mobile` — the backend skips Turnstile for mobile. **Production deploy required:** if login fails against `api.edumimi.com`, ensure the backend with mobile bypass is deployed.
- Paystack dev bypass works when `PAYSTACK_SECRET_KEY` is unset and `NODE_ENV !== production`.
- Replace `android/app/google-services.json` before enabling push in production.
- Copy `android/key.properties.example` → `android/key.properties` for signed release builds.
- Dart defines are documented in [.env.example](.env.example) (pass each as `--dart-define=KEY=value`).

## Firebase setup (push notifications)

Remote streak reminders require Firebase Cloud Messaging. Without configuration, the app still runs; the Notifications screen shows setup instructions and offers a **local notification preview**.

### 1. Firebase Console

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Add an **Android** app with package name `com.edumimi.mock_mobile`.
3. Add an **iOS** app with bundle ID `com.edumimi.mockMobile`.
4. Download config files:
   - Android → `google-services.json` → replace `android/app/google-services.json`
   - iOS → `GoogleService-Info.plist` → add to `ios/Runner/` and include in Xcode Runner target

### 2. Dart defines (required at build time)

```bash
flutter run \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_APP_ID=1:123456789:android:abcdef \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789
```

Values come from Firebase project settings and each platform app config.

### 3. iOS notes

- The placeholder `google-services.json` does **not** block iOS builds — iOS uses `GoogleService-Info.plist`, not the Android JSON file.
- Enable **Push Notifications** capability in Xcode for the Runner target.
- Upload your APNs key in Firebase Console → Project settings → Cloud Messaging.

### 4. Android notes

- `google-services.json` must match your Firebase Android app (replace the placeholder).
- Minimum SDK is **23** (Android 6.0+) — required by Firebase Messaging.
- For release builds, use the release keystore SHA-256 in Firebase Console and in `mock-frontend/public/.well-known/assetlinks.json`.
- Copy `android/key.properties.example` → `android/key.properties` for signed Play Store uploads.

## Deep links

Custom scheme: `mockedumimi://app/...` (Android manifest + iOS URL scheme). HTTPS universal links use `MOCK_WEB_URL` host (default `https://mock.edumimi.com`); web auth paths `/auth/verify-email` and `/auth/reset-password` map to mobile `/verify-email` and `/reset-password`.

Universal link files live in `mock-frontend/public/` (`apple-app-site-association`, `.well-known/assetlinks.json`). Replace `TEAMID` in the AASA file with your Apple Team ID and add release/debug SHA-256 fingerprints to `assetlinks.json` before deploying mock.edumimi.com.

Supported routes: `/verify-email`, `/reset-password`, `/challenge/:token`, `/parent/:token`, `/payments/verify`.

```bash
# iOS simulator
xcrun simctl openurl booted "mockedumimi://app/challenge/test-token"

# Android emulator/device
adb shell am start -a android.intent.action.VIEW -d "mockedumimi://app/verify-email?token=test-token"
```
