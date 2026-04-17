# StartGold App API Specification

This document summarizes the complete set of API endpoints required for the StartGold mobile application, organized by feature.

---

## 🔐 GLOBAL SECURITY ARCHITECTURE

1.  **Transport Encryption:** All communication is strictly via **HTTPS (TLS 1.2+)**. 
2.  **Field-Level Encryption (AES-256-CBC):**
    *   Sensitive fields (e.g., `password`, `otp`, `pin`, `aadhaar`, `pan`, `upi_id`, `bank_details`) are encrypted client-side using **AES-256** before being sent in the JSON payload.
    *   This ensures data remains unreadable even if the proxy is compromised.
3.  **Central API Interceptor:**
    *   **Auto-Authentication:** Injects `Authorization: Bearer <token>` into all requests.
    *   **Auto-Encryption:** Detects sensitive endpoints and encrypts payloads on-the-fly.
    *   **Auto-Decryption:** Decrypts server responses before they reach the UI logic.
4.  **Secure Logger (Anti-Leakage):**
    *   All terminal/console logs are sanitized.
    *   Sensitive data is automatically replaced with `[REDACTED]` to prevent developers/testers from accidentally seeing private user info.
5.  **Offline Handling:** 
    *   API calls are blocked if no internet is detected to prevent state corruption.
    *   Standardized errors: `Network connection lost` or `Server unavailable`.
6.  **Socket Security:**
    *   Endpoint: `ws://bullion_v4.logimaxindia.com/ocket/socket.io/`.
    *   **Auto-Reconnect:** Enabled for continuous market data flow.
    *   **Restricted Scope:** Socket is used EXCLUSIVELY for market rates; NO sensitive data is sent via WS.
7.  **Device Integrity:** 
    *   Pass `device_id` on login and sensitive actions.
    *   Environment checks (Root/Jailbreak detection) prevent the app from running on insecure hardware.
8.  **RSA Key Exchange (`crypto/public-key`):**
    *   On first launch (or when cache is empty), the app calls `GET crypto/public-key` to retrieve the server's **RSA-OAEP-SHA256** public key.
    *   The key is persisted in `FlutterSecureStorage` and reused for the session.
    *   If the endpoint is unreachable, the app transparently falls back to **AES-256-CBC** so the user experience is never broken.
    *   The private key is **never exposed** to the client; sensitive fields are encrypted one-way with RSA before transmission.

---

## 0. 🔑 Encryption Key Exchange

### 0.1 Fetch Server RSA Public Key
*   **Endpoint:** `GET crypto/public-key`
*   **Authorization:** None (public endpoint – called before login)
*   **Purpose:** Retrieves the server's RSA-OAEP-SHA256 public key used to encrypt sensitive fields client-side before transmission.
*   **Trigger:** Called automatically by `ApiSecurityInterceptor` on app startup. Result is cached in `FlutterSecureStorage`.
*   **Response (Success):**
    ```json
    {
      "success": true,
      "data": {
        "algorithm": "RSA-OAEP-SHA256",
        "public_key": "\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
      }
    }
    ```
*   **Failure Handling:**
    *   If the endpoint is unavailable (network error, server down, timeout) the app **silently falls back** to AES-256-CBC encryption.
    *   The error is logged via `SecureLogger` but the user is never shown an error for this background call.
    *   On the next app launch the fetch is retried automatically.

---

## 0.2 🌐 App Runtime Control

### 0.2.1 Fetch App Control Data
*   **Endpoint:** `POST app/control`
*   **Authorization:** None (public endpoint — called before login and periodically while app is open)
*   **Purpose:** Central runtime control gate. Returns current version info (with platform-specific popups) and any live global alerts.
*   **Polling:** App polls this endpoint every **5 minutes** while active to pick up live alert changes without requiring a restart.
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "version": {
          "force_update": false,
          "android": {
            "latest_version": "2.1.0",
            "min_version": "1.5.0",
            "store_url": "https://play.google.com/store/apps/details?id=com.startgold",
            "title": "New Update Available",
            "message": "We've added exciting new features. Update now for the best experience.",
            "button_text": "Update Now"
          },
          "ios": {
            "latest_version": "2.0.0",
            "min_version": "1.3.0",
            "store_url": "https://apps.apple.com/app/startgold/id123456",
            "title": "Update Available",
            "message": "A new version of StartGold is available on the App Store.",
            "button_text": "Go to App Store"
          }
        },
        "alert": {
          "is_active": true,
          "type": "warning",
          "title": "Scheduled Maintenance",
          "message": "Our servers will be down for maintenance on Apr 2, 2:00–4:00 AM IST.",
          "action_url": null,
          "action_label": null
        },
        "maintenance": {
          "is_enabled": false,
          "title": "Under Maintenance",
          "subtitle": "We're upgrading our systems for a better experience. Please check back soon.",
          "expected_resume": "We'll be back by 4:00 AM IST"
        }
      }
    }
    ```

#### Version Update Logic (Client-Side)
| Condition | Behaviour |
|---|---|
| `current < android.min_version` (or `ios.min_version`) | **Force update** — dialog shown, app unusable until updated |
| `current < android.latest_version` (or `ios.latest_version`) | **Optional update** — dialog with "Later" skip option |
| `current >= platform.latest_version` | No popup shown |

#### Alert `type` Values
| Value | Color | Dismissible |
|---|---|---|
| `info` | Blue | ✅ Yes |
| `warning` | Amber | ✅ Yes |
| `maintenance` | Indigo | ❌ No |

*   **Failure Handling:** If this endpoint is unavailable, the app continues normally with no update/alert/maintenance popup.

#### Maintenance Mode Behaviour
| `is_enabled` | Client Behaviour |
|---|---|
| `true` at launch | `initialRoute` → `/maintenance` (blocks all normal routing) |
| `true` while in-app | `AppControlWrapper` redirects to `/maintenance` on next poll |
| `false` (lifted) | `MaintenanceScreen` auto-navigates to the original `resumeRoute` |

*   **Polling during maintenance:** Every **2 minutes** (faster than normal 5-min alert poll)
*   **Back press on maintenance screen:** Exits app (Android) / no-op (iOS)
*   **No AppBar back button** on maintenance screen

---

## 1. Onboarding & Shared Data

### 1.1 Fetch Onboarding Carousel
*   **Page Name:** `OnboardingScreen`
*   **Endpoint:** `POST users/content/onboarding`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "slides": [
          { "id": 1, "image": "https://cdn.gold.com/slides/1.png", "title": "Buy 24K Gold", "desc": "Start with just ₹10." }
        ]
      }
    }
    ```

