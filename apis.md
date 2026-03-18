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
    *   Endpoint: `ws://bullion_v4.logimaxindia.com/ratesocket/socket.io/`.
    *   **Auto-Reconnect:** Enabled for continuous market data flow.
    *   **Restricted Scope:** Socket is used EXCLUSIVELY for market rates; NO sensitive data is sent via WS.
7.  **Device Integrity:** 
    *   Pass `device_id` on login and sensitive actions.
    *   Environment checks (Root/Jailbreak detection) prevent the app from running on insecure hardware.

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
          "web_soc_id": 47,
          "name": "Gold 24KT"
        },
        {
          "id_metal": 2,
          "web_soc_id": 48,
          "name": "Silver 999"
        }
      ]
    }
    ```

### 1.4 Fetch Amount Denominations
*   **Endpoint:** `POST users/shared/amount-denominations`
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

## 3. MPIN Management (Security)

### 3.1 Create Secure MPIN
*   **Page Name:** `PinCreationScreen`
*   **Endpoint:** `POST /mpin/create`
*   **Authorization:** `Bearer Token`
*   **Request:** `{ "mpin": "1234" }`

### 3.2 Validate MPIN (App Unlock)
*   **Page Name:** `MpinScreen`
*   **Endpoint:** `POST /mpin/validate`
*   **Authorization:** `Bearer Token`
*   **Request:** `{ "mpin": "1234" }`

### 3.3 Check MPIN Status
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

---

## 4. Market & Portfolio

### 4.1 Live Gold Market Rates
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
*   `POST /referral/data`: Returns user referral code and earning stats.
*   `POST /referral/claim`: To claim referral rewards (Page: `ReferralScreen`).

### 5.5 Session Termination
*   `POST /auth/logout`: Invalidate session on server-side.

---

---

## 6. Instant Saving (Buy Flow)

### 6.1 Fetch Saving Configuration
*   **Endpoint:** `POST /savings/config`
*   **Description:** Retrieves global limits. Used to validate `min_amount` and `max_amount` before initiation.
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "min_amount": 10.0,
        "max_amount": 200000.0
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
      "coupon_code": null
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "message": "Eligibility checked successfully",
      "data": {
        "next_step": "KYC_REQUIRED / PAYMENT"
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
      "device_id": "uuid-123"
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
            "id_document": "1",
            "document_name": "Aadhaar",
            "code": "AADHAAR",
            "mandatory": true,
            "fields": [
              {
                "name": "aadhaar_number",
                "label": "Aadhaar Number",
                "type": "text",
                "regex": "^[0-9]{12}$"
              }
            ],
            "images": {
              "front": true,
              "back": true
            }
          },
          {
            "id_document": "2",
            "document_name": "PAN",
            "code": "PAN",
            "mandatory": true,
            "fields": [
              {
                "name": "pan_number",
                "label": "PAN Number",
                "type": "text",
                "regex": "^[A-Z]{5}[0-9]{4}[A-Z]{1}$"
              }
            ],
            "images": {
              "front": true,
              "back": false
            }
          }
        ]
      }
    }
    ```

### 7.2 Upload KYC Data
*   **Endpoint:** `POST /kyc/upload`
*   **Content-Type:** `multipart/form-data`
*   **Description:** Uploads KYC document details and images.
*   **Request Body:**
    *   `id_customer`: String
    *   `request_from`: String (e.g., "instant")
    *   `id_document`: String
    *   `fields`: JSON String (e.g., `{"aadhaar_number": "1234..."}`) -> **ENCRYPTED**
    *   `front_image`: File (multipart)
    *   `back_image`: File (multipart, optional)
*   **Security:** Field values (like Aadhaar/PAN numbers) must be encrypted before sending. Images must be JPEG/PNG < 5MB.
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
          { "id": "upi", "name": "UPI", "icon": "upi_icon_url" },
          { "id": "netbanking", "name": "Net Banking", "icon": "nb_icon_url" }
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

## 9. Withdrawal Flow

### 7.1 Check Eligibility & Balance
*   **Page Name:** `WithdrawalScreen`
*   **Endpoint:** `POST /withdrawal/eligibility`
*   **Response:** Returns live balance, KYC status, and withdrawal limits (Min/Max).

### 7.2 Fetch Verified Bank/UPI Accounts
*   **Endpoint:** `POST /withdrawal/bank-accounts`
*   **Response:** List of previously verified UPI IDs and Bank Accounts.

### 7.3 Add & Verify New UPI ID
*   **Step 1:** Call `POST /withdrawal/verify-upi-vpa` to check VPA owner name (e.g., via Setu/Cashfree).
*   **Step 2:** Call `Generate OTP` (Section 2.1) with `type: "ADD_UPI"`.
*   **Step 3:** Call `POST /withdrawal/add-upi` with `vpa`, `name`, and `otp`.

### 7.4 Initiate Withdrawal (MPIN Required)
*   **Endpoint:** `POST /withdrawal/initiate`
*   **Request Body:**
    ```json
    {
      "amount_grams": 0.001,
      "commodity_type": "GOLD",
      "withdrawal_method_id": "UPI_123",
      "mpin_hash": "HASHED_MPIN",
      "device_id": "uuid-123"
    }
    ```
*   **Response:**
    ```json
    {
      "success": true,
      "data": {
        "withdrawal_id": "WDL_101",
        "status": "PENDING",
        "estimated_arrival": "2024-03-02..."
      }
    }
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
      "data": {
        "email": "support@startgold.com",
        "phone": "+91 9876543210",
        "address": "123 gold street, bullion city",
        "working_hours": "10 AM - 7 PM"
      }
    }
    ```

---

## 11. Support Enquiries

### 11.1 Submit Enquiry
*   **Endpoint:** `POST users/support/submit`
*   **Payload:**
    ```json
    {
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
