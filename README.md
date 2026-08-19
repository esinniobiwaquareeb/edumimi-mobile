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
- Paystack dev bypass works when `PAYSTACK_SECRET_KEY` is unset and `NODE_ENV !== production`.
- Replace `android/app/google-services.json` before enabling push in production.
- Copy `android/key.properties.example` → `android/key.properties` for signed release builds.