### 1.2 Country & Prefix Selection
*   **Page Name:** `LoginScreen`
*   **Endpoint:** `POST users/shared/country-codes`
*   **Response:** Returns ISO codes, phone prefixes, and flag icons.

### 1.3 Fetch Commodities
*   **Endpoint:** `POST users/shared/commodities`
*   **Response:**
    ```json
    {
      "success": true,
      "data": [
        {
          "id_metal": "1",
          "web_soc_id": 91,
          "name": "Gold 24KT"
        },
        {
          "id_metal": 2,
          "web_soc_id": 98,
          "name": "Silver 999"
        }
      ]
    }
    ```

### 1.4 Fetch Amount Denominations
*   **Endpoint:** `POST users/shared/amount-denominations`
*   **Request Body:**
    ```json
    {
      "id_metal": "1"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": [
        {
          "value": 10,
          "is_popular": 0
        },
        {
          "value": 50,
          "is_popular": 0
        },
        {
          "value": 100,
          "is_popular": 1
        }
      ]
    }
    ```

### 1.5 Fetch Weight Denominations
*   **Endpoint:** `POST users/shared/weight-denominations`
*   **Request Body:**
    ```json
    {
      "id_metal": "1"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": [
        {
          "value": 1,
          "is_popular": 0
        },
        {
          "value": 2,
          "is_popular": 0
        },
        {
          "value": 5,
          "is_popular": 1
        },
        {
          "value": 10,
          "is_popular": 0
        }
      ]
    }
    ```


