# Store deployment — mock.edumimi mobile

Complete guide for **Google Play** and **Apple App Store** releases of the Flutter app (`com.edumimi.mock`).

---

## Quick reference

| Item | Value |
|------|-------|
| Package / Bundle ID | `com.edumimi.mock` |
| Store app name | mock.edumimi |
| Device display name | Edumimi Mock |
| Version | `1.0.0+1` (update in `pubspec.yaml` before each release) |
| Production API | `https://api.edumimi.com` |
| Web / marketing | `https://mock.edumimi.com` |
| Firebase project | `edumimi-mock` |
| Category | Education |

**Generated assets:** `store/assets/` (run `store/generate_store_assets.py`)  
**Listing copy:** `store/listings/store-listing-copy.md`  
**Play data safety:** `store/listings/google-play-data-safety.md`  
**Android release steps:** [PLAYSTORE.md](../PLAYSTORE.md)

---

## Asset inventory

Regenerate all marketing assets:

```bash
cd mock_mobile
store/.venv/bin/python store/generate_store_assets.py
# or: python3 -m venv store/.venv && store/.venv/bin/pip install pillow && ...
```

| File | Size | Used for |
|------|------|----------|
| `store/assets/play-store-icon-512.png` | 512×512 | Google Play hi-res icon |
| `store/assets/app-store-icon-1024.png` | 1024×1024 | App Store icon (no transparency) |
| `store/assets/feature-graphic-1024x500.png` | 1024×500 | Google Play feature graphic |
| `store/assets/promo-tile-180.png` | 180×180 | Optional Play promo |
| `store/assets/screenshot-frames/*.png` | 1080×1920 | Replace inner area with real screenshots |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` | various | iOS home screen (already in project) |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | various | Android launcher (already in project) |

### Screenshots still required (capture from device/simulator)

| Platform | Size | Screens to capture |
|----------|------|-------------------|
| Google Play | 1080×1920 min (16:9 phone) | Dashboard, exam session, results, packages, community |
| App Store 6.7" | 1290×2796 | Same 5–6 screens |
| App Store 6.5" | 1284×2778 | Same (or let App Store scale) |

**Tip:** Use `flutter run --release` on a physical device, capture with system screenshot tools, paste into the frames or upload directly.

---

## Master readiness checklist

### A. Code & configuration

- [ ] `pubspec.yaml` version bumped (`version: x.y.z+build`)
- [ ] Bundle ID is `com.edumimi.mock` on **both** iOS and Android
- [ ] `android/app/google-services.json` — production Firebase Android app
- [ ] `ios/Runner/GoogleService-Info.plist` — production Firebase iOS app
- [ ] `lib/firebase_options.dart` matches Firebase project `edumimi-mock`
- [ ] Release builds use `--dart-define=MOCK_API_URL=https://api.edumimi.com`
- [ ] Release builds use `--dart-define=MOCK_WEB_URL=https://mock.edumimi.com`
- [ ] No debug API URLs or localhost in release builds
- [ ] App icons use clean white background (not black box)

### B. Backend & services (production)

- [ ] `api.edumimi.com` deployed with latest backend (mobile Turnstile bypass, Post-UTME fixes)
- [ ] `PAYSTACK_SECRET_KEY` — **live** key configured
- [ ] Paystack callback / verify flow tested end-to-end on device
- [ ] `FIREBASE_SERVICE_ACCOUNT_JSON` on server (streak push cron)
- [ ] APNs key uploaded in Firebase Console (iOS push)
- [ ] Community chat enabled for verified mock customers
- [ ] CORS / rate limits allow mobile client

### C. Signing & credentials

#### Android
- [ ] Release keystore created (`android/keystore/mock-edumimi-release.jks`)
- [ ] `android/key.properties` configured (not committed)
- [ ] SHA-256 fingerprint added to Firebase Console
- [ ] SHA-256 added to `mock-frontend/public/.well-known/assetlinks.json`
- [ ] `flutter build appbundle --release` succeeds

#### iOS
- [ ] Apple Developer account active
- [ ] App ID `com.edumimi.mock` registered
- [ ] Push Notifications capability enabled
- [ ] Associated Domains: `applinks:mock.edumimi.com`
- [ ] Distribution certificate + App Store provisioning profile
- [ ] `GoogleService-Info.plist` in Runner target
- [ ] `apple-app-site-association` uses `TEAMID.com.edumimi.mock`
- [ ] Archive + upload via Xcode or `flutter build ipa`

### D. Legal & policy URLs

