# startGOLD — Complete Page Architecture & API Reference

> **Base URL:** `http://startgoldapi.logimaxindia.com/`  
> **Auth:** Bearer Token (JWT) in `Authorization` header  
> **Encryption:** RSA-OAEP-SHA256 on sensitive fields  
> **State:** Riverpod (StateNotifier + FutureProvider)

---

## 1. Splash Screen

**File:** `lib/features/splash/splash_screen.dart`  
**Route:** `/splash` (initial route)  
**Provider:** None (standalone)

### Flow
```
App Launch
  → Root Detection (blocks if compromised)
  → Fetch App Control API
  → Check: maintenance_mode?
      YES → /maintenance
  → Check: force_update?
      YES → Show update dialog (blocks app)
  → Check: onboarding_seen?
      NO  → /onboarding
  → Check: has_token?
      NO  → /login
      YES → Check: mpin_enabled?
          YES → /mpin
          NO  → /main (home)
```

### API: `POST app/control`
**Auth:** None (pre-login)

**Request:**
```json
{ "platform": "android" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "maintenance": { "is_active": false, "message": "" },
    "version": {
      "latest": "1.0.5",
      "minimum": "1.0.0",
      "force_update": false
    },
    "alert": { "is_active": false, "title": "", "message": "" }
  }
}
```

---

## 2. Onboarding Screen

**File:** `lib/features/onboarding/onboarding_screen.dart`  
**Route:** `/onboarding`

### Flow
```
Show onboarding slides (from API)
  → User taps "Get Started"
  → Save onboarding_seen = true (SharedPreferences)
  → Navigate → /login
```

### API: `POST users/content/onboarding`
**Auth:** None

**Response:**
```json
{
  "success": true,
  "data": [
    { "title": "...", "description": "...", "image_url": "..." }
  ]
}
```

---

## 3. Login Screen

**File:** `lib/features/auth/login/login_screen.dart`  
**Route:** `/login`  
**Provider:** `authProvider` → `AuthNotifier`

### Flow
```
User enters phone number + selects country code
  → Tap "Continue"
  → Call generate-otp API
  → Success → Navigate → /otp (pass mobile, countryCode, otpReferenceId)
  → Error → Show toast with error message
```

### API: `POST users/auth/generate-otp`
**Auth:** None  
**Encrypted fields:** `mobile`

**Request:**
```json
{
  "mobile": "9876543210",
  "country_code": "+91",
  "id_country": "101",
  "type": "LOGIN",
  "device_id": "abc123",
  "device_type": "android",
  "appVersion": "1.0.0"
}
```

**Response (existing user):**
```json
{
  "success": true,
  "data": { "otp_reference_id": "ref_abc123" }
}
```

### Dependency API: `POST users/shared/country-codes`
**Response:**
```json
{
  "data": [
    { "id_country": "101", "name": "India", "iso": "IN", "code": "+91", "flag": "🇮🇳" }
  ]
}
```

---

## 4. OTP Screen

**File:** `lib/features/auth/otp/otp_screen.dart`  
**Route:** `/otp`  
**Args:** `{ mobile, countryCode, idCountry, otpReferenceId }`  
**Provider:** `authProvider`

### Flow
```
User enters 6-digit OTP
  → Auto-submit on 6th digit
  → Call verify-otp API
  → Check response:
      is_new_user == true → Navigate → /registration (pass mobile, temp_token)
      mpin_enabled == true → Navigate → /mpin
      mpin_enabled == false → Navigate → /mpin-creation
  → Resend OTP: 30s cooldown timer, calls generate-otp again
```

### API: `POST users/auth/verify-otp`
**Encrypted fields:** `otp`, `mobile`

**Request:**
```json
{
  "mobile": "9876543210",
  "otp": "123456",
  "otp_reference_id": "ref_abc123"
}
```

**Response (existing user):**
```json
{
  "success": true,
  "data": {
    "is_new_user": false,
    "mpin_enabled": true,
    "access_token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "user": {
      "id_customer": "42",
      "name": "John Doe",
      "photo_url": "https://..."
    }
  }
}
```

**Response (new user):**
```json
{
  "success": true,
  "data": {
    "is_new_user": true,
    "temp_token": "temp_xyz789"
  }
}
```

**Side effects:** Saves `access_token`, `refresh_token`, `id_customer`, `name`, `mobile` to SecureStorage.

---

## 5. Registration Screen

**File:** `lib/features/auth/registration/registration_screen.dart`  
**Route:** `/registration`  
**Args:** `{ mobile, tempToken }`  
**Provider:** `authProvider`

### Flow
```
User fills: Full Name, Email, DOB, Referral Code (optional)
  → Check Terms & Conditions checkbox
  → Tap "Confirm"
  → Call register-check API (pre-validation)
      → Failure → Show toast
      → Success → Navigate → /mpin-creation (pass all fields + tempToken)
```

### API: `POST users/auth/register-check`
**Request:**
```json
{
  "mobile": "9876543210",
  "full_name": "John Doe",
  "email": "john@example.com",
  "dob": "1990-01-15",
  "referral_code": "REF123",
  "temp_token": "temp_xyz789",
  "device_id": "abc123",
  "device_type": "android"
}
```

**Response:**
```json
{ "success": true, "message": "Validation passed" }
```

---

## 6. PIN Creation Screen