### 1.4 Fetch All Translations (Mega)
*   **Endpoint:** `POST users/shared/all-translations`
*   **Description:** Fetches the entire translation repository for all supported languages. This is called once at app startup and stored locally to avoid repeated API calls.
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "homeTitle": {
          "en": "Home",
          "ta": "முகப்பு",
          "te": "హోమ్"
        },
        "loginTitle": {
          "en": "Secure Login",
          "ta": "பாதுகாப்பான உள்நுழைவு"
        }
      }
    }
    ```

### 1.5 Pincode Check
*   **Endpoint:** `POST users/shared/check-pincode`
*   **Description:** Validates a 6-digit pincode and retrieves corresponding State and City.
*   **Request Body:**
    ```json
    {
      "pincode": "641012"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "state": "Tamilnadu",
        "city": "Coimbatore"
      }
    }
    ```

---


## 2. Authentication Flow

### 2.1 Generate OTP (Send OTP)
*   **Page Name:** `LoginScreen`, `OtpScreen`, `MpinScreen`
*   **Reason:** To initiate or re-trigger the verification process for:
    *   **New Customer**: First-time registration.
    *   **Existing Customer**: Standard login.
    *   **Forgot PIN**: Verification before reset.
    *   **Resend**: Re-sending code during a session.
*   **Endpoint:** `POST users/auth/generate-otp`
*   **Request Body:**
    ```json
    {
      "mobile": "9876543210",
      "country_code": "+91",
      "id_country": "101",
      "type": "LOGIN / REGISTRATION / FORGOT_PIN / RESEND",
      "device_id": "uuid-123",
      "device_type": "android",
      "appVersion": "1.0.0"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "otp_reference_id": "OTP_REF_789"
      }
    }
    ```

### 2.2 Verify OTP
*   **Page Name:** `OtpScreen`
*   **Endpoint:** `POST users/auth/verify-otp`
*   **Request Body:**
    ```json
    {
      "mobile": "9876543210",
      "otp": "123456",
      "otp_reference_id": "OTP_REF_789"
    }
    ```
*   **Response (Existing Customer):**
    ```json
    {
      "success": true,
      "message": "Login successful",
      "data": {
        "is_new_user": false,
        "access_token": "JWT_ACCESS_F930AEE813F04A22B45A80360B7F97BF",
        "refresh_token": "REFRESH_8CDFE907AB3846CC90A625FAA0D031C8",
        "mpin_enabled": true,
        "user": {
          "id_customer": "C101",
          "name": "John Doe",
          "mobile": "2545534232",
          "email": "john.doe@example.com"
        }
      }
    }
    ```
*   **Response (New Customer):**
    ```json
    {
      "success": true,
      "message": "OTP verified. Proceed to registration.",
      "data": {
        "is_new_user": true,
        "temp_token": "TEMP_REG_TOKEN_507d6305",
        "mobile": "3545465786"
      }
    }
    ```
    ```json
    {
      "success": true,
      "message": "User not registered",
      "data": {
        "is_new_user": true,
        "temp_token": "TEMP_REG_TOKEN",
        "mobile": "9876543210"
      }
    }
    ```

### 2.3 User Registration (Profile Creation)
*   **Page Name:** `RegistrationScreen`
*   **Reason:** To create a new profile for a first-time users.
*   **Endpoint:** `POST users/auth/register`
*   **Request Body:**
    ```json
    {
      "mobile": "9876543210",
      "full_name": "Lord Alexander",
      "email": "alex@gold.com",
      "temp_token": "TEMP_REG_TOKEN"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Registration successful",
      "data": {
        "access_token": "JWT_TOKEN",
        "refresh_token": "REF_TOKEN",
        "user": {
          "id_customer": "C101",
          "name": "Lord Alexander"
        }
      }
    }
    ```

---

### 2.4 Refresh Access Token
*   **Trigger:** Called automatically by `ApiSecurityInterceptor` when any API returns `401 Unauthorized`.
*   **Endpoint:** `POST users/auth/token/refresh`
*   **Authorization:** None (public endpoint)
*   **Request Body:**
    ```json
    {
      "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Token refreshed successfully.",
      "data": {
        "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      }
    }
    ```
*   **On Success:** New `access` + `refresh` tokens are persisted; original failed request is retried transparently.
*   **On Failure:** `SessionManager.logout()` is called, user is redirected to login.

---



### 3.1 MPIN Lifecycle Scenarios (The 5 Core Flows)
1. **Registration Flow:** Customer creates profile, then prompted to establish PIN -> Calls **`POST /mpin/create`**
2. **App Session (Cold Start):** Returning customer unlocks application -> Calls **`POST /mpin/validate`** 
3. **Change MPIN:** Customer updates PIN from Profile settings -> Calls **`POST /mpin/change`**
4. **Biometric Enablement:** Enabling fingerprint/FaceID requires PIN confirmation -> Calls **`POST /mpin/validate`**
5. **Withdrawal / Money Transfer:** Confirming financial action requires PIN verification -> Calls **`POST /mpin/validate`** (followed by `POST /account/withdraw` passing `transaction_pin`)

### 3.2 Create Secure MPIN
*   **Page Name:** `MpinScreen` (Setup Mode)
*   **Endpoint:** `POST /mpin/create`
*   **Authorization:** `Bearer Token`
*   **Request:** `{ "mpin": "1234" }`

### 3.3 Validate MPIN (App Unlock / Biometrics / Transfers)
*   **Page Name:** `MpinScreen` (Unlock/Verify Mode)
*   **Endpoint:** `POST /mpin/validate`
*   **Authorization:** `Bearer Token`
*   **Request:** `{ "mpin": "1234" }`

### 3.4 Check MPIN Status
*   **Reason:** To check if the user has already set an MPIN (usually called on app start).
*   **Endpoint:** `POST /auth/has-mpin`
*   **Authorization:** `Bearer Token`
*   **Response:** `{ "success": true, "hasMpin": true }`

### 3.4 Forgot PIN (Recovery)
*   **Step 1:** Call `Generate OTP` (Section 2.1) with `type: "FORGOT_PIN"`.
*   **Step 2:** Call `Verify OTP` (Section 2.2).
*   **Step 3:** On success, call `POST /mpin/reset` with:
    ```json
    {
      "temp_token": "TEMP_VERIFY_TOKEN",
      "new_mpin": "5678"
    }
    ```

### 3.5 Change MPIN
*   **Reason:** Allows an already authenticated user to change their MPIN in the application profile settings.
*   **Page Name:** `ChangeMpinScreen`
*   **Endpoint:** `POST /mpin/change`
*   **Authorization:** `Bearer Token`
*   **Request Body:**
    ```json
    {
      "old_mpin": "1234",
      "new_mpin": "5678"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "MPIN changed successfully."
    }
    ```

---

## 4. Home Dashboard

### 4.1 Fetch Home Dashboard Blocks
*   **Page Name:** `HomeScreen`
*   **Endpoint:** `POST /home/dashboard`
*   **Description:** Retrieves dynamic blocks for the home screen, including rate history, investment banners, and learning content.
*   **Request Body:**
    ```json
    {
      "id_metal": "1"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "rate_history": {
          "title": "Gold on a Growth Streak",
          "start_year": "2020",
          "start_rate": 4865,
          "end_year": "2026",
          "end_rate": 16446,
          "highlight_text": "Gold value has grown Over 4X in 5 years"
        },
        "invest_sections": {
          "title": "Invest Smart, Earn Big",
          "blocks": [
            {
              "type": "micro_saving",
              "title": "Micro Savings, Mega Rewards",
              "image": "assets/images/banner1.png",
              "cta": "Swipe"
            },
            {
              "type": "safe_secure",
              "title": "Safe & Secure",
              "subtitle": "Your assets are safely stored in 100% insured digital vaults."
            }
          ]
        },
        "learning_sections": {
          "title": "Learn Something New",
          "banners": [
            {
              "id": 1,
              "image": "assets/images/learn1.png",
              "title": "How Digital Gold Works",
              "url": "https://startgold.com/learn/how-it-works"
            }
          ]
        },
        "footer_info": {
          "title": "Your savings are 100% secure with StartGOLD!",
          "subtitle": "Your hard-earned precious metal is securely stored in vaults and can be withdrawn at any time.",
          "compliance": [
            { "icon": "assets/icons/iso.png", "label": "ISO 27001 Certified" },
            { "icon": "assets/icons/bis.png", "label": "BIS 24K Hallmark" }
          ],
          "office_address": "477-482, Anna Salai, 1st Floor, Khivraj Complex-1, Chennai 600 035, Tamil Nadu, India"
        }
      }
    }
    ```

---

## 5. Market & Portfolio
*   **Page Name:** `HomeScreen` / `MarketScreen`
*   **Endpoint:** `POST /market/rates/live`
*   **Response:** `{ "buy_price": 6250.5, "sell_price": 6120.25, "currency": "INR", "timestamp": "2024-03-02..." }`

### 4.2 Portfolio Summary
*   **Endpoint:** `POST /portfolio/summary`
*   **Request:**
    ```json
    {
      "id_metal": "1"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Portfolio summary retrieved",
      "data": {
        "total_holdings_grams": 0.5,
        "current_value_inr": 3125.25,
        "total_invested": 2900,
        "growth_percentage": 7.7
      }
    }
    ```

---

## 5. Other Modules

### 5.1 Profile & KYC
*   `POST /profile/customer_details`: Fetches user profile data (name, email, address, etc.).
*   `POST /profile/update`: Edits user profile (Page: `ProfileScreen`).
*   `POST /customer/update-profile-photo`: Uploads/updates the customer's profile picture.
*   `POST /kyc/status`: Fetches current verification state.
*   `POST /kyc/initiate`: Triggers the verification process (Page: `KycScreen`).

### 5.2 Transactions & Financials
*   `POST /statements/list`: Fetches all logs/reports.
*   `POST /statements/download/{id}`: Downloads specific PDF report (Page: `StatementsScreen`).

### 5.3 Support & Contact
*   `POST /support/ticket`: Submits a query or chat request (Page: `SupportScreen`).

### 5.4 Referrals

#### 5.4.1 Fetch Referral Data
*   **Page Name:** `ReferralScreen`
*   **Endpoint:** `POST /users/auth/referral/details`
*   **Description:** Returns user's referral code, sharing link, and earning statistics. Called every time the Refer & Earn screen is opened.
*   **Authorization:** `Bearer Token`
*   **Request Body:**
    ```json
    {}
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Referral data fetched successfully",
      "data": {
        "referral_code": "KSU8Y314",
        "total_referrals": 1,
        "total_earned": "100.00",
        "reward_amount": "100.00",
        "share_link": "https://startgold.com/refer/KSU8Y314",
        "title": "Invite a friend and earn ₹100 worth of Gold.",
        "bullet_points": [
          { "content": "Share the link with friends, family, and relatives." },
          { "content": "Both you and your friend get ₹100 worth of gold." },
          { "content": "Reward is credited automatically after your friend's first purchase." }
        ]
      }
    }
    ```
*   **Fields:**
    | Field | Type | Description |
    |-------|------|-------------|
    | `referral_code` | String | Unique code for the customer to share |
    | `total_referrals` | Integer | Number of friends who joined using this code |
    | `total_earned` | String | Total reward amount earned via referrals |
    | `reward_amount` | String | Per-referral reward value (e.g. `"100.00"`) |
    | `share_link` | String | Deep link URL for sharing |
    | `title` | String | **Dynamic** hero heading shown in the Refer & Earn screen header |
    | `bullet_points` | Array | **Dynamic** list of `{ content: String }` objects rendered as bullet points |

> [!IMPORTANT]
> `title` and `bullet_points` are required for the UI to render dynamically.
> If omitted by the server, the app falls back to composed text using `reward_amount`.


#### 5.4.2 Claim Referral Reward
*   **Endpoint:** `POST /referral/claim`
*   **Description:** Claims pending referral rewards.
*   **Authorization:** `Bearer Token`
*   **Page:** `ReferralScreen`

#### 5.4.3 Fetch Referral Reward Balance
*   **Page Name:** `WithdrawalScreen`
*   **Endpoint:** `POST referrals/reward-balance`
*   **Description:** Returns the referral reward balance available for the selected metal. Called on the Withdrawal screen whenever it loads or the user switches between Gold / Silver tabs.
*   **Authorization:** `Bearer Token`
*   **Provider:** `rewardBalanceProvider` (auto-dispose, rebuilds on commodity change)
*   **Request Body:**
    ```json
    {
      "id_metal": "1"
    }
    ```
    > `id_metal` is resolved dynamically via `selectedMetalIdProvider` (`"1"` = Gold, `"2"` = Silver).

*   **Response:**
    ```json
    {
      "success": true,
      "message": "Reward balance fetched successfully",
      "data": {
        "reward_balance": 250.00
      }
    }
    ```
*   **Fields:**

    | Field | Type | Description |
    |-------|------|-------------|
    | `reward_balance` | Double | Available referral reward balance for the selected metal |

*   **UI Behaviour:**
    - If `reward_balance > 0` → a green **"Referral Reward Balance — ₹XXX.XX — Available"** chip is shown inside the withdrawal input card, below the current holding row.
    - If `reward_balance == 0` or API fails → chip is hidden silently (no error shown).

### 5.5 Session Termination
*   `POST /auth/logout`: Invalidate session on server-side.

---

---

## 6. Instant Saving (Buy Flow)

### 6.1 Fetch Saving Configuration
*   **Endpoint:** `POST /savings/config`
*   **Description:** Retrieves global limits and timer lock durations.
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "min_amount": 10.0,
        "max_amount": 200000.0,
        "sell_rate_lock_seconds": 10,
        "buy_rate_lock_seconds": 10,
        "gst": "3",
        "type": "inclusive"
      }
    }
    ```