- [ ] Privacy policy live at `https://mock.edumimi.com/privacy`
- [ ] Terms of service live at `https://mock.edumimi.com/terms`
- [ ] Policy covers: account data, exam attempts, payments, FCM tokens, community chat
- [ ] Support email listed in store listings
- [ ] “Not affiliated with JAMB/WAEC/NECO” disclaimer in description

### E. Store listing content

- [ ] Short description (80 chars) — see `store/listings/store-listing-copy.md`
- [ ] Full description uploaded
- [ ] Keywords / promotional text (App Store)
- [ ] Feature graphic uploaded (Play)
- [ ] Icons uploaded (512 Play, 1024 App Store)
- [ ] 5+ phone screenshots per platform
- [ ] Content rating questionnaire completed
- [ ] Data safety form completed (Play) — see `google-play-data-safety.md`
- [ ] App Privacy labels completed (Apple)

### F. QA before submit

- [ ] Fresh install: signup → onboarding → first practice
- [ ] Login / logout / password reset / email verify (deep links)
- [ ] Exam start → submit → view result
- [ ] Paystack purchase → verify → unlocked exam
- [ ] Offline mode: start exam offline, sync on reconnect
- [ ] Community chat send/receive
- [ ] Push: enable streak toggle, receive test notification
- [ ] Bottom nav / back navigation on all main flows
- [ ] iPad / large phone layout acceptable (or phone-only declared)

### G. Post-submission

- [ ] Internal testing track (Play) / TestFlight (Apple) with team
- [ ] Monitor crash reports (Firebase Crashlytics if added)
- [ ] Respond to store review feedback within 24h
- [ ] Tag git release `mobile-v1.0.0`

---

## Google Play — step-by-step

1. Create app in [Google Play Console](https://play.google.com/console) with package `com.edumimi.mock`
2. **Store presence → Main store listing** — paste copy from `store-listings/store-listing-copy.md`
3. Upload assets from `store/assets/`
4. **Policy → App content** — complete Data safety using `google-play-data-safety.md`
5. **Release → Production** — upload AAB:

```bash
flutter build appbundle --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com
```

Output: `build/app/outputs/bundle/release/app-release.aab`

6. Add release notes from listing copy
7. Submit for review

---

## Apple App Store — step-by-step

1. Create app in [App Store Connect](https://appstoreconnect.apple.com) with bundle ID `com.edumimi.mock`
2. **App Information** — category Education, content rights, age rating
3. **Pricing and Availability** — free with IAP (packages via Paystack web checkout — declare appropriately)
4. **App Privacy** — see `store/listings/app-store-privacy.md`
5. Upload `app-store-icon-1024.png` and screenshots
6. Build & upload:

```bash
flutter build ipa --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com
```

Or archive in Xcode → Distribute App → App Store Connect

7. **App Review Information** — demo account + notes from listing copy
8. Submit for review

---

## Universal links & deep links

| Type | Value |
|------|-------|
| Custom scheme | `mockedumimi://app/...` |
| HTTPS host | `https://mock.edumimi.com` |
| Verify email | `/auth/verify-email?token=` |
| Reset password | `/auth/reset-password?token=` |
| Payment verify | `/payments/verify?reference=` |
| Challenge | `/challenge/:token` |
| Parent view | `/parent/:token` |

**Deploy updated association files** on mock.edumimi.com:
- `public/apple-app-site-association`
- `public/.well-known/apple-app-site-association`
- `public/.well-known/assetlinks.json`

Replace `TEAMID` with your Apple Team ID and add release keystore SHA-256.

---

## Build commands reference

```bash
# Android App Bundle (Play Store)
flutter build appbundle --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com

# iOS IPA
flutter build ipa --release \
  --dart-define=MOCK_API_URL=https://api.edumimi.com \
  --dart-define=MOCK_WEB_URL=https://mock.edumimi.com

# Regenerate marketing assets
python3 store/generate_store_assets.py
```

---

## Known blockers to resolve before launch

| Blocker | Owner | Status |
|---------|-------|--------|
| Privacy policy page on mock.edumimi.com | Web | ☐ |
| Terms page on mock.edumimi.com | Web | ☐ |
| Release keystore created & backed up | Mobile | ☐ |
| Apple Team ID in AASA file | Mobile | ☐ |
| Play SHA-256 in assetlinks.json | Mobile | ☐ |
| App Store Connect demo account | Ops | ☐ |
| Live Paystack verified on production | Backend | ☐ |
| Physical device screenshot set | Design | ☐ |

---

## Version cadence

1. Bump `version` in `pubspec.yaml` (`x.y.z+build`)
2. Update “What’s New” in listing copy
3. Run QA checklist (section F)
4. Build → upload → submit
5. Tag release in git
