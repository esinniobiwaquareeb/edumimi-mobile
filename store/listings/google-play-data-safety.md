# Google Play — Data safety & privacy declarations

Use this when completing the **Data safety** form in Google Play Console for `com.edumimi.mock`.

## Overview

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | Yes |
| Is all data encrypted in transit? | Yes (HTTPS) |
| Can users request data deletion? | Yes (contact support / account deletion policy) |
| Committed to Play Families policy? | No (general audience 13+, exam prep) |

## Data types collected

### Account & identity
| Data | Collected | Shared | Purpose | Required |
|------|-----------|--------|---------|----------|
| Email address | Yes | No | Account creation, login, verification | Yes |
| Name | Yes | No | Profile, leaderboard display | Optional |
| Phone number | Optional | No | Profile, referral/payout if enabled | Optional |
| User IDs | Yes | No | Authentication, attempts, purchases | Yes |

### App activity
| Data | Collected | Shared | Purpose | Required |
|------|-----------|--------|---------|----------|
| App interactions | Yes | No | Exam attempts, scores, streaks | Yes |
| In-app search history | No | No | — | — |
| Other user-generated content | Yes | No | Community chat messages, reactions | Optional |

### Financial info
| Data | Collected | Shared | Purpose | Required |
|------|-----------|--------|---------|----------|
| Purchase history | Yes | No | Package access, billing support | Optional |
| Payment info | No* | No | *Processed by Paystack; app stores reference only | — |

### Device or other IDs
| Data | Collected | Shared | Purpose | Required |
|------|-----------|--------|---------|----------|
| Device or other IDs (FCM token) | Yes | No | Push notifications (streak reminders) | Optional |

## Security practices

- Data encrypted in transit via TLS
- Auth tokens stored in platform secure storage (Keychain / EncryptedSharedPreferences)
- Transaction PIN handled server-side for checkout

## Data deletion

Document in privacy policy:
- Users can request account/data deletion via support@edumimi.com (update with real contact)
- Purchases and attempts may be retained for legal/accounting requirements as stated in policy

## Permissions declared (Android)

| Permission | Why |
|------------|-----|
| INTERNET | API, chat, payments |
| POST_NOTIFICATIONS | Streak reminders (Android 13+) |
| Camera / Photos | Optional profile avatar upload |

## Content rating questionnaire hints

- No gambling
- User-generated content: Yes (community chat) — moderation/reporting available
- No violent or mature content
- In-app purchases: Yes (digital exam access packages)
