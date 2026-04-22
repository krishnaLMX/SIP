# StartGold API Reference

**Base URL:** `http://startgoldapi.logimaxindia.com/api/api/v1/`
**All requests:** `POST` (unless noted) · `Content-Type: application/json`
**Auth header:** `Authorization: Bearer <access_token>` (on all authenticated endpoints)

> All responses follow: `{ "success": bool, "data": {...}, "message": "...", "error": { "message": "..." } }`
> Encrypted fields are marked 🔒 — AES-256 encrypted before sending.

---

## 1. Authentication

### 1.1 Generate OTP
`POST users/auth/generate-otp`

**Payload:**
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

**Response:**
```json
{
  "success": true,
  "data": {
    "otp_reference_id": "ref_abc123",
    "message": "OTP sent successfully"
  }
}
```

---

### 1.2 Verify OTP
`POST users/auth/verify-otp`

**Payload:**
```json
{
  "mobile": "9876543210",
  "otp": "123456",
  "otp_reference_id": "ref_abc123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "mpin_enabled": true,
    "is_new_user": false,
    "user": {
      "id_customer": "1001",
      "name": "Arjun Kumar",
      "photo_url": "https://..."
    }
  }
}
```

---

### 1.3 Register
`POST users/auth/register`

**Payload:**
```json
{
  "mobile": "9876543210",
  "full_name": "Arjun Kumar",
  "email": "arjun@example.com",
  "dob": "1995-06-15",
  "referral_code": "REFXYZ",
  "temp_token": "temp_abc",
  "device_id": "abc123",
  "device_type": "android"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id_customer": "1001", "name": "Arjun Kumar" }
  }
}
```

---

## 2. MPIN

### 2.1 Create MPIN
`POST mpin/create` (🔒 mpin encrypted)

**Payload:** `{ "mpin": "4821" }`
**Response:** `{ "success": true, "message": "MPIN set successfully" }`

### 2.2 Validate MPIN
`POST mpin/validate` (🔒 mpin encrypted)

**Payload:** `{ "mpin": "4821" }`
**Response:** `{ "success": true }`

### 2.3 Change MPIN
`POST mpin/change` (🔒 old_mpin, new_mpin encrypted)

**Payload:**
```json
{ "old_mpin": "4821", "new_mpin": "9034" }
```
**Response:** `{ "success": true, "message": "MPIN changed successfully" }`

### 2.4 Reset MPIN (Forgot PIN)
`POST mpin/reset` (🔒 new_mpin, mobile encrypted)

**Payload:**
```json
{
  "temp_token": "temp_abc123",
  "new_mpin": "9034",
  "mobile": "9876543210"
}
```
**Response:** `{ "success": true, "message": "MPIN reset successfully" }`

### 2.5 Check Has MPIN
`POST auth/has-mpin`

**Payload:** (none)
**Response:** `{ "hasMpin": true }`

---

## 3. Profile

### 3.1 Get Customer Details
`POST profile/customer_details`

**Payload:** `{ "id_customer": "1001" }`

**Response:**
```json
{
  "success": true,
  "data": {
    "id_customer": "1001", "name": "Arjun Kumar",
    "email": "arjun@example.com", "mobile": "9876543210",
    "dob": "1995-06-15", "pincode": "600001",
    "state": "Tamil Nadu", "city": "Chennai",
    "address": "123 Main St", "kyc_status": 1,
    "photo_url": "https://..."
  }
}
```

### 3.2 Update Profile
`POST profile/update`

**Payload:**
```json
{
  "id_customer": "1001", "name": "Arjun Kumar",
  "email": "arjun@example.com", "dob": "1995-06-15",
  "pincode": "600001", "state": "Tamil Nadu",
  "city": "Chennai", "address": "123 Main St",
  "id_country": "101", "id_state": "33", "id_city": "5"
}
```
**Response:** `{ "success": true, "message": "Profile updated successfully" }`

### 3.3 Update Profile Photo
`POST customer/update-profile-photo` · multipart/form-data

| Field | Type |
|---|---|
| photo | File |
| id_customer | String |

**Response:** `{ "success": true }`

### 3.4 Check Pincode
`POST users/shared/check-pincode`