**File:** `lib/features/auth/pin/pin_creation_screen.dart`  
**Route:** `/mpin-creation`  
**Args:** `{ mobile, fullName, email, dob, referralCode, tempToken }`

### Flow
```
Step 1: Enter 4-digit MPIN (shuffled keypad)
Step 2: Confirm MPIN (re-enter)
  → If mismatch → Show error, reset
  → If match:
      → Call register API (creates account + tokens)
      → Call mpin/create API (sets the PIN)
      → Navigate → /registration-success
```

### API: `POST users/auth/register`
**Request:**
```json
{
  "mobile": "9876543210",
  "full_name": "John Doe",
  "email": "john@example.com",
  "dob": "1990-01-15",
  "referral_code": "REF123",
  "temp_token": "temp_xyz789",
  "device_id": "abc123",
  "device_type": "android"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "user": { "id_customer": "42", "name": "John Doe" }
  }
}
```

### API: `POST mpin/create`
**Encrypted fields:** `mpin`

**Request:**
```json
{ "mpin": "1234" }
```

**Response:**
```json
{ "success": true, "message": "MPIN set successfully" }
```

---

## 7. MPIN Screen

**File:** `lib/features/mpin/mpin_screen.dart`  
**Route:** `/mpin`  
**Provider:** `mpinProvider` → `MpinNotifier`

### Modes
| Mode | Trigger | On Success |
|------|---------|------------|
| `verify` | App launch (after OTP login) | → `/main` |
| `app_lock` | App resume from background | → `Navigator.pop()` (back to previous screen) |
| `withdrawal_pin` | Before withdrawal submit | → `Navigator.pop(true)` (returns result) |
| `verify_only` | Generic re-auth | → `Navigator.pop(true)` |
| `forgot` | After forgot-PIN OTP verify | → Reset MPIN, then → `/main` |

### Flow
```
Show 4-digit shuffled keypad
  → Biometric check first (if enabled, NOT for withdrawal_pin/verify_only)
      → Success → verifyMpin API → navigate
      → Failure → Fall back to keypad
  → User enters 4 digits
  → Call mpin/validate API
      → Success → Navigate based on mode
      → 401/403/409 → SESSION_EXPIRED → Clear storage → /login
      → Wrong PIN → Show error, increment attempt count
      → 5 failures → ACCOUNT LOCKED message
```

### API: `POST mpin/validate`
**Encrypted fields:** `mpin`

**Request:**
```json
{ "mpin": "1234" }
```

**Response:**
```json
{ "success": true }
```

**Error (wrong PIN):**
```json
{ "success": false, "message": "Invalid MPIN" }
```

**Error (session expired):** HTTP 401 → DioException caught → `SESSION_EXPIRED` state

### API: `POST auth/has-mpin`
**Response:**
```json
{ "hasMpin": true }
```

---

## 8. Change MPIN Screen

**File:** `lib/features/mpin/change_mpin_screen.dart`  
**Route:** `/change-mpin`

### Flow
```
Step 1: Enter current MPIN
Step 2: Enter new MPIN
Step 3: Confirm new MPIN
  → Call mpin/change API
  → Success → Toast + pop back
  → Error → Show server error message
```

### API: `POST mpin/change`
**Encrypted fields:** `old_mpin`, `new_mpin`

**Request:**
```json
{ "old_mpin": "1234", "new_mpin": "5678" }
```

**Response:**
```json
{ "success": true, "message": "MPIN changed successfully" }
```

---

## 9. Forgot PIN Flow

### Flow
```
MPIN Screen → Tap "Forgot PIN?"
  → Navigate → /login (with type=FORGOT_PIN)
  → generate-otp API (type: "FORGOT_PIN")
  → OTP Screen (verify)
  → verify-otp returns temp_token
  → Navigate → /mpin (mode: forgot, pass temp_token)
  → Enter new MPIN + confirm
  → Call mpin/reset API
  → Success → Navigate → /main
```

### API: `POST mpin/reset`
**Encrypted fields:** `new_mpin`

**Request:**
```json
{
  "temp_token": "temp_xyz789",
  "new_mpin": "5678",
  "mobile": "9876543210"
}
```

**Response:**
```json
{ "success": true, "message": "MPIN reset successfully" }
```

---

## 10. Security Layer (Non-UI)

### App Lock (Resume Re-auth)
**File:** `lib/core/security/app_lifecycle_observer.dart`

```
App goes to background (paused)
  → Cache auth state, MPIN enabled, biometric enabled (in-memory)
App resumes (resumed)
  → Check suppressAppLock flag (true during Cashfree payment)
  → Check cached: isAuthenticated && mpinEnabled
      YES → Push /mpin (mode: app_lock)
      NO  → Skip
  → Call session-check API (lightweight validation)
      → 401/409 → Force logout
```

### API: `GET users/auth/session-check`
**Response:**
```json
{ "valid": true }
```

### 409 Session Invalidation
**File:** `lib/core/security/api_interceptor.dart`

```
Any API returns HTTP 409 with code "session_invalidated"
  → Set isForceLoggedOut = true (blocks all future API calls)
  → Show non-dismissible frosted-glass dialog: "Session Ended"
  → User taps "Login Again"
  → Clear SecureStorage → Navigate → /login (clear stack)
```

### Token Refresh (401)
```
API returns HTTP 401
  → Check: isForceLoggedOut? YES → skip (already logging out)
  → Get refresh_token from SecureStorage
  → Call POST users/auth/refresh-token
  → Success → Save new tokens → Retry original request
  → Failure → SessionManager.logout() → Navigate → /login
```