### 6.2 Check Saving Eligibility
*   **Page Name:** `InstantSavingScreen`
*   **Reason:** Check whether customer can proceed directly to payment or must complete KYC before purchase.
*   **Endpoint:** `POST /savings/check-eligibility`
*   **Request Body:**
    ```json
    {
      "id_customer": "C101",
      "id_metal": "1",
      "mobile": "9876543210",
      "amount_inr": 100,
      "rate_per_gram": 15248.95,
      "device_id": "device-id-placeholder",
      "coupon_code": null,
      "request_from": "instant"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Eligibility checked successfully",
      "data": {
        "next_step": "KYC_REQUIRED / PAYMENT / UPI_LIST"
      }
    }
    ```

### 6.3 Initiate Instant Purchase
*   **Page Name:** `PaymentMethodsScreen`
*   **Reason:** Starting a spot purchase for Gold/Silver. This call happens AFTER eligibility is checked (and KYC if needed) and a payment method is selected.
*   **Endpoint:** `POST /savings/initiate`
*   **Request Body:**
    ```json
    {
      "id_customer": "1",
      "id_metal": "1",
      "buy_type": "AMOUNT",
      "mobile": "1234567890",
      "amount_inr": 100.0,
      "rate_per_gram": 6250.5,
      "coupon_code": "SECONDJAR",
      "device_id": "uuid-123",
      "request_from": "instant"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "transaction_id": "TXN_123456",
        "payment_token": "PG_TOKEN_XYZ",
        "order_amount": 100.0,
        "grams_locked": 0.016,
        "expiry_seconds": 600
      }
    }
    ```