**Payload:** `{ "pincode": "600001" }`

**Response:**
```json
{
  "success": true,
  "data": { "state": "Tamil Nadu", "city": "Chennai", "id_state": "33", "id_city": "5" }
}
```

### 3.5 Fetch Account Details (UPI / Bank)
`POST profile/accountdetails` (🔒 mobile encrypted)

**Payload:** `{ "id_customer": "1001", "mobile": "9876543210" }`

**Response:**
```json
{
  "success": true,
  "data": {
    "accounts": [
      { "id": "acc_1", "type": "upi", "upi_id": "arjun@upi", "name": "Arjun Kumar" },
      { "id": "acc_2", "type": "bank", "account_no": "XXXX1234", "ifsc_code": "SBIN0001234", "bank_name": "SBI" }
    ]
  }
}
```

---

## 4. KYC

### 4.1 Get Document Types
`POST kyc/document-types`

**Payload:** `{ "id_country": "101" }`

**Response:**
```json
{
  "success": true,
  "data": [
    { "id": "1", "name": "Aadhaar Card", "code": "aadhaar" },
    { "id": "2", "name": "PAN Card", "code": "pan" }
  ]
}
```

### 4.2 Upload KYC Document
`POST kyc/upload` · multipart/form-data (🔒 aadhaar_number, pan_number encrypted)

| Field | Type | Note |
|---|---|---|
| id_customer | String | |
| document_type | String | aadhaar / pan |
| aadhaar_number | String | 🔒 encrypted |
| pan_number | String | 🔒 encrypted |
| front_image | File | |
| back_image | File | if applicable |

**Response:**
```json
{ "success": true, "message": "KYC submitted", "data": { "kyc_status": 0 } }
```
`kyc_status`: 0=pending, 1=verified, 2=rejected

---

## 5. Savings / Investment

### 5.1 Get Savings Config
`POST savings/config`

**Payload:** (none)

**Response:**
```json
{
  "success": true,
  "data": {
    "min_amount": 10, "max_amount": 100000,
    "metals": [
      { "id_metal": "1", "name": "Gold 24K" },
      { "id_metal": "3", "name": "Silver" }
    ]
  }
}
```

### 5.2 Check Eligibility
`POST savings/check-eligibility` (🔒 mobile, amount_inr encrypted)

**Payload:**
```json
{
  "id_customer": "1001", "id_metal": "1",
  "mobile": "9876543210", "amount_inr": 500.00,
  "rate_per_gram": 7250.50, "device_id": "abc123",
  "coupon_code": "SAVE10", "request_from": "instant"
}
```

**Response:**
```json
{
  "success": true,
  "data": { "eligible": true, "next_step": "proceed", "message": "You are eligible" }
}
```
`next_step`: proceed | kyc | error

### 5.3 Initiate Purchase
`POST savings/initiate` (🔒 mobile, amount_inr encrypted)

**Payload:**
```json
{
  "id_customer": "1001", "id_metal": "1",
  "mobile": "9876543210", "buy_type": "amount",
  "amount_inr": "500.00", "rate_per_gram": 7250.50,
  "weight": 0.0689, "device_id": "abc123",
  "coupon_code": "SAVE10", "request_from": "instant"
}
```

**Response:**
```json
{
  "success": true,
  "data": { "transaction_id": "txn_abc", "order_id": "ord_xyz", "amount": 500.00, "weight": 0.0689 }
}
```

### 5.4 Confirm Payment
`POST savings/confirm-payment`

**Payload:** `{ "order_id": "ord_xyz" }`
**Response:** `{ "success": true }`

### 5.5 Cancel Order
`POST savings/cancel_order`

**Payload:** `{ "order_id": "ord_xyz" }`
**Response:** `{ "success": true }`

---

## 6. Payment Gateway

### 6.1 Get Payment Methods
`POST payments/methods`