### API: `POST users/auth/refresh-token`
**Request:**
```json
{ "refresh_token": "eyJhbG..." }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "new_eyJhbG...",
    "refresh_token": "new_eyJhbG..."
  }
}
```

### RSA Encryption
**File:** `lib/core/security/encryption_service.dart`

```
On app launch → Fetch server public key
  → POST crypto/public-key → Cache in SecureStorage
  → Before each API request:
      → Scan request body for sensitive fields
      → Encrypt each field value with RSA-OAEP-SHA256
      → Replace plaintext with encrypted value
```

**Sensitive fields:** `password`, `otp`, `mpin`, `old_mpin`, `new_mpin`, `mobile`, `aadhaar_number`, `pan_number`, `bank_account_number`, `ifsc_code`, `upi_id`, `amount`, `amount_inr`, `weight`, `buy_rate`, `transaction_pin`

### API: `POST crypto/public-key`
**Response:**
```json
{
  "success": true,
  "data": { "public_key": "-----BEGIN PUBLIC KEY-----\nMIIBI..." }
}
```


---

## 11. Main Screen (Tab Host)

**File:** `lib/features/main/main_screen.dart`  
**Route:** `/main`  
**Tabs:** Home | Invest | Withdraw | Profile

### Flow
```
On init:
  → rehydrateFromStorage() (load auth from SecureStorage)
  → refreshUnreadCount() (notification badge)
  → Connect WebSocket (live rates)
  → Fetch commodities API
On tab switch:
  → Home tab: refresh unread count
  → Invest tab: refresh saving config + denominations
  → Withdraw tab: refresh reward balance
```

---

## 12. Home Screen

**File:** `lib/features/home/home_screen.dart`  
**Route:** Tab 0 in MainScreen  
**Providers:** `dashboardProvider`, `portfolioProvider`, `unreadCountProvider`

### Flow
```
On load:
  → Fetch dashboard API (portfolio summary, scheme data)
  → Fetch portfolio/summary API
  → Listen to WebSocket ratesStream (live rates)
  → Fetch unread notification count
  → Show: greeting, portfolio card, live rates, invest section, learn carousel
```

### API: `POST home/dashboard`
**Request:**
```json
{ "id_metal": "1" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "portfolio": { "total_invested": "5000", "current_value": "5200", "growth": "4.0" },
    "schemes": [...],
    "learn": [...]
  }
}
```

### API: `POST portfolio/summary`
**Request:**
```json
{ "id_metal": "1" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total_invested": "5000.00",
    "current_value_inr": "5200.00",
    "total_holdings_grams": "0.6543",
    "growth_percentage": "4.0"
  }
}
```

### WebSocket: Live Market Rates
**URL:** `ws://13.202.62.253:57200` (staging) / `wss://sgbackoffice.startgold.com/ws/` (production)  
**Protocol token:** `0b286a8b...` (hardcoded, needs dynamic auth)

**Incoming data format:**
```
Rate frame:   3|commodity_id|commodity_name|buy_rate|sell_rate|change|percentage
Status frame: 5|commodity_id|commodity_name|market_status (0=closed, 1=open)
```

**Parsed into `MarketRates` model:** goldBuy, goldSell, goldChange, silverBuy, silverSell, silverChange

---

## 13. Instant Saving Screen (Buy Gold/Silver)

**File:** `lib/features/instant_saving/instant_saving_screen.dart`  
**Route:** `/instant-saving` (also Tab 1 in MainScreen)  
**Providers:** `savingConfigProvider`, `amountDenominationsProvider`, `weightDenominationsProvider`

### Flow
```
On load:
  → Fetch saving config (min/max amounts, GST rate)
  → Fetch denominations (amount chips or weight chips based on toggle)
  → Listen to WebSocket for live sell rate
Toggle: "Buy in ₹" vs "Buy in Grams"
  → ₹ mode: user enters amount, app calculates weight
  → Grams mode: user enters weight, app calculates amount
  → GST: goldValue = totalPayable / (1 + gstRate/100)
Tap denomination chip → auto-fills amount
Tap "Buy Now":
  → Call check-eligibility API
  → Response next_step:
      "PAYMENT"      → Navigate → /payment-methods
      "KYC_REQUIRED" → Navigate → /kyc-dynamic
      "UPI_LIST"     → Navigate → /upi-selection
```

### API: `POST savings/config`
**Response:**
```json
{
  "success": true,
  "data": {
    "min_amount": 100,
    "max_amount": 200000,
    "min_weight": 0.001,
    "max_weight": 50,
    "gst_rate": 3.0,
    "commodities": [
      { "id_metal": "1", "name": "Gold 24K" },
      { "id_metal": "3", "name": "Silver" }
    ]
  }
}
```

### API: `POST savings/check-eligibility`
**Encrypted fields:** `amount_inr`, `mobile`

**Request:**
```json
{
  "id_customer": "42",
  "id_metal": "1",
  "mobile": "9876543210",
  "amount_inr": 5000,
  "rate_per_gram": 7500.50,
  "device_id": "abc123",
  "coupon_code": null,
  "request_from": "instant"
}
```

**Response:**
```json
{
  "success": true,
  "data": { "next_step": "PAYMENT" }
}
```

