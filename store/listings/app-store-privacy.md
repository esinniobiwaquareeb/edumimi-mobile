# App Store — App Privacy (nutrition labels)

Complete in **App Store Connect → App Privacy** for `com.edumimi.mock`.

## Data linked to the user

### Contact info
| Data type | Collected | Linked to identity | Tracking | Purpose |
|-----------|-----------|-------------------|----------|---------|
| Email address | Yes | Yes | No | App functionality, account |
| Name | Yes | Yes | No | App functionality, personalization |
| Phone number | Optional | Yes | No | App functionality (profile / referral) |

### User content
| Data type | Collected | Linked to identity | Tracking | Purpose |
|-----------|-----------|-------------------|----------|---------|
| Other user content | Yes | Yes | No | App functionality (community chat) |

### Identifiers
| Data type | Collected | Linked to identity | Tracking | Purpose |
|-----------|-----------|-------------------|----------|---------|
| User ID | Yes | Yes | No | App functionality |
| Device ID (FCM token) | Optional | Yes | No | App functionality (push reminders) |

### Usage data
| Data type | Collected | Linked to identity | Tracking | Purpose |
|-----------|-----------|-------------------|----------|---------|
| Product interaction | Yes | Yes | No | App functionality, analytics (exam attempts, scores) |

### Purchases
| Data type | Collected | Linked to identity | Tracking | Purpose |
|-----------|-----------|-------------------|----------|---------|
| Purchase history | Yes | Yes | No | App functionality |

## Data not collected for tracking

Select **No** for “Do you or your third-party partners use data for tracking?” unless you add ad SDKs later.

## Third-party data processors

| Partner | Data | Purpose |
|---------|------|---------|
| Paystack | Payment session (via WebView) | Package checkout |
| Firebase (Google) | FCM token | Push notifications |
| Your API (`api.edumimi.com`) | Account, attempts, chat | Core app functionality |

## Privacy policy URL

`https://mock.edumimi.com/privacy`

## Age rating

Recommend **4+** / no restricted content. Community chat has report flow; no open public posting without account.