**Payload:** (none)

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_methods": [
      { "id": "1", "name": "UPI", "code": "upi" },
      { "id": "2", "name": "Net Banking", "code": "netbanking" }
    ]
  }
}
```

### 6.2 Create Payment Order
`POST payments/create-order` (🔒 amount encrypted)

**Payload:**
```json
{ "amount": 500.00, "method_id": "1", "transaction_id": "txn_abc" }
```

**Response:**
```json
{
  "success": true,
  "data": { "order_id": "cf_ord_xyz", "payment_session_id": "session_abc", "amount": 500.00 }
}
```

### 6.3 Payment Status
`POST payments/status`

**Payload:** `{ "order_id": "cf_ord_xyz" }`
**Response:** `{ "success": true, "data": { "status": "SUCCESS" } }`
`status`: SUCCESS | FAILED | PENDING

---

## 7. Withdrawal

### 7.1 Submit Withdrawal
`POST withdrawal/withdraw` (🔒 amount, weight, buy_rate encrypted)

**Payload:**
```json
{
  "id_metal": "1", "amount": 1000.00,
  "weight": 0.1379, "buy_rate": 7250.50,
  "withdrawal_method_id": "acc_1", "withdrawal_method": "upi"
}
```

**Response:**
```json
{
  "success": true,
  "data": { "transaction_id": "wthd_abc", "message": "Withdrawal initiated", "estimated_time": "24-48 hours" }
}
```

### 7.2 Verify & Add UPI
`POST account/verify-upi` (🔒 mobile, upi_id encrypted)

**Payload:**
```json
{ "mobile": "9876543210", "upi_id": "arjun@upi" }
```

**Response:**
```json
{ "success": true, "data": { "name": "Arjun Kumar", "upi_id": "arjun@upi", "verified": true } }
```

### 7.3 Verify & Add Bank Account
`POST account/verify-bank` (🔒 mobile, account_no, ifsc_code encrypted)

**Payload:**
```json
{
  "mobile": "9876543210", "account_holder": "Arjun Kumar",
  "bank_name": "State Bank of India",
  "account_no": "1234567890", "ifsc_code": "SBIN0001234"
}
```

**Response:**
```json
{ "success": true, "data": { "verified": true, "bank_name": "SBI", "account_holder": "Arjun Kumar" } }
```

### 7.4 Fetch Referral Reward Balance
`POST referrals/reward-balance`

**Payload:** `{ "id_metal": "1" }`

**Response:**
```json
{
  "success": true,
  "data": [
    { "commodity_name": "Gold 24K", "withdrawable_qty": 0.5000, "total_qty": 0.6000, "on_hold_qty": 0.1000 }
  ]
}
```

---

## 8. Referral

### 8.1 Get Referral Details
`POST users/auth/referral/details`

**Payload:** (none)

**Response:**
```json
{
  "success": true,
  "data": {
    "referral_code": "AQWYSJ", "total_referrals": 5,
    "total_earned": 250.00, "reward_per_referral": 50.00,
    "reward_amount": "50",
    "reward_text": "Refer a friend and earn Rs.50 in gold!",
    "bullet_points": ["Share your code", "They invest Rs.500+", "You earn Rs.50 in gold"]
  }
}
```

---

## 9. Notifications

### 9.1 Get Notification List
`POST users/notifications`

**Payload:** (none)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1, "title": "Gold Price Alert",
      "message": "Gold increased Rs.50 today",
      "type": "market", "is_read": false,
      "created_at": "2026-04-17"
    }
  ]
}
```
`type`: market | transaction | kyc | withdrawal | offer

### 9.2 Mark as Read
`POST users/notifications/read`

**Payload:** `{ "notification_id": 1 }`
**Response:** `{ "success": true, "message": "Marked as read" }`

### 9.3 Get Unread Count (Badge)
`POST users/notifications/unread-count`

**Payload:** (none)
**Response:** `{ "success": true, "data": { "count": 3 } }`

---

## 10. Transaction History

### 10.1 Get Transaction History
`POST transactions/history`

**Payload:**
```json
{ "id_customer": "1001", "metal_type": "gold", "page": 1, "limit": 20 }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      { "transaction_id": "txn_abc", "type": "buy", "amount": 500.00, "weight": 0.0689, "metal": "Gold 24K", "status": "success", "date": "2026-04-17" }
    ],
    "total": 25, "page": 1
  }
}
```

### 10.2 Get Transaction Details
`POST transactions/details`