### API: `POST users/shared/amount-denominations`
**Request:** `{ "id_metal": "1" }`  
**Response:**
```json
{
  "data": [
    { "value": 500, "is_popular": 0 },
    { "value": 1000, "is_popular": 1 },
    { "value": 5000, "is_popular": 0 }
  ]
}
```

### API: `POST users/shared/weight-denominations`
**Request:** `{ "id_metal": "1" }`  
**Response:**
```json
{
  "data": [
    { "value": 0.5, "is_popular": 0 },
    { "value": 1.0, "is_popular": 1 }
  ]
}
```

---

## 14. Payment Methods Screen

**File:** `lib/features/instant_saving/screens/payment_methods_screen.dart`  
**Route:** `/payment-methods`  
**Args:** `{ amount, metal_id, rate, coupon_code, buy_type, weight }`

### Flow
```
On load:
  → Fetch payment methods API
  → Start sell rate lock timer (countdown)
User selects payment method
  → Call savings/initiate API → get order_id + cf_session_id
  → Launch Cashfree SDK checkout
  → onVerify callback → call confirm-payment API
  → onError callback → still call confirm-payment (server reconciles)
  → Based on confirm result:
      SUCCESS → Navigate → Purchase Success
      FAILED  → Navigate → Purchase Failed
```

### API: `POST payments/methods`
**Response:**
```json
{
  "data": {
    "payment_methods": [
      { "id": "upi", "name": "UPI", "icon": "...", "enabled": true },
      { "id": "card", "name": "Card", "icon": "...", "enabled": true }
    ]
  }
}
```

### API: `POST savings/initiate`
**Encrypted fields:** `amount_inr`, `weight`, `mobile`

**Request:**
```json
{
  "id_customer": "42",
  "id_metal": "1",
  "mobile": "9876543210",
  "buy_type": 1,
  "amount_inr": "5000.00",
  "rate_per_gram": 7500.50,
  "weight": 0.6543,
  "device_id": "abc123",
  "coupon_code": null,
  "request_from": "instant"
}
```

**Response:**
```json
{
  "data": {
    "order_id": "order_abc123",
    "cf_session_id": "session_xyz789",
    "cf_order_id": "cf_abc123",
    "amount": 5000.00,
    "status": "INITIATED"
  }
}
```

### API: `POST savings/confirm-payment`
**Request:**
```json
{ "order_id": "order_abc123" }
```

**Response:**
```json
{
  "success": true,
  "data": { "status": "SUCCESS", "transaction_id": "txn_123" }
}
```

### API: `POST payments/create-order`
**Request:**
```json
{
  "amount": 5000,
  "method_id": "upi",
  "transaction_id": "txn_123"
}
```

### API: `POST payments/status`
**Request:** `{ "order_id": "cf_abc123" }`  
**Response:** `{ "data": { "status": "SUCCESS" } }`

---

## 15. Withdrawal Screen

**File:** `lib/features/withdrawal/screens/withdrawal_screen.dart`  
**Route:** `/withdrawal` (also Tab 2 in MainScreen)  
**Providers:** `rewardBalanceProvider`, `withdrawalPolicyProvider`

### Flow
```
On load:
  → Fetch reward balance (available grams, on-hold grams)
  → Listen to WebSocket for live buy rate
  → Start buy rate lock timer
Commodity tabs: Gold | Silver
  → Toggle updates metalId → refreshes balance + denominations
User enters amount (₹)
  → App calculates weight = amount / buyRate
  → Validates: weight ≤ withdrawable_qty
  → Fetch withdrawal policy (charges, net amount)
Tap "Withdraw":
  → Call check-eligibility (request_from: "withdraw")
      → "PAYMENT" → Navigate → /upi-selection
      → "KYC_REQUIRED" → Navigate → /kyc-dynamic
```

### API: `POST referrals/reward-balance`
**Request:**
```json
{ "id_metal": "1" }
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "withdrawable_qty": "2.5000",
      "total_qty": "3.0000",
      "on_hold_qty": "0.5000",
      "commodity_name": "Gold 24K"
    }
  ]
}
```

### API: `POST withdrawal/policy`
**Encrypted fields:** `amount`

**Request:**
```json
{ "id_metal": 1, "amount": 5000.00 }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "gross_amount": 5000.00,
    "charges": 50.00,
    "tds": 25.00,
    "net_amount": 4925.00,
    "charge_details": [...]
  }
}
```

---

## 16. UPI Selection Screen

**File:** `lib/features/withdrawal/screens/upi_selection_screen.dart`  
**Route:** `/upi-selection`  
**Provider:** `accountDetailsProvider`

### Flow
```
On load:
  → Fetch saved UPI accounts (profile/accountdetails API)
  → Show UPI list with radio selection
  → "Add New UPI" → Show form → verify-upi API → add to list
User selects UPI → Tap "Continue"
  → Navigate → /withdrawal-confirmation (pass selected UPI)
```

### API: `POST profile/accountdetails`
**Request:**
```json
{ "id_customer": "42", "mobile": "9876543210" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accounts": [
      { "id": "1", "upi_id": "john@upi", "name": "John Doe", "verified": true }
    ]
  }
}
```

### API: `POST account/verify-upi`
**Encrypted fields:** `upi_id`, `mobile`

**Request:**
```json
{ "mobile": "9876543210", "upi_id": "john@paytm" }
```

**Response:**
```json
{ "success": true, "data": { "name": "John Doe", "verified": true } }
```

