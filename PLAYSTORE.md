# Play Store release guide — mock.edumimi

## App identity

| Field | Value |
|-------|-------|
| App name | mock.edumimi |
| Package ID | `com.edumimi.mock` |
| Min SDK | 23 (Android 6.0+) |
| Category | Education |
| Content rating | Everyone (exam prep, no UGC moderation required beyond chat reports) |

## Short description (80 chars)

JAMB, WAEC & NECO mock exams — practice offline, chat, streak reminders.

## Full description

mock.edumimi helps Nigerian students prepare for JAMB, WAEC, and NECO with timed full mocks, topic drills, and past papers.

**Features**
- Personalized dashboard with weak-topic insights
- Offline practice with automatic sync when you reconnect
- LaTeX and HTML question rendering for maths and science
- Paystack checkout for premium packs
- Study Squad community chat
- Daily streak push reminders

Part of the Edumimi learning platform.

## Release build

1. Copy `android/key.properties.example` to `android/key.properties` and create a release keystore:

```bash
keytool -genkey -v -keystore android/keystore/mock-edumimi-release.jks \
  -alias mock-edumimi -keyalg RSA -keysize 2048 -validity 10000
```

2. Replace `android/app/google-services.json` with your Firebase project file.

3. Build the release APK/AAB:

```bash
flutter build appbundle \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_APP_ID=your-app-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id
```

4. Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

## Backend checklist

- `PAYSTACK_SECRET_KEY` configured for live checkout
- `MOCK_FRONTEND_URL` set (Paystack callback still uses web verify URL; mobile verifies via API)
- `FIREBASE_SERVICE_ACCOUNT_JSON` set for streak push cron
- Community chat enabled for verified mock customers

## Store assets checklist

Generated assets live in `store/assets/` — regenerate with `python3 store/generate_store_assets.py`.

- [x] 512×512 hi-res icon (`play-store-icon-512.png`)
- [x] 1024×1024 App Store icon (`app-store-icon-1024.png`)
- [x] Feature graphic 1024×500 (`feature-graphic-1024x500.png`)
- [ ] Phone screenshots (capture from device; frames in `store/assets/screenshot-frames/`)
- [ ] Privacy policy URL live at https://mock.edumimi.com/privacy
- [ ] Data safety form: see `store/listings/google-play-data-safety.md`

Full readiness checklists: [store/STORE_DEPLOYMENT.md](store/STORE_DEPLOYMENT.md)

## Deep links

Custom scheme: `mockedumimi://app/dashboard` (used by notification tap handling).