### 6.4 Validate Coupon
*   **Endpoint:** `POST /savings/validate-coupon`
*   **Request Body:** `{ "code": "SECONDJAR", "amount": 100.0 }`
*   **Response:** `{ "valid": true, "discount_amount": 5.0, "message": "Coupon applied!" }`

### 6.5 Confirm Payment
*   **Endpoint:** `POST /savings/confirm-payment`
*   **Reason:** Verifying the payment status with the backend after the mobile SDK (Cashfree) returns a callback.
*   **Request Body:**
    ```json
    {
      "order_id": "ORD2T20260325122541"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Order ORD2T20260325122541 has been successfully paid.",
      "data": {
        "status": "SUCCESS",
        "transaction_id": "CF_123456",
        "credited_weight": 0.0070
      }
    }
    ```

### 6.6 Cancel Order
*   **Endpoint:** `POST /savings/cancel_order`
*   **Reason:** Explicitly cancelling an order when the user backs out of the payment confirmation or bottom sheet.
*   **Request Body:**
    ```json
    {
      "order_id": "ORD2T20260325122541"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "order has been canceled"
    }
    ```

---

## 7. Dynamic KYC Flow

### 7.1 Fetch KYC Document Types
*   **Page Name:** `KycScreen`
*   **Endpoint:** `POST /kyc/document-types`
*   **Description:** Retrieves dynamic form configuration for different documents based on the request source.
*   **Request Body:**
    ```json
    {
      "id_customer": "1",
      "request_from": "instant / withdrawal / profile_update / scheme_join"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "KYC document types retrieved successfully",
      "data": {
        "documents": [
          {
            "id_document": "2",
            "document_name": "PAN",
            "code": "PAN",
            "mandatory": true,
            "fields": [
              {
                "name": "pan",
                "label": "PAN Number",
                "type": "text",
                "regex": "^[A-Z]{5}[0-9]{4}[A-Z]{1}$"
              }
            ]
          }
        ]
      }
    }
    ```

### 7.2 Upload KYC Data
*   **Endpoint:** `POST /kyc/upload`
*   **Content-Type:** `application/json`
*   **Description:** Uploads KYC document details.
*   **Request Body:**
    ```json
    {
      "id_document": "1",
      "request_from": "instant / withdraw",
      "fields": {
        "pan": "ABCPV1234D",
        "name": "John Doe"
      }
    }
    ```
*   **Security:** Field values (like PAN numbers) must be encrypted before sending (AES-256).
*   **Response:**
    ```json
    {
      "success": true,
      "message": "KYC submitted successfully",
      "data": {
         "status": "PENDING / APPROVED / REJECTED"
      }
    }
    ```

---