### API: `POST account/verify-bank`
**Encrypted fields:** `account_no`, `ifsc_code`, `mobile`

**Request:**
```json
{
  "mobile": "9876543210",
  "account_holder": "John Doe",
  "bank_name": "SBI",
  "account_no": "1234567890",
  "ifsc_code": "SBIN0001234"
}
```

---

## 17. Withdrawal Confirmation Screen

**File:** `lib/features/withdrawal/screens/withdrawal_confirmation_screen.dart`  
**Route:** `/withdrawal-confirmation`

### Flow
```
Show summary: amount, weight, rate, charges, net amount, UPI ID
Tap "Confirm Withdrawal":
  → Navigate → /mpin (mode: withdrawal_pin)
  → MPIN verified (returns true)
  → Call withdrawal/withdraw API
  → Success → Navigate → /withdrawal-success
  → Error → Show toast
```

### API: `POST withdrawal/withdraw`
**Encrypted fields:** `amount`, `weight`, `buy_rate`

**Request:**
```json
{
  "id_metal": "1",
  "amount": 5000.00,
  "weight": 0.6543,
  "buy_rate": 7640.50,
  "withdrawal_method_id": "1",
  "withdrawal_method": "UPI"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_id": "wtxn_456",
    "status": "PROCESSING",
    "amount": 4925.00,
    "weight": "0.6543 gm"
  }
}
```

---

## 18. Withdrawal Success Screen

**File:** `lib/features/withdrawal/screens/withdrawal_success_screen.dart`  
**Route:** `/withdrawal-success`  
**Args:** `{ transaction_id, status, amount, weight }`

### Flow
```
Show success animation + transaction details
Tap "Go to Home" → Navigate → /main (clear stack)
```


---

## 19. Auto Savings (SIP) Screen

**File:** `lib/features/sip/screens/auto_savings_screen.dart`  
**Route:** `/auto-savings`

### Flow
```
On load:
  → Fetch SIP config (frequencies, min/max)
  → Fetch gold + silver denominations
  → Listen to WebSocket for live rate
User selects: Frequency (Daily/Weekly/Monthly) + Commodity (Gold/Silver) + Amount
  → Weekly: select day (Mon–Sat)
  → Monthly: select date (1–28)
Tap "Setup Auto Savings":
  → Call sip/create API
  → Response contains authorization_link + order_id
  → Launch Cashfree mandate webview (authorization_link)
  → On return: call sip/confirm API
  → Success → /sip-success | Failure → /sip-failure
```

### API: `POST sip/config`
**Response:**
```json
{
  "data": {
    "frequencies": [
      { "id": 1, "name": "Daily" },
      { "id": 2, "name": "Weekly" },
      { "id": 3, "name": "Monthly" }
    ],
    "min_amount": 100,
    "max_amount": 50000,
    "commodities": [
      { "id": 1, "name": "Gold 24K" },
      { "id": 3, "name": "Silver" }
    ]
  }
}
```

### API: `POST sip/gold-denominations`
**Request:** `{ "frequency": 1 }` (optional)  
**Response:**
```json
{
  "data": [
    { "amount": 100, "is_popular": false },
    { "amount": 500, "is_popular": true }
  ]
}
```

### API: `POST sip/silver-denominations`
Same structure as gold denominations.

### API: `POST sip/create`
**Encrypted fields:** `amount`

**Request:**
```json
{
  "frequency": 1,
  "commodity_id": 1,
  "amount": 500,
  "day": "Monday",
  "date": null
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "subscription_id": "sub_abc123",
    "order_id": "order_xyz",
    "authorization_link": "https://cashfree.com/mandate/...",
    "cf_subscription_id": "cf_sub_123"
  }
}
```

### API: `POST sip/confirm`
**Request:**
```json
{
  "order_id": "order_xyz",
  "subscription_id": "sub_abc123"
}
```

**Response:**
```json
{ "success": true, "data": { "status": "ACTIVE" } }
```

---

## 20. SIP Overview Screen

**File:** `lib/features/sip/screens/sip_overview_screen.dart`  
**Route:** `/sip-overview`

### Flow
```
On load → Fetch sip/details API
  → Show active SIP plans grouped by frequency tabs (Daily/Weekly/Monthly)
  → Filter by commodity (Gold/Silver)
  → Tap plan → Navigate → /sip-manage (pass subscription_id)
```

### API: `POST sip/details`
**Response:**
```json
{
  "data": [
    {
      "subscription_id": "sub_abc123",
      "frequency": "Daily",
      "commodity": "Gold 24K",
      "amount": 500,
      "status": "ACTIVE",
      "next_payment_date": "2026-05-09"
    }
  ]
}
```

---

## 21. SIP Manage Screen

**File:** `lib/features/sip/screens/manage_savings_screen.dart`  
**Route:** `/sip-manage`  
**Args:** `{ subscription_id }`

### Flow
```
On load → Fetch sip/manage-details API
  → Show plan details, payment history
  → Actions: Pause | Resume | Cancel
```

### API: `POST sip/manage-details`
**Request:** `{ "subscription_id": "sub_abc123" }`

### API: `POST sip/pause`
**Request:** `{ "subscription_id": "sub_abc123" }`

### API: `POST sip/resume`
**Request:** `{ "subscription_id": "sub_abc123" }`

---

## 22. SIP Cancel Screen

