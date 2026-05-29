# startGOLD — Enterprise Technical Documentation

> **Version:** 1.0.0 | **Platform:** Flutter (Android & iOS) | **Domain:** Fintech — Digital Gold & Silver Investment
> **Classification:** CONFIDENTIAL — Internal Use Only

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Security Architecture](#2-security-architecture)
3. [Screen Documentation](#3-screen-documentation)
   - 3.1 Splash Screen
   - 3.2 Onboarding Screen
   - 3.3 Login Screen
   - 3.4 OTP Verification Screen
   - 3.5 Registration Screen
   - 3.6 Registration Success Screen
   - 3.7 PIN Creation Screen
   - 3.8 MPIN Screen (Login / App Lock / Reset)
   - 3.9 Change MPIN Screen
   - 3.10 Home Screen (Dashboard)
   - 3.11 Instant Saving Screen
   - 3.12 Payment Methods Screen
   - 3.13 KYC Screen (Dynamic)
   - 3.14 PAN Verification Screen
   - 3.15 Daily Savings Screen
   - 3.16 Withdrawal Screen
   - 3.17 UPI Selection Screen
   - 3.18 Withdrawal Confirmation Screen
   - 3.19 Withdrawal Success Screen
   - 3.20 Auto Savings (SIP) Screen
   - 3.21 Manage Savings Screen
   - 3.22 SIP Cancel Screen
   - 3.23 SIP Payment Screen
   - 3.24 SIP Success / Failure Screens
   - 3.25 SIP Transaction History & Details
   - 3.26 SIP Overview Screen
   - 3.27 Transaction History Screen
   - 3.28 Transaction Details Screen
   - 3.29 Profile Screen
   - 3.30 Account Details Screen
   - 3.31 Delete Account Screen
   - 3.32 Settings Screen
   - 3.33 Notifications Screen
   - 3.34 Nominee Screen
   - 3.35 Referral Screen
   - 3.36 Referee List Screen
   - 3.37 Support Screen
   - 3.38 Enquiry Form Screen
   - 3.39 Enquiry List Screen
   - 3.40 Content Screens (Terms, Privacy, About, Refund, FAQ, Contact)
   - 3.41 Maintenance Screen
   - 3.42 Main Screen (Bottom Navigation Shell)
4. [WebSocket Integration](#4-websocket-integration)
5. [Compliance Matrix](#5-compliance-matrix)

---

## 1. Architecture Overview

### 1.1 Technology Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod (providers, notifiers, streams) |
| Networking | Dio with custom interceptor chain |
| Real-time Data | Socket.IO (live metal rates) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Local Security | FlutterSecureStorage (AES-backed) |
| Encryption | RSA-OAEP-SHA256 (server public key) |
| Biometrics | local_auth (fingerprint / Face ID) |
| Navigation | Named routes via `AppRouter` |

### 1.2 Project Structure

```
lib/
├── core/
│   ├── config/          # AppConfig (URLs, keys, sensitive fields)
│   ├── constants/       # Static values
│   ├── error/           # Failure models, API error mapping
│   ├── localization/    # Multi-language support (en, ta, te)
│   ├── models/          # Shared data models
│   ├── network/         # ApiClient (Dio wrapper)
│   ├── providers/       # Global Riverpod providers
│   ├── security/        # Encryption, interceptor, session, storage
│   ├── services/        # Business services (auth, FCM, notification)
│   └── utils/           # Validators, formatters
├── features/            # 21 feature modules (screens + logic)
├── routes/              # AppRouter — centralized route definitions
└── shared/              # Reusable widgets, theme, utilities
```

### 1.3 Module Map

| # | Module | Screens | Business Domain |
|---|--------|---------|----------------|
| 1 | `auth` | Login, OTP, Registration, PIN Creation | User authentication |
| 2 | `mpin` | MPIN Screen, Change MPIN | App lock & identity verification |
| 3 | `kyc` | Dynamic KYC, PAN Verification | Regulatory compliance |
| 4 | `home` | Dashboard | Portfolio overview & navigation hub |
| 5 | `instant_saving` | Instant Saving, Payment Methods | One-time gold/silver purchase |
| 6 | `daily_savings` | Daily Savings | Recurring micro-investments |
| 7 | `sip` | Auto Savings, Manage, Cancel, Payment, Success/Failure, History | Systematic Investment Plans |
| 8 | `withdrawal` | Withdrawal, UPI Selection, Confirmation, Success | Cash-out to bank/UPI |
| 9 | `profile` | Profile, Account Details, Delete Account | User management |
| 10 | `notifications` | Notifications | Push notification center |
| 11 | `nominee` | Nominee | Beneficiary management |
| 12 | `referral` | Referral, Referee List | Growth & rewards |
| 13 | `settings` | Settings | App preferences |
| 14 | `support` | Support, Enquiry Form, Enquiry List | Customer service |
| 15 | `content` | Terms, Privacy, About, Refund, FAQ, Contact | Legal & informational |
| 16 | `market` | (Embedded in Home) | Live rate display |
| 17 | `history` | Transaction History, Transaction Details | Audit trail |
| 18 | `splash` | Splash | App initialization |
| 19 | `onboarding` | Onboarding | First-time user introduction |
| 20 | `maintenance` | Maintenance | Server downtime handling |
| 21 | `main` | Main Screen (tab shell) | Bottom navigation container |

---

## 2. Security Architecture

### 2.1 Security Layer Stack

```
┌─────────────────────────────────────────────┐
│           UI Layer (Screens)                │
├─────────────────────────────────────────────┤
│     ApiSecurityInterceptor (Dio)            │
│  ┌─────────┬──────────┬──────────────────┐  │
│  │ Offline  │ Auth     │ RSA Encryption   │  │
│  │ Guard    │ Token    │ (sensitive only) │  │
│  └─────────┴──────────┴──────────────────┘  │
├─────────────────────────────────────────────┤
│     Session Manager                         │
│  ┌─────────┬──────────┬──────────────────┐  │
│  │ 401     │ 409      │ Token            │  │
│  │ Refresh │ Force    │ Lifecycle        │  │
│  │         │ Logout   │                  │  │
│  └─────────┴──────────┴──────────────────┘  │
├─────────────────────────────────────────────┤
│     FlutterSecureStorage (AES-256)          │
├─────────────────────────────────────────────┤
│     OS-Level: Root/Jailbreak Detection      │
│     FLAG_SECURE (screenshot block)          │
└─────────────────────────────────────────────┘
```

### 2.2 Encryption Protocol

| Aspect | Implementation |
|--------|---------------|
| Algorithm | RSA-OAEP-SHA256 |
| Key Source | Server endpoint `crypto/public-key` |
| Key Storage | FlutterSecureStorage (AES-backed) |
| Scope | Field-level (only sensitive fields) |
| Sensitive Fields | `password`, `otp`, `mpin`, `pan`, `aadhaar_number`, `bank_account_number`, `upi_id`, `amount`, `withdrawal_amount` |

### 2.3 Session Security

| Feature | Mechanism |
|---------|-----------|
| Token Storage | FlutterSecureStorage |
| Token Refresh | Silent 401 retry via interceptor |
| Session Invalidation | 409 Conflict → force logout + dialog |
| App Lock | MPIN/Biometric on every app resume |
| Idle Timeout | Managed via lifecycle observer |

### 2.4 Runtime Protection

| Protection | Implementation |
|-----------|---------------|
| Root/Jailbreak Detection | `RootDetectionService` at startup |
| Screenshot Prevention | `FLAG_SECURE` in `MainActivity.kt` |
| Screen Recording Block | Global `FLAG_SECURE` |
| Back-Navigation Guard | `PopScope` on auth/payment screens |
| Double-Tap Prevention | `_navigating` flags on all CTAs |

---

## 3. Screen Documentation

---

### 3.1 Splash Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/splash` |
| **File** | `lib/features/splash/splash_screen.dart` |
| **Purpose** | App initialization gate — session check, version check, maintenance check |

**Features:**
- Animated logo fade-in (800ms)
- Minimum 2s display time (brand impression)
- Back-press exits app (no empty stack)

**Business Logic:**
1. Check `SessionManager.isAuthenticated()` + `SecureStorageService.isMpinEnabled()`
2. Fetch `AppControlService.fetchAppControl()` for maintenance & version info
3. Route decision:
   - Maintenance ON → `/maintenance`
   - Update required → blocking update dialog
   - Logged in + MPIN enabled → `/mpin`
   - Otherwise → `/login`

**API Integrations:**

| API | Purpose |
|-----|---------|
| `GET shared/app-control` | Maintenance status + version info |

**Security:** Back-press blocked via `PopScope(canPop: false)`. No sensitive data on screen.

**Edge Cases:** Network failure during app-control fetch → silent fail, proceed to login/mpin.

---

### 3.2 Onboarding Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/onboarding` |
| **File** | `lib/features/onboarding/onboarding_screen.dart` |
| **Purpose** | First-time user introduction to app features |

**Features:** Multi-page carousel, skip button, proceed to login.

---

### 3.3 Login Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/login` |
| **File** | `lib/features/auth/login/login_screen.dart` |
| **Purpose** | Entry point for authentication — mobile number collection |

**Features:**
- Country code picker (dynamic from API)
- 10-digit mobile input with digit-only filter
- "Initiate Secure Login" CTA (disabled until valid)
- Terms & Conditions / Privacy Policy links
- Double-back-press to exit app
- Double-tap navigation guard (`_navigating` flag)

**API Integrations:**

| API | Purpose | Encryption |
|-----|---------|-----------|
| `GET shared/country-codes` | Populate country picker | No |
| `POST users/auth/generate-otp` | Send OTP to mobile | Yes (`mobile`) |

**Validation Rules:**

| Rule | Implementation |
|------|---------------|
| Mobile format | `Validators.validateMobile()` — 10 digits |
| Country code | Dynamic from API, default `+91` |

**Security:**
- Mobile number encrypted via RSA before API call
- No sensitive data stored on this screen
- `PopScope` prevents accidental exit

**User Flow:**
```
Login → Enter Mobile → Tap "Initiate Secure Login" → OTP Screen
```

---

### 3.4 OTP Verification Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/otp` |
| **File** | `lib/features/auth/otp/otp_screen.dart` |
| **Purpose** | Verify user identity via SMS OTP |

**Features:**
- 6-digit PIN input (Pinput widget)
- 30-second countdown timer for resend
- "Resend Code" button (active after timer)
- Masked mobile display (`XX XXXX XX89`)
- "Edit" link to go back and change number
- Auto-submit on 6th digit entry
- Screenshot prevention (`ScreenProtector`)

**API Integrations:**

| API | Purpose | Encryption |
|-----|---------|-----------|
| `POST users/auth/verify-otp` | Verify OTP | Yes (`otp`, `mobile`) |
| `POST users/auth/generate-otp` (RESEND) | Resend OTP | Yes (`mobile`) |

**Post-Verification Routing:**

| Condition | Destination |
|-----------|-------------|
| New user | `/registration` |
| Existing user + MPIN enabled | `/mpin` |
| Existing user + no MPIN | `/mpin` (setup mode) |
| Forgot PIN flow | `/mpin` (reset mode) |
| UPI verification flow | `pop(true)` |

**Security:**
- Screenshot blocked during OTP display
- OTP field encrypted before transmission
- Timer prevents OTP brute-force
- Back-navigation blocked in app-lock forgot-PIN flow

**Fintech Risk:** OTP replay prevention via `otp_reference_id` tracking.

---

### 3.5 Registration Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/registration` |
| **File** | `lib/features/auth/registration/registration_screen.dart` |
| **Purpose** | Collect new user profile details |

**Features:**
- Full name, email, date of birth inputs
- Optional referral code
- Form validation before submission

**API Integrations:**

| API | Purpose | Encryption |
|-----|---------|-----------|
| `POST users/auth/register` | Create user account | Yes |

**User Flow:**
```
Registration → Fill Details → Submit → PIN Creation Screen
```

---

### 3.6 Registration Success Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/registration-success` |
| **Purpose** | Confirmation after successful registration + PIN setup |

---

### 3.7 PIN Creation Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/mpin-creation` |
| **File** | `lib/features/auth/pin/pin_creation_screen.dart` |
| **Purpose** | Set up 4-digit MPIN for app security |

**Features:**
- Enter PIN → Confirm PIN (two-step)
- PIN match validation
- FCM token registration after success

**API Integrations:**

| API | Purpose | Encryption |
|-----|---------|-----------|
| `POST users/mpin/create` | Create MPIN | Yes (`mpin`) |
| `POST users/notifications/register-token` | Register FCM token | No |

**Security:**
- MPIN encrypted via RSA
- Fire-and-forget FCM registration (non-blocking)
- Back-navigation controlled

---

### 3.8 MPIN Screen (Multi-Purpose)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/mpin` |
| **File** | `lib/features/mpin/mpin_screen.dart` |
| **Purpose** | Identity verification gate — serves 4 distinct modes |

**Modes:**

| Mode | Trigger | Behavior |
|------|---------|----------|
| `login` | After OTP verification | Verify PIN → navigate to Home |
| `app_lock` | App resume from background | Verify PIN → dismiss overlay |
| `reset_pin` | Forgot PIN flow | Enter new PIN + confirm |
| `setup` | Existing user without PIN | Create PIN (edge case recovery) |

**Features:**
- 4-digit secure PIN input
- Biometric authentication option (fingerprint/Face ID)
- "Forgot PIN?" link (conditionally hidden in reset flow)
- FCM token registration on successful login
- Back-press handling per mode

**API Integrations:**

| API | Purpose | Encryption |
|-----|---------|-----------|
| `POST users/mpin/validate` | Verify MPIN | Yes (`mpin`) |
| `POST users/mpin/reset` | Reset MPIN | Yes (`mpin`, `new_mpin`) |
| `POST users/notifications/register-token` | FCM registration | No |

**Security:**
- MPIN never stored in plaintext
- Biometric fallback to MPIN on failure
- `PopScope` blocks back-navigation in `app_lock` mode
- Session validation on every resume (409 detection)
- Double-tap prevention on verify button

**Fintech Risk:**
- Brute-force prevention via server-side rate limiting
- Session invalidation on concurrent login (409)
- App lock triggers on ANY background duration

**Edge Cases:**
- App killed during PIN setup → forces re-setup on next login
- Biometric cancelled → falls back to MPIN
- 409 during verify → force logout dialog

---

### 3.9 Change MPIN Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/change-mpin` |
| **File** | `lib/features/mpin/change_mpin_screen.dart` |
| **Purpose** | Allow authenticated user to change their MPIN |

**API:** `POST users/mpin/change` — Encrypted fields: `old_mpin`, `new_mpin`

---

### 3.10 Home Screen (Dashboard)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/home`, `/main` |
| **File** | `lib/features/home/home_screen.dart` |
| **Purpose** | Primary dashboard — portfolio overview, live rates, quick actions |

**Features:**
- Premium gradient header with greeting + avatar
- Gold/Silver toggle (shared commodity state)
- Live sell rate display with countdown timer
- Portfolio overview (weight, value, P&L)
- New customer welcome banner
- Growth streak / rate history card
- "Invest Smart, Earn Big" section (dynamic from API)
- Discover section (Withdrawal, Referral, Auto Saving)
- Learn carousel (dynamic banners from API)
- Support section
- Pull-to-refresh
- Notification bell with unread badge count
- Market closed/open status per commodity

**API Integrations:**

| API | Purpose |
|-----|---------|
| `POST users/portfolio` | Portfolio weight + value |
| `GET users/home/dashboard` | Dashboard sections (invest, learn, footer) |
| `POST users/notifications/unread-count` | Badge count |
| WebSocket `market_rates` | Live gold/silver rates |

**Technical Logic:**
- **Sell Rate Timer:** Locks displayed rate for N seconds (from `sell_rate_lock_seconds` config)
- **Market Status:** Socket event `5|...|1/0` toggles market open/close per commodity
- **Race Condition Guard:** When market reopens, timer restarts; if first rate frame is 0, re-locks on next non-zero rate
- **Tab Refresh:** All providers invalidated when Home tab becomes active

**Edge Cases:**
- Market closed → amber badge, rates show last known
- Network error → graceful error card with retry
- New customer → welcome banner instead of portfolio

---

### 3.11 Instant Saving Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/instant-saving` |
| **File** | `lib/features/instant_saving/instant_saving_screen.dart` |
| **Purpose** | One-time gold/silver purchase — core revenue screen |

**Features:**
- Gold/Silver commodity tabs
- "Buy in Rupees" / "Buy in Grams" toggle
- Amount input with denomination chips (from API)
- Live rate display with countdown timer
- GST calculation (+3%)
- Weight ↔ Amount conversion
- Min/max validation (from config API)
- Market closed banner
- "Pay Now" footer with amount dropdown

**API Integrations:**

| API | Purpose | Encryption |
|-----|---------|-----------|
| `GET savings/config` | Rate lock duration, GST, min/max | No |
| `GET savings/denominations/amount` | Amount chip values | No |
| `GET savings/denominations/weight` | Weight chip values | No |
| `POST savings/check-eligibility` | KYC + eligibility check | Yes |
| `POST savings/initiate` | Create purchase order | Yes |
| WebSocket | Live rates | N/A |

**Validation Rules:**

| Rule | Source |
|------|--------|
| Minimum amount | `config.minAmount` |
| Maximum amount | `config.maxAmount` |
| Market open | Socket market status |

**Security:**
- Amount encrypted in API payload
- Rate locked for configured duration (prevents price manipulation)
- KYC gate before payment

**Fintech Risk:**
- Rate expiry handling (timer-based lock)
- Market closed → purchase blocked
- Duplicate transaction prevention via order ID

**User Flow:**
```
Select Metal → Enter Amount → Pay Now → Eligibility Check → KYC (if needed) → Payment Gateway → Success
```

---

### 3.12 Payment Methods Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/payment-methods` |
| **File** | `lib/features/instant_saving/screens/payment_methods_screen.dart` |
| **Purpose** | Payment gateway selection and SDK launch |

**Features:**
- Displays available payment methods
- Launches Cashfree/Razorpay payment SDK
- Handles payment callbacks (success/failure/cancelled)

**Security:**
- `AppLifecycleObserver.suppressAppLock = true` during payment (prevents lock during UPI intent)
- PCI DSS delegated flow — card details never touch app
- Payment verification via server callback

---

### 3.13 KYC Screen (Dynamic)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/kyc-dynamic` |
| **File** | `lib/features/kyc/kyc_screen.dart` |
| **Purpose** | Collect KYC documents as required by regulations |

**Features:**
- Dynamic step rendering based on pending KYC items
- PAN, Aadhaar, Bank verification steps
- Document upload capability
- Progress indicator

**API Integrations:**

| API | Encryption |
|-----|-----------|
| `POST users/kyc/upload` | Yes (`pan_number`, `aadhaar_number`, `bank_account_number`) |
| `POST users/submit-kyc` | Yes |

**Compliance:** RBI KYC norms, PMLA compliance

---

### 3.14 PAN Verification Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/pan-verification` |
| **Purpose** | Standalone PAN verification for investment eligibility |

**Security:** PAN number encrypted via RSA before transmission.

---

### 3.15 Daily Savings Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/daily-savings` |
| **Purpose** | Configure daily micro-investment settings |

---

### 3.16 Withdrawal Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/withdrawal` |
| **File** | `lib/features/withdrawal/screens/withdrawal_screen.dart` |
| **Purpose** | Sell gold/silver and withdraw cash to bank/UPI |

**Features:**
- Select metal to sell
- Enter withdrawal amount/weight
- Live buy rate with timer lock
- UPI/Bank account selection
- Min/max validation
- Market closed guard

**API Integrations:**

| API | Encryption |
|-----|-----------|
| `POST withdraw/initiate` | Yes (`withdrawal_amount`, `upi_id`, `bank_details`, `buy_rate`) |
| `POST withdraw/verify-upi` | Yes (`upi_id`) |

**Fintech Risk:**
- Rate lock prevents sell-price manipulation
- Transaction PIN verification
- Duplicate withdrawal prevention
- Market closed → withdrawal blocked

---

### 3.17–3.19 UPI Selection, Withdrawal Confirmation & Success

| Screen | Route | Purpose |
|--------|-------|---------|
| UPI Selection | `/upi-selection` | Choose/add UPI ID for payout |
| Confirmation | `/withdrawal-confirmation` | Review before final submit |
| Success | `/withdrawal-success` | Transaction receipt display |

---

### 3.20 Auto Savings (SIP) Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/auto-savings` |
| **File** | `lib/features/sip/screens/auto_savings_screen.dart` |
| **Purpose** | Set up systematic investment plans for recurring gold/silver purchases |

**API:** `POST sip/create` — Encrypted fields: `amount`

---

### 3.21–3.26 SIP Management Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Manage Savings | `/sip-manage` | View/edit active SIP |
| SIP Cancel | `/sip-cancel` | Cancel active subscription |
| SIP Payment | `/sip-payment` | Process SIP installment |
| SIP Success | `/sip-success` | Payment confirmation |
| SIP Failure | `/sip-failure` | Payment failure handling |
| SIP Transactions | `/sip-transactions` | SIP payment history |
| SIP Details | `/sip-transaction-details` | Individual SIP transaction |
| SIP Overview | `/sip-overview` | Portfolio-level SIP summary |

---

### 3.27–3.28 Transaction History & Details

| Attribute | Detail |
|-----------|--------|
| **Routes** | `/transaction-history`, `/transaction-details` |
| **Purpose** | Complete audit trail of all buy/sell/SIP transactions |

**Features:** Filterable list, date range, transaction type filter, detailed receipt view.

---

### 3.29–3.31 Profile Module

| Screen | Route | Purpose |
|--------|-------|---------|
| Profile | `/profile` | View/edit user information |
| Account Details | `/accountdetails` | Detailed account info |
| Delete Account | `/delete-account` | GDPR/regulatory account deletion |

---

### 3.32 Settings Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/settings` |
| **Purpose** | App preferences — biometric toggle, language, notifications |

---

### 3.33 Notifications Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/notifications` |
| **File** | `lib/features/notifications/notifications_screen.dart` |
| **Purpose** | Push notification inbox with read/unread management |

**API Integrations:**

| API | Purpose |
|-----|---------|
| `POST users/notifications` | Fetch notification list |
| `POST users/notifications/read` | Mark single as read |
| `POST users/notifications/read-all` | Mark all as read |
| `POST users/notifications/delete` | Delete notification |
| `POST users/notifications/unread-count` | Badge count |

---

### 3.34 Nominee Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/nominee` |
| **Purpose** | Add/update beneficiary for gold holdings |

**API:** `POST users/nominee/update` — Encrypted

---

### 3.35–3.36 Referral Module

| Screen | Route | Purpose |
|--------|-------|---------|
| Referral | `/referral` | Share referral code, view rewards |
| Referee List | `/referee-list` | List of referred users + status |

---

### 3.37–3.39 Support Module

| Screen | Route | Purpose |
|--------|-------|---------|
| Support | `/support` | Support hub |
| Enquiry Form | `/enquiry-form` | Submit support ticket |
| Enquiry List | `/enquiry-list` | Track existing tickets |

---

### 3.40 Content Screens

| Screen | Route | Source |
|--------|-------|--------|
| Terms & Conditions | `/terms` | `termsProvider` |
| Privacy Policy | `/privacy` | `privacyPolicyProvider` |
| About Us | `/about` | `aboutUsProvider` |
| Refund Policy | `/refund-policy` | `refundPolicyProvider` |
| FAQ | `/faq` | Dedicated `FaqScreen` |
| Contact Us | `/contact` | Dedicated `ContactUsScreen` |

---

### 3.41 Maintenance Screen

| Attribute | Detail |
|-----------|--------|
| **Route** | `/maintenance` |
| **Purpose** | Display server downtime message with auto-resume route |

---

### 3.42 Main Screen (Bottom Navigation Shell)

| Attribute | Detail |
|-----------|--------|
| **Route** | `/main` |
| **Purpose** | Bottom tab container — Home, Invest, Market, Profile |

---

## 4. WebSocket Integration

| Aspect | Detail |
|--------|--------|
| **Endpoint** | `ws://bullion_v4.logimaxindia.com/ratesocket/socket.io/` |
| **Protocol** | Socket.IO |
| **Events** | `market_rates` (gold/silver buy/sell prices) |
| **Market Status** | Message type `5` with open/close flag |
| **Rate Format** | `3\|goldBuy\|goldSell\|silverBuy\|silverSell\|...` |
| **Reconnection** | Automatic with exponential backoff |
| **Lifecycle** | Disconnects on app background, reconnects on resume |
| **Security** | No sensitive data transmitted; payload validated |

---

## 5. Compliance Matrix

| Standard | Implementation |
|----------|---------------|
| **OWASP MASVS L1** | Secure storage, certificate pinning, input validation |
| **OWASP MASVS L2** | Root detection, anti-tampering, screenshot prevention |
| **PCI DSS** | Delegated payment flow — card data never touches app |
| **RBI KYC** | PAN/Aadhaar verification before investment |
| **PMLA** | KYC enforcement, transaction monitoring |
| **GDPR/IT Act** | Account deletion, data minimization |
| **API Security** | RSA-OAEP-SHA256 field-level encryption |
| **Session Security** | JWT with silent refresh, 409 force-logout |
| **Runtime Protection** | Root/jailbreak detection, FLAG_SECURE |

---

> **Document generated by Antigravity AI** | Last updated: 2026-05-20