## 8. Payment Gateway Flow

### 8.1 Fetch Payment Methods
*   **Endpoint:** `POST /payments/methods`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "methods": [
          { "id": "1", "name": "cashfree", "icon": "cashfree icon","description":"For testing Credit Card Debit Card Net Banking."
           },
        
        ]
      }
    }
    ```

### 8.2 Create Payment Order
*   **Endpoint:** `POST /payments/create-order`
*   **Request Body:**
    ```json
    {
      "amount": 100.0,
      "method_id": "upi",
      "transaction_id": "TXN_123456"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "payment_url": "https://gateway.com/pay/abc",
        "order_id": "ORDER_789"
      }
    }
    ```

### 8.3 Verify Payment Status
*   **Endpoint:** `POST /payments/status`
*   **Request Body:** `{ "order_id": "ORDER_789" }`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "status": "SUCCESS / FAILED / PENDING",
        "new_balance": 0.05
      }
    }
    ```

---

### 9.1 Check Redemption Eligibility
*   **Page Name:** `WithdrawalScreen`
*   **Endpoint:** `POST /savings/check-eligibility`
*   **Payload:**
    ```json
    {
      "id_customer": "C101",
      "id_metal": "1",
      "mobile": "9876543210",
      "amount_inr": 100,
      "request_from": "withdraw"
    }
    ```
*   **Response:**
    ```json
    { "success": true, "data": { "next_step": "KYC_REQUIRED / UPI_LIST" } }
    ```

---

## 10. Informational Content

### 10.1 Terms and Conditions
*   **Endpoint:** `POST users/content/terms`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "title": "Terms and Conditions",
        "content": "Full terms and conditions text..."
      }
    }
    ```

### 10.2 Privacy Policy
*   **Endpoint:** `POST users/content/privacy`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "title": "Privacy Policy",
        "content": "Full privacy policy text..."
      }
    }
    ```

### 10.3 Frequently Asked Questions (FAQ)
*   **Endpoint:** `POST users/content/faqs`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "faqs": [
          { "question": "What is StartGold?", "answer": "StartGold is a digital gold savings platform." }
        ]
      }
    }
    ```

### 10.4 About Us
*   **Endpoint:** `POST users/content/about-us`
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "title": "About Us",
        "content": "Company history and vision..."
      }
    }
    ```

### 10.5 Contact Us
*   **Endpoint:** `POST users/content/contact-us`
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Contact us fetched successfully",
      "data": {
        "email": "support@startgold.com",
        "phone": "+91-9876453210",
        "address": "477-482, Anna Salai, 1st Floor, Khivraj Complex-1, Chennai 600 035, Tamil Nadu, India",
        "working_hours": "10 AM - 7 PM",
        "facebook": "https://www.facebook.com/StartGoldIndia",
        "twitter": "https://x.com/Startgoldapp",
        "instagram": "https://www.instagram.com/start_goldapp/",
        "website": "https://startgold.com/"
      }
    }
    ```
*   **Fields:**

    | Field | Type | Description |
    |-------|------|-------------|
    | `email` | String | Support email address |
    | `phone` | String | Support phone number |
    | `address` | String | Office / registered address |
    | `working_hours` | String | Business hours display string |
    | `facebook` | String? | Facebook page URL *(optional — icon hidden if absent)* |
    | `twitter` | String? | X (Twitter) profile URL *(optional — icon hidden if absent)* |
    | `instagram` | String? | Instagram profile URL *(optional — icon hidden if absent)* |
    | `website` | String? | Official website URL *(optional — icon hidden if absent)* |

*   **Note:** All social/link fields are **optional**. The app renders a social icon tile **only** when the field is present and non-empty in the API response. If the field is missing or empty, the icon is **not shown** — no hardcoded fallback URL is used for social/website icons.

---

## 11. Support Enquiries

### 11.1 Submit Enquiry
*   **Endpoint:** `POST users/support/submit`
*   **Payload:**
    ```json
    {
      "id_customer": "123",
      "mobile": "9876543210",
      "subject": "Payment Issue",
      "message": "My payment was deducted but not reflect in portfolio.",
      "category": "PAYMENT / TECHNICAL / GENERAL"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Enquiry submitted successfully. Ticket ID: #TK12345",
      "data": {
        "enquiry_id": "TK12345",
        "status": "OPEN",
        "created_at": "2024-03-18 11:00 AM"
      }
    }
    ```

### 11.2 Enquiry Listing
*   **Endpoint:** `POST users/support/list`
*   **Payload:**
    ```json
    {
      "id_customer": "123",
      "mobile": "9876543210"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "enquiries": [
          {
            "enquiry_id": "TK12345",
            "subject": "Payment Issue",
            "status": "RESOLVED",
            "created_at": "2024-03-15",
            "last_update": "2024-03-16"
          },
          {
            "enquiry_id": "TK12346",
            "subject": "Gold Rate Query",
            "status": "OPEN",
            "created_at": "2024-03-18",
            "last_update": "2024-03-18"
          }
        ]
      }
    }
    ```
---

## 12. 🚀 PRODUCTION READINESS CHECKLIST

Before deploying the application to the Production Environment (Play Store / App Store), the following changes **MUST** be implemented in `lib/core/config/app_config.dart` and the server infrastructure:

### 12.1 Backend Environment
- **Base URL:** Change from `.../test/api/mock_api/` to the production endpoint (e.g., `https://mxhedge.logimaxindia.com/api/v1/`).
- **Trailing Slashes:** Ensure all production URLs match the backend routing rules (consistent trailing slashes).