**File:** `lib/features/sip/screens/sip_cancel_screen.dart`  
**Route:** `/sip-cancel`  
**Args:** `{ subscription_id }`

### API: `POST sip/cancel`
**Request:**
```json
{ "subscription_id": "sub_abc123", "reason": "Not needed anymore" }
```

---

## 23. SIP Transaction History

**File:** `lib/features/sip/screens/sip_transaction_history_screen.dart`  
**Route:** `/sip-transactions`

### API: `POST sip/transactions`
**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "transaction_id": "stxn_123",
        "date": "2026-05-08",
        "amount": 500,
        "commodity": "Gold 24K",
        "status": "SUCCESS",
        "frequency": "Daily"
      }
    ]
  }
}
```

## 24. SIP Transaction Details

**File:** `lib/features/sip/screens/sip_transaction_details_screen.dart`  
**Route:** `/sip-transaction-details`

### API: `POST sip/transaction-details`
**Request:** `{ "transaction_id": "stxn_123" }`

---

## 25. KYC Screen

**File:** `lib/features/kyc/screens/kyc_screen.dart`  
**Route:** `/kyc-dynamic`  
**Args:** `{ request_from, ...extraData }`

### Flow
```
On load:
  → Fetch document types (PAN, Aadhaar, Bank)
  → Show dynamic form based on document type fields
User fills form fields
  → Call kyc/upload API (fields encrypted)
  → Success → Navigate back to calling flow (instant saving or withdrawal)
  → Error → Show server error message
```

### API: `POST kyc/document-types`
**Request:**
```json
{ "id_customer": "42", "request_from": "instant" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "documents": [
      {
        "id": "1",
        "name": "PAN Card",
        "status": "pending",
        "fields": [
          { "key": "pan_number", "label": "PAN Number", "type": "text", "required": true },
          { "key": "name_as_per_pan", "label": "Name as per PAN", "type": "text", "required": true }
        ]
      },
      {
        "id": "2",
        "name": "Aadhaar",
        "status": "verified",
        "fields": [...]
      }
    ]
  }
}
```

### API: `POST kyc/upload`
**Encrypted fields:** `pan_number`, `aadhaar_number`, `bank_account_number`

**Request:**
```json
{
  "id_document": "1",
  "request_from": "instant",
  "fields": {
    "pan_number": "<encrypted>",
    "name_as_per_pan": "JOHN DOE"
  }
}
```

---

## 26. Transaction History Screen

**File:** `lib/features/history/screens/transaction_history_screen.dart`  
**Route:** `/transaction-history`

### API: `POST transactions/history`
**Request:**
```json
{
  "id_customer": "42",
  "metal_type": "gold",
  "page": 1,
  "limit": 20
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "transaction_id": "txn_123",
        "type": "PURCHASE",
        "amount": 5000,
        "weight": "0.6543",
        "commodity": "Gold 24K",
        "status": "SUCCESS",
        "date": "2026-05-08T10:30:00Z"
      }
    ],
    "pagination": { "current_page": 1, "total_pages": 5 }
  }
}
```

## 27. Transaction Details Screen

**File:** `lib/features/history/screens/transaction_details_screen.dart`  
**Route:** `/transaction-details`

### API: `POST transactions/details`
**Request:** `{ "id_customer": "42", "transaction_id": "txn_123" }`

---

## 28. Profile Screen

**File:** `lib/features/profile/profile_screen.dart`  
**Route:** `/profile` (also Tab 3 in MainScreen)

### Menu items → Routes
| Menu | Route |
|------|-------|
| Account Details | `/accountdetails` |
| Nominee | `/nominee` |
| Change MPIN | `/change-mpin` |
| Transaction History | `/transaction-history` |
| Auto Savings Overview | `/sip-overview` |
| Referral & Earn | `/referral` |
| FAQ | `/faq` |
| Terms & Conditions | `/terms` |
| Privacy Policy | `/privacy` |
| About Us | `/about` |
| Contact Us | `/contact` |
| Enquiry | `/enquiry-list` |
| Delete Account | `/delete-account` |

---

## 29. Account Details Screen

**File:** `lib/features/profile/account_details_screen.dart`  
**Route:** `/accountdetails`

### Flow
```
On load → Fetch profile/customer_details API
  → Populate form: name, email, DOB, pincode, state, city, address
  → Profile photo with upload button
Pincode change:
  → Auto-call check-pincode API on 6 digits
  → Success → fill state + city
  → Error → toast + clear state/city, disable Save