**Payload:**
```json
{ "id_customer": "1001", "transaction_id": "txn_abc" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_id": "txn_abc", "type": "buy",
    "amount": 500.00, "weight": 0.0689, "rate": 7250.50,
    "metal": "Gold 24K", "payment_method": "UPI",
    "status": "success", "date": "2026-04-17T10:30:00Z",
    "invoice_url": "https://..."
  }
}
```

---

## 11. Support / Enquiry

### 11.1 Create Support Ticket
`POST support/create-ticket`

**Payload:**
```json
{ "subject": "Unable to withdraw", "message": "I am facing an issue...", "category": "withdrawal" }
```
**Response:** `{ "success": true, "data": { "ticket_id": "TKT-1001" } }`

### 11.2 Get Enquiry List
`POST support/list`

**Payload:** (none)
**Response:**
```json
{
  "success": true,
  "data": [
    { "ticket_id": "TKT-1001", "subject": "Unable to withdraw", "status": "open", "created_at": "2026-04-17" }
  ]
}
```

---

## 12. Content Pages

| Endpoint | Purpose |
|---|---|
| POST content/terms | Terms & Conditions |
| POST content/privacy | Privacy Policy |
| POST content/faqs | FAQ List |
| POST content/about-us | About Us |
| POST content/contact-us | Contact Details |
| POST users/content/onboarding | Onboarding slides |

All: `{ "success": true, "data": { "content": "..." } }`

---

## 13. Shared / Utility

### 13.1 Country Codes
`POST users/shared/country-codes`
**Response:** `{ "data": [{ "id_country": "101", "name": "India", "iso": "IN", "code": "+91", "flag": "IN" }] }`

### 13.2 Commodities
`POST users/shared/commodities`
**Response:** `{ "data": [{ "id_metal": "1", "name": "Gold 24K", "web_soc_id": "1" }, { "id_metal": "3", "name": "Silver", "web_soc_id": "3" }] }`

### 13.3 Amount Denominations
`POST users/shared/amount-denominations`
**Payload:** `{ "id_metal": "1" }`
**Response:** `{ "data": [{ "value": 100, "is_popular": 0 }, { "value": 500, "is_popular": 1 }] }`

### 13.4 Weight Denominations
`POST users/shared/weight-denominations`
**Payload:** `{ "id_metal": "1" }`
**Response:** `{ "data": [{ "value": 0.5, "is_popular": 1 }, { "value": 1.0, "is_popular": 1 }] }`

### 13.5 Home Dashboard
`POST home/dashboard`
**Payload:** `{ "id_metal": "1" }`
**Response:**
```json
{
  "success": true,
  "data": {
    "portfolio_value": 15250.00, "total_weight": 2.1035,
    "gold_rate": 7250.50, "referral_message": "Invite friends and earn Rs.50 in gold!"
  }
}
```

### 13.6 App Control
`POST app/control`
**Response:**
```json
{
  "success": true,
  "data": { "force_update": false, "min_version": "1.0.0", "maintenance": false, "maintenance_message": "" }
}
```

### 13.7 RSA Public Key
`GET crypto/public-key`
**Response:** `{ "public_key": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----" }`

---

## 14. WebSocket — Live Rates

**URL:** `ws://bullion_v4.logimaxindia.com/ratesocket/socket.io/`

| Event | Direction | Payload |
|---|---|---|
| market_rates | Server to Client | `{ "gold": 7250.50, "silver": 85.20, "market_status": "open" }` |
| gold_rate | Server to Client | `{ "rate": 7250.50 }` |
| silver_rate | Server to Client | `{ "rate": 85.20 }` |

Socket must NEVER send sensitive data. Always reconnect automatically on disconnect.

---

## Security — Encrypted Fields Summary

| Field | Encrypted |
|---|---|
| otp, login_pin, password | YES |
| mpin, old_mpin, new_mpin | YES |
| mobile | YES |
| aadhaar_number, pan_number | YES |
| bank_account_number, account_no | YES |
| ifsc_code, upi_id | YES |
| amount_inr, weight, buy_rate | YES |
| id_customer, id_metal, page, limit | Plain |
| All content/display GET endpoints | Plain |