### 12.2 SSL & Security (Level 1: Transport)
- **HTTPS Enforcement:** Verify that NO `http://` URLs remain in the app.
- **SSL Pinning:** Implement Certificate Pinning using the SHA-256 fingerprint in `AppConfig.allowedCertFingerprints`.

### 12.3 Data Protection (Level 2: Information)
- **Field-Level Encryption:** Activate AES-256-CBC for all fields in `sensitiveFields` (Aadhaar, PAN, UPI IDs, Bank details).
- **Secure Storage:** Ensure all tokens and keys are ONLY stored in `FlutterSecureStorage` using Hardware-backed Enclaves (automatic on iOS/Android).
- **Secure Logger:** Ensure `SecureLogger` is scrubbing logs in the Release build.

### 12.4 Device Protection (Level 3: Physical)
- **Root/Jailbreak Detection:** Mandatory check at app launch; block sensitive transactions if detected.
- **Screenshot Protection:** Enable `ScreenProtector.preventScreenshotOn()` to block screenshots and screen recordings app-wide.
- **App Switcher Masking:** Use lifecycle events to blur or black out the app preview in the Task Manager (Recent Apps).
- **Biometric Unlock:** (Future Update) Integrate `local_auth` for FaceID/Fingerprint unlock on app resume.

### 12.5 API Performance & Availability
- **Connection Timeouts:** Change `connectTimeout` from 60s to 30s for better mobile reliability.
- **ProGuard/R8:** Add rules to `android/app/proguard-rules.pro` to prevent reverse-engineering of encryption logic.
- **App Integrity:** Verify Android 'Play Integrity API' and iOS 'App Attest' settings on the store consoles.

### 12.5 Socket.io
- **Production Event Names:** Confirm that the socket events (`market_rates`, `gold_rate`) match the production bullion server's definitions.
- **Auto-Reconnect:** Verify heartbeat intervals to maintain stable connections on mobile networks (3G/4G/5G).

### 12.6 Logging & Analytics
- **SecureLogger:** Double-check that `SecureLogger` is suppressing `[REDACTED]` fields in Release mode.
- **Analytics:** Enable production-level analytics (Firebase/AppCenter) to monitor transaction success rates and app stability.

---

## 13. ⚙️ AUTOMATION: SYNC RELEASE INFO

To avoid manually editing 10+ platform-specific files, use the integrated sync script.

### 13.1 Global Configuration
Edit the **`release_config.json`** file at the root of the project to change the app name or bundle identifier globally:
```json
{
    "app_name": "Start Gold",
    "bundle_id": "com.startgold.app",
    "version": "0.0.1",
    "build_number": 1
}
```

### 13.2 Running the Sync
Run the following command from the project root to apply the changes to Android Manifest, Gradle, Info.plist, and Kotlin sources:
```powershell
python scripts/update_release_info.py
```

### 13.3 What the script updates:
1.  **Android Label**: `AndroidManifest.xml` (the name on the home screen).
2.  **Android ID**: `build.gradle.kts` (`applicationId` & `namespace`).
3.  **Kotlin Package**: Moves `MainActivity.kt` and updates the `package` declaration.
4.  **iOS Label**: `Info.plist` (`CFBundleDisplayName`).
5.  **iOS Bundle ID**: `project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`).

---

## 14. 💸 WITHDRAWAL APIs

### 14.1 Fetch Saved Accounts
Lists all saved UPI handles and bank accounts. First item is auto-selected in UI when only one exists.

- **Endpoint:** `POST profile/accountdetails`
- **Request:**
```json
{
  "id_customer": "1234",
  "mobile": "9876543210"
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Account details fetched successfully",
  "data": {
    "accounts": [
      { "id_payout": "1", "upi_id": "user@okaxis", "upi_handle": "user@okaxis" },
      { "id_payout": "2", "bank_name": "SBI", "holder_name": "John Doe", "account_no": "012345678901", "ifsc_code": "SBIN0001234" }
    ]
  }
}
```

---

### 14.2 Verify & Add UPI Handle
- **Endpoint:** `POST account/verify-upi`
- **Encryption:** `upi_id` → AES-256
- **Request:**
```json
{ "id_customer": "1234", "mobile": "9876543210", "upi_id": "<encrypted>" }
```
- **Response (success):**
```json
{ "success": true, "message": "UPI ID verified and saved successfully", "data": { "id_payout": "3", "upi_id": "user@okaxis", "status": "verified" } }
```
- **Response (failure):**
```json
{ "success": false, "message": "Invalid UPI ID. Please check and try again." }
```

---

### 14.3 Verify & Add Bank Account
- **Endpoint:** `POST account/verify-bank`
- **Encryption:** `account_no`, `ifsc_code` → AES-256
- **Request:**
```json
{ "id_customer": "1234", "mobile": "9876543210", "account_holder": "John Doe", "account_no": "<encrypted>", "ifsc_code": "<encrypted>" }
```
- **Response (success):**
```json
{ "success": true, "message": "Bank account verified and saved", "data": { "id_payout": "4", "bank_name": "SBI", "holder_name": "John Doe", "account_no": "XXXX8901", "ifsc_code": "SBIN0001234", "status": "verified" } }
```
- **Response (failure):**
```json
{ "success": false, "message": "Bank account verification failed. Please check details." }
```