Tap "Save" → Call profile/update API
Tap photo → Camera/Gallery picker → Call update-profile-photo API
```

### API: `POST profile/customer_details`
**Request:** `{ "id_customer": "42" }`  
**Response:**
```json
{
  "success": true,
  "data": {
    "name": "John Doe",
    "email": "john@example.com",
    "dob": "1990-01-15",
    "mobile": "9876543210",
    "pincode": "600001",
    "state": "Tamil Nadu",
    "city": "Chennai",
    "address": "123 Main St",
    "photo_url": "https://...",
    "profile_completion": 85
  }
}
```

### API: `POST profile/update`
**Request:**
```json
{
  "id_customer": "42",
  "name": "John Doe",
  "email": "john@example.com",
  "dob": "1990-01-15",
  "pincode": "600001",
  "state": "Tamil Nadu",
  "city": "Chennai",
  "address": "123 Main St",
  "id_country": "101",
  "id_state": "33",
  "id_city": "3301"
}
```

### API: `POST users/shared/check-pincode`
**Request:** `{ "pincode": "600001" }`  
**Response:**
```json
{
  "success": true,
  "data": {
    "state": "Tamil Nadu",
    "city": "Chennai",
    "id_state": "33",
    "id_city": "3301"
  }
}
```

### API: `POST customer/update-profile-photo`
**Content-Type:** `multipart/form-data`  
**Request:** `{ photo: File, id_customer: "42" }`

---

## 30. Nominee Screen

**File:** `lib/features/nominee/screens/nominee_screen.dart`  
**Route:** `/nominee`

### API: `POST users/nominee/details`
**Response:**
```json
{
  "success": true,
  "data": {
    "name": "Jane Doe",
    "relationship": "Spouse",
    "dob": "1992-05-20",
    "mobile": "9876543211",
    "pincode": "600001",
    "state": "Tamil Nadu",
    "city": "Chennai",
    "address": "123 Main St"
  }
}
```

### API: `POST users/nominee/update`
**Request:** Same fields as response above.

### API: `POST users/nominee/relationships`
**Response:**
```json
{
  "data": {
    "relationships": [
      { "id": "1", "name": "Spouse" },
      { "id": "2", "name": "Parent" },
      { "id": "3", "name": "Child" }
    ]
  }
}
```

---

## 31. Notifications Screen

**File:** `lib/features/notifications/notifications_screen.dart`  
**Route:** `/notifications`

### API: `POST users/notifications`
**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "title": "Purchase Successful",
      "message": "You bought 0.5g Gold",
      "type": "PURCHASE",
      "is_read": false,
      "created_at": "2026-05-08T10:30:00Z"
    }
  ]
}
```

### API: `POST users/notifications/read`
**Request:** `{ "notification_id": 1 }`

### API: `POST users/notifications/read-all`

### API: `POST users/notifications/delete`
**Request:** `{ "notification_id": 1 }`

### API: `POST users/notifications/unread-count`
**Response:** `{ "data": { "count": 5 } }`

### API: `POST users/notifications/register-token`
**Request:**
```json
{
  "fcm_token": "dGVzdC10b2tlbg...",
  "device_id": "abc123",
  "device_type": "android",
  "device_model": "Pixel 7",
  "device_name": "John's Phone",
  "os": "Android",
  "os_version": "14"
}
```

---

## 32. Referral Screen

**File:** `lib/features/referral/referral_screen.dart`  
**Route:** `/referral`

### API: `POST users/auth/referral/details`
**Response:**
```json
{
  "data": {
    "referral_code": "JOHN123",
    "total_referrals": 5,
    "total_earned": 500.00,
    "reward_amount": "100",
    "share_link": "https://startgold.com/r/JOHN123",
    "title": "Invite & earn ₹100 worth of Gold",
    "bullet_points": [
      { "content": "Share your code" },
      { "content": "Friend signs up" }
    ]
  }
}
```

## 33. Referee List Screen

**File:** `lib/features/referral/referee_list_screen.dart`  
**Route:** `/referee-list`

### API: `POST referrals/referee-list`
**Response:**
```json
{
  "data": {
    "count": 5,
    "results": [
      {
        "referee": "Jane",
        "referral_date": "2026-05-01",
        "reward": "100",
        "quantity": "0.013g",
        "status": "Completed",
        "reward_status": "Credited"
      }
    ]
  }
}
```

---

## 34. Support / Enquiry

### Enquiry Form
**File:** `lib/features/support/screens/enquiry_form_screen.dart`  
**Route:** `/enquiry-form`

### API: `POST support/create-ticket`
**Request:**
```json
{ "type": 1, "subject": "Payment issue", "content": "My payment was deducted but..." }
```

**Type mapping:** `Enquiry=1, Support=2, Review=3, Others=4, Auto Savings=5`

### Enquiry List
**File:** `lib/features/support/screens/enquiry_list_screen.dart`  
**Route:** `/enquiry-list`

### API: `POST support/list`
**Response:**
```json
{
  "data": [
    {
      "id": "1",
      "type": "Enquiry",
      "subject": "Payment issue",
      "content": "...",
      "status": "pending",
      "on": "2026-05-08"
    }
  ]
}
```

---

## 35. Content Pages

### Terms & Conditions — `POST content/terms`
### Privacy Policy — `POST content/privacy`
### About Us — `POST content/about-us`
### FAQ — `POST content/faqs`
### Refund Policy — `POST content/refund-policy`
### Contact Us — `POST content/contact-us`

**Common Response:**
```json
{
  "success": true,
  "data": {
    "title": "Terms & Conditions",
    "content": "<html>...</html>"
  }
}
```

---

## 36. Delete Account Screen

**File:** `lib/features/profile/screens/delete_account_screen.dart`  
**Route:** `/delete-account`

### API: `POST users/delete-account/info`
**Response:**
```json
{
  "success": true,
  "data": {
    "content": "Deleting your account will permanently...",
    "is_allowed": true
  }
}
```

### API: `POST users/delete-account`
**Request:** `{ "confirm": true }`

---

## 37. Maintenance Screen

**File:** `lib/features/maintenance/maintenance_screen.dart`  
**Route:** `/maintenance`

No API — triggered by `app/control` response.

---

## 38. Settings Screen

**File:** `lib/features/settings/settings_screen.dart`  
**Route:** `/settings`

