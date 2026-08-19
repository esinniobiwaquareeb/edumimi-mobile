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

## Architecture

```
lib/
  core/          theme, network, storage, reusable widgets, router
  features/      auth, dashboard, exams, leaderboard, results, profile, shell
  shared/models/ API models
```

## Run

```bash
cd mock_mobile
flutter pub get

# Point at your NestJS API (default: localhost:3000)
flutter run \
  --dart-define=MOCK_API_URL=http://10.0.2.2:3000   # Android emulator
# flutter run --dart-define=MOCK_API_URL=http://127.0.0.1:3000  # iOS simulator
# flutter run --dart-define=MOCK_API_URL=https://api.edumimi.com  # production
```

## Notes

- Login works without Cloudflare Turnstile when `MOCK_TURNSTILE_SECRET_KEY` is unset (local dev).
- Exam questions strip HTML for display; rich LaTeX rendering can be added later.
- Offline: questions are cached per subject, in-progress attempts persist locally, and submissions queue until reconnect.
- Community chat and payments are web-first for now; core practice loop is in the app.