---

### 14.4 Submit Withdrawal
- **Endpoint:** `POST withdraw`
- **Encryption:** `withdrawal_amount`, `upi_id`, `transaction_pin` → AES-256
- **Request:**
```json
{ "id_customer": "1234", "mobile": "9876543210", "withdrawal_amount": "<encrypted>", "upi_id": "<encrypted>", "transaction_pin": "<encrypted>" }
```
- **Response:**
```
{ "success": true, "message": "Withdrawal request submitted", "data": { "transaction_id": "TXN20240324001", "amount": 5000, "status": "PROCESSING", "estimated_time": "1-2 business days" } }
```

---

## 15. Transaction History & Details

### 15.1 Fetch Transaction History
- **Endpoint:** `POST transactions/history`
- **Request Body:**
```json
{
  "id_customer": "C101",
  "metal_type": "1", // General filter
  "page": 1,
  "limit": 20
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Transactions retrieved successfully",
  "data": {
    "grouped_transactions": {
      "11 Mar 2026": [
        {
          "transaction_id": "TXN_11MAR_01",
          "title": "Instant Saving",
          "type": "purchase",
          "status": "Success",
          "amount": 10.00,
          "weight_grams": 0.0005,
          "metal_name": "Gold",
          "display_date": "11 Mar '26, 01:03pm"
        },
        {
          "transaction_id": "TXN_11MAR_02",
          "title": "Withdrawal",
          "type": "withdrawal",
          "status": "Success",
          "amount": 9.64,
          "weight_grams": 0.0006,
          "metal_name": "Gold",
          "display_date": "11 Mar '26, 11:07am"
        }
      ],
      "05 Feb 2025": [
        {
          "transaction_id": "TXN_05FEB_01",
          "title": "Instant Saving",
          "type": "purchase",
          "status": "Success",
          "amount": 10.00,
          "weight_grams": 0.0011,
          "metal_name": "Gold",
          "display_date": "05 Feb '25, 11:03am"
        }
      ]
    }
  }
}
```

---

### 15.2 Fetch Transaction Details
- **Endpoint:** `POST transactions/details`
- **Request Body:**
```json
{
  "id_customer": "C101",
  "transaction_id": "TXN_11MAR_01"
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Transaction details retrieved successfully",
  "data": {
    "transaction_id": "TXN_11MAR_01",
    "title": "Instant Saving",
    "subtitle": "Gold purchased",
    "amount": 10.00,
    "weight_grams": 0.0005,
    "metal_name": "Gold",
    "timeline": [
      {
        "step_name": "Payment",
        "status": "Success",
        "time": "11 Mar '26, 01:03 PM"
      },
      {
        "step_name": "Gold order",
        "status": "Success",
        "time": "11 Mar '26, 01:03 PM"
      },
      {
        "step_name": "Gold purchase",
        "status": "Success",
        "time": "11 Mar '26, 01:03 PM"
      }
    ],
    "footer_message": "Gold has been added to your Jar locker.",
    "price_breakdown": {
      "gold_quantity": "0.0005 g",
      "gold_rate": "₹16,577.19/g",
      "gold_value": "₹9.76",
      "gst": "₹0.24",
      "total_amount": "₹10"
    },
    "technical_details": {
      "transaction_id_display": "........4e9b64a",
      "gold_transaction_id": "........3DZ8B45",
      "placed_on": "11 Mar '26, 01:03 PM",
      "paid_via": "UPI"
    }
  }
}
```

---

## Support / Enquiry

### Create Support Ticket
*   **Endpoint:** `POST support/create-ticket`
*   **Authorization:** Bearer token required
*   **Request Payload:**
    ```json
    {
      "type": 1,
      "subject": "Payment query",
      "content": "I have a question about my last payment."
    }
    ```

#### `type` Values
| Value | Label |
|---|---|
| `1` | General |
| `2` | Payment |
| `3` | Technical |
| `4` | Account |

*   **Response:**
    ```json
    {
      "success": true,
      "message": "Support request submitted successfully.",
      "data": {
        "id": 3,
        "on": "01/04/2026 05:59 am",
        "type": "Enquiry",
        "subject": "Payment query",
        "content": "I have a question about my last payment.",
        "status": "pending"
      }
    }
    ```

#### Status Values
| Value | Meaning |
|---|---|
| `pending` | Ticket received, awaiting review |
| `open` | Under investigation |
| `resolved` | Ticket closed |

---

### List My Tickets
*   **Endpoint:** `POST support/list`
*   **Authorization:** Bearer token required
*   **Payload:** `{}` (empty body — user identified from token)
*   **Response:**
    ```json
    {
      "success": true,
      "data": [
        {
          "id": 3,
          "on": "01/04/2026 05:59 am",
          "type": "Enquiry",
          "subject": "Payment query",
          "content": "I have a question about my last payment.",
          "status": "pending"
        }
      ]
    }
    ```

> **Note:** The client tries multiple response shapes:
> `data` as array → `data.tickets` → `data.enquiries` → `data.data` → `data.list`