Contains biometric toggle (local SecureStorage only, no API).

---

## 39. Daily Savings Screen

**File:** `lib/features/daily_savings/daily_savings_screen.dart`  
**Route:** `/daily-savings`

**Status:** Partial — screen exists, backend integration pending.

---

## API Endpoint Master List

| # | Endpoint | Auth | Encrypted Fields |
|---|----------|:----:|-----------------|
| 1 | `POST app/control` | ❌ | — |
| 2 | `POST users/content/onboarding` | ❌ | — |
| 3 | `POST users/auth/generate-otp` | ❌ | mobile |
| 4 | `POST users/auth/verify-otp` | ❌ | otp, mobile |
| 5 | `POST users/auth/register-check` | ❌ | mobile |
| 6 | `POST users/auth/register` | ❌ | mobile |
| 7 | `POST users/auth/refresh-token` | ❌ | — |
| 8 | `POST crypto/public-key` | ❌ | — |
| 9 | `POST mpin/create` | ✅ | mpin |
| 10 | `POST mpin/validate` | ✅ | mpin |
| 11 | `POST mpin/change` | ✅ | old_mpin, new_mpin |
| 12 | `POST mpin/reset` | ❌ | new_mpin |
| 13 | `POST auth/has-mpin` | ✅ | — |
| 14 | `GET users/auth/session-check` | ✅ | — |
| 15 | `POST home/dashboard` | ✅ | — |
| 16 | `POST portfolio/summary` | ✅ | — |
| 17 | `POST savings/config` | ✅ | — |
| 18 | `POST savings/check-eligibility` | ✅ | amount_inr, mobile |
| 19 | `POST savings/initiate` | ✅ | amount_inr, weight, mobile |
| 20 | `POST savings/confirm-payment` | ✅ | — |
| 21 | `POST savings/cancel_order` | ✅ | — |
| 22 | `POST payments/methods` | ✅ | — |
| 23 | `POST payments/create-order` | ✅ | amount |
| 24 | `POST payments/status` | ✅ | — |
| 25 | `POST withdrawal/withdraw` | ✅ | amount, weight, buy_rate |
| 26 | `POST withdrawal/policy` | ✅ | amount |
| 27 | `POST referrals/reward-balance` | ✅ | — |
| 28 | `POST profile/accountdetails` | ✅ | — |
| 29 | `POST account/verify-upi` | ✅ | upi_id, mobile |
| 30 | `POST account/verify-bank` | ✅ | account_no, ifsc_code |
| 31 | `POST sip/config` | ✅ | — |
| 32 | `POST sip/gold-denominations` | ✅ | — |
| 33 | `POST sip/silver-denominations` | ✅ | — |
| 34 | `POST sip/create` | ✅ | amount |
| 35 | `POST sip/details` | ✅ | — |
| 36 | `POST sip/manage-details` | ✅ | — |
| 37 | `POST sip/pause` | ✅ | — |
| 38 | `POST sip/resume` | ✅ | — |
| 39 | `POST sip/cancel` | ✅ | — |
| 40 | `POST sip/confirm` | ✅ | — |
| 41 | `POST sip/transactions` | ✅ | — |
| 42 | `POST sip/transaction-details` | ✅ | — |
| 43 | `POST kyc/document-types` | ✅ | — |
| 44 | `POST kyc/upload` | ✅ | pan_number, aadhaar_number |
| 45 | `POST transactions/history` | ✅ | — |
| 46 | `POST transactions/details` | ✅ | — |
| 47 | `POST profile/customer_details` | ✅ | — |
| 48 | `POST profile/update` | ✅ | — |
| 49 | `POST users/shared/check-pincode` | ✅ | — |
| 50 | `POST customer/update-profile-photo` | ✅ | — |
| 51 | `POST users/nominee/details` | ✅ | — |
| 52 | `POST users/nominee/update` | ✅ | — |
| 53 | `POST users/nominee/relationships` | ✅ | — |
| 54 | `POST users/notifications` | ✅ | — |
| 55 | `POST users/notifications/read` | ✅ | — |
| 56 | `POST users/notifications/read-all` | ✅ | — |
| 57 | `POST users/notifications/delete` | ✅ | — |
| 58 | `POST users/notifications/unread-count` | ✅ | — |
| 59 | `POST users/notifications/register-token` | ✅ | — |
| 60 | `POST users/auth/referral/details` | ✅ | — |
| 61 | `POST referrals/referee-list` | ✅ | — |
| 62 | `POST support/create-ticket` | ✅ | — |
| 63 | `POST support/list` | ✅ | — |
| 64 | `POST content/terms` | ❌ | — |
| 65 | `POST content/privacy` | ❌ | — |
| 66 | `POST content/faqs` | ❌ | — |
| 67 | `POST content/about-us` | ❌ | — |
| 68 | `POST content/contact-us` | ❌ | — |
| 69 | `POST content/refund-policy` | ❌ | — |
| 70 | `POST users/delete-account/info` | ✅ | — |
| 71 | `POST users/delete-account` | ✅ | — |
| 72 | `POST users/shared/country-codes` | ❌ | — |
| 73 | `POST users/shared/commodities` | ❌ | — |
| 74 | `POST users/shared/amount-denominations` | ✅ | — |
| 75 | `POST users/shared/weight-denominations` | ✅ | — |
| 76 | `WebSocket ws://...` | Token | — |
