# Today's Code Changes — April 13, 2026 & April 18, 2026

---

# 📅 April 18, 2026 — Notification System Implementation

## Files Changed (13 files)

| # | File | Change Type |
|---|---|---|
| 1 | `apis.md` | Section 12 — Notifications appended |
| 2 | `lib/core/services/notification_service.dart` | `registerFcmToken()` method added |
| 3 | `lib/core/security/secure_storage_service.dart` | `saveFcmToken` / `getFcmToken` added |
| 4 | `lib/core/config/app_config.dart` | `keyFcmToken` storage key added |
| 5 | `lib/features/mpin/mpin_screen.dart` | `_registerFcmTokenAfterLogin()` + imports |
| 6 | `lib/core/services/fcm_service.dart` | Full FCM implementation (replaces stub) |
| 7 | `pubspec.yaml` | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| 8 | `android/settings.gradle.kts` | Google Services plugin declared |
| 9 | `android/app/build.gradle.kts` | Google Services plugin applied |
| 10 | `android/app/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS` permission added |
| 11 | `android/app/google-services.json` | Placed by developer (Firebase config) |
| 12 | `lib/main.dart` | `Firebase.initializeApp()` + `kIsWeb` guards + `FcmService.init()` |
| 13 | `lib/features/home/home_screen.dart` | Bell icon — `GestureDetector` + navigate to `/notifications` |

## Key Changes Detail

### `fcm_service.dart` — Full FCM Service
- Foreground: shows `flutter_local_notifications` banner
- Background/Terminated tap: navigates to `/notifications`
- Token refresh: auto re-registers with backend
- Design rule: FCM is **trigger only** — never renders payload data

### `main.dart` — Firebase Init + Web Guard
```dart
if (!kIsWeb) {
  await Firebase.initializeApp();
  await FcmService.init();
}
```
App now runs on both **Android** AND **Chrome** (`flutter run -d chrome`).

### `mpin_screen.dart` — Token Sent After Login
```dart
void _registerFcmTokenAfterLogin() {
  // Fire-and-forget after successful MPIN verify → navigate to /main
  FcmService.getToken() → NotificationService.registerFcmToken(token)
}
```

### `home_screen.dart` — Bell Icon Fixed
```dart
// Before: no tap handler (broken)
// After:
GestureDetector(
  onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
  child: _buildActionIcon(...),
)
```

## Notification Flow
```
Bell tap / FCM tap → /notifications → POST users/notifications
  → List (green dot = unread)
  → Item tap → POST users/notifications/read → dot removed (optimistic)
```

---


> [!IMPORTANT]
> Complete list of all Dart files modified today. Flutter shares the same `lib/` across Android and iOS — no separate iOS code changes needed.

---

## Summary of Changed Files (13 files)

| # | File | Key Changes |
|---|------|-------------|
| 1 | `mpin_screen.dart` | MPIN keypad UI cleanup |
| 2 | `withdrawal_success_screen.dart` | Lottie → GIF, dark green card layout |
| 3 | `purchase_success_screen.dart` | Lottie → GIF, consistent card design |
| 4 | `transaction_details_screen.dart` | SVG icons, referral type, order_id, copy-to-clipboard |
| 5 | `transaction_history_screen.dart` | SVG icons, referral type support |
| 6 | `main_screen.dart` | Bottom nav visibility fix |
| 7 | `payment_methods_screen.dart` | Header/timer refinements |
| 8 | `withdrawal_confirmation_screen.dart` | Rate lock & submission refinements |
| 9 | `history_models.dart` | Added `orderId` to models |
| 10 | `login_screen.dart` | Logo moved to right, reduced spacing |
| 11 | `otp_screen.dart` | Added logo on right side |
| 12 | `registration_screen.dart` | Logo on right, title → "Personal Information", PAN note |
| 13 | `pin_creation_screen.dart` | Logo on right side |

---

## Detailed Changes Per File

### 1. `mpin_screen.dart`
**Path:** [mpin_screen.dart](file:///d:/Git/SIP/lib/features/mpin/mpin_screen.dart)

- Removed redundant container boxes from the MPIN keypad for a cleaner minimalist aesthetic
- Number keys use `BoxShape.circle` with subtle borders and shadows
- Backspace key uses a simple `SizedBox` (no decorative box)

---

### 2. `withdrawal_success_screen.dart`
**Path:** [withdrawal_success_screen.dart](file:///d:/Git/SIP/lib/features/withdrawal/screens/withdrawal_success_screen.dart)

- **Lottie → GIF**: Uses `Image.asset('assets/withdraw/successtik.gif')`
- **Dark green summary card**: Gradient `#0D4A1A → #002E0F`
- **Structured detail rows**: Transaction ID (copyable), Target Account, Status
- **Commodity badge**: Shows "Gold 24K" or "Silver 999" dynamically

---

### 3. `purchase_success_screen.dart`
**Path:** [purchase_success_screen.dart](file:///d:/Git/SIP/lib/features/instant_saving/screens/purchase_success_screen.dart)

- **Lottie → GIF**: Same `successtik.gif` for consistency
- **Consistent card design**: Same dark green gradient as withdrawal success
- **Detail rows**: Order ID (copyable), Weight Credited, Buy Rate, Payment Mode
- **Failure card**: Red theme with "No amount has been deducted" message

---

### 4. `transaction_details_screen.dart`
**Path:** [transaction_details_screen.dart](file:///d:/Git/SIP/lib/features/history/screens/transaction_details_screen.dart)

- **SVG icons**: Replaced Material icons with custom SVG assets based on type + metal
- **Referral type**: Added `isReferral` flag → shows "Referral Reward" label with purple color
- **Order ID row**: Added `Order ID` with copy button in TRANSACTION DETAILS section
- **Copy-to-clipboard**: All copy icons now functional with `Clipboard.setData()` + toast
- **Added imports**: `flutter/services.dart`, `flutter_svg`

---

### 5. `transaction_history_screen.dart`
**Path:** [transaction_history_screen.dart](file:///d:/Git/SIP/lib/features/history/screens/transaction_history_screen.dart)

- **SVG icons**: Replaced Material icons with custom SVG assets (no background container)
- **Referral type**: Added `isReferral` flag → "Referral Reward" label with purple color
- **Icon mapping**:
  - Purchase Gold → `inst_gold.svg`
  - Purchase Silver → `inst_silver.svg`
  - Withdrawal Gold → `with_gold.svg`
  - Withdrawal Silver → `with_silver.svg`
  - Referral → `trans_referal.svg`

---

### 6. `main_screen.dart`
**Path:** [main_screen.dart](file:///d:/Git/SIP/lib/features/main/main_screen.dart)

- Bottom nav only rendered when `selectedIndex == 0` (Home tab)
- Lazy tab loading with `_visitedTabs` set
- Provider invalidation on mount for fresh dashboard data

---

### 7. `payment_methods_screen.dart`
**Path:** [payment_methods_screen.dart](file:///d:/Git/SIP/lib/features/instant_saving/screens/payment_methods_screen.dart)

- Gradient header widget
- Rate lock timer integration (`sellRateTimerProvider`)
- "Live Price Updated" green banner
- Auto-select first payment method
- Cashfree payment gateway integration

---

### 8. `withdrawal_confirmation_screen.dart`
**Path:** [withdrawal_confirmation_screen.dart](file:///d:/Git/SIP/lib/features/withdrawal/screens/withdrawal_confirmation_screen.dart)

- Rate lock timer (`buyRateTimerProvider`)
- Rate refresh handling with timer expiry
- `_isSubmitting` guard against double-submission
- API response field mapping for success screen

---

### 9. `history_models.dart`
**Path:** [history_models.dart](file:///d:/Git/SIP/lib/features/history/models/history_models.dart)

- **`TransactionDetailResponse`**: Added `orderId` field (parsed from `order_id`)
- **`TechnicalDetails`**: Added `orderId` field

---

### 10. `login_screen.dart`
**Path:** [login_screen.dart](file:///d:/Git/SIP/lib/features/auth/login/login_screen.dart)

- **Logo moved to right**: `MainAxisAlignment.end`
- **Reduced spacing**: Logo-to-text gap from `48.h` → `24.h`

---

### 11. `otp_screen.dart`
**Path:** [otp_screen.dart](file:///d:/Git/SIP/lib/features/auth/otp/otp_screen.dart)

- **Added logo**: startGold SVG on the right side (85h)
- **Layout**: Back arrow left, logo right (`MainAxisAlignment.spaceBetween`)
- **Added import**: `flutter_svg`

---

### 12. `registration_screen.dart`
**Path:** [registration_screen.dart](file:///d:/Git/SIP/lib/features/auth/registration/registration_screen.dart)

- **Logo on right**: Back arrow left, startGold logo right (85h)
- **Title changed**: "Enter full name exactly as on PAN Card" → **"Personal Information"**
- **Placeholder fixed**: "Enter your full name" → **"Enter Your Full Name"** (Start Case)
- **PAN note added**: ⚠️ "Note: Enter full name exactly as on your PAN Card." in amber with info icon
- **Added import**: `flutter_svg`

---

### 13. `pin_creation_screen.dart`
**Path:** [pin_creation_screen.dart](file:///d:/Git/SIP/lib/features/auth/pin/pin_creation_screen.dart)

- **Logo on right**: Back arrow left, startGold logo right (85h)
- Both "Set Your Security PIN" and "Confirm Your PIN" states show the logo
- **Added import**: `flutter_svg`

---

## Asset Dependencies

> [!TIP]
> Ensure these assets are present and registered in `pubspec.yaml`:

| Asset | Used In |
|-------|---------|
| `assets/withdraw/successtik.gif` | Purchase & Withdrawal success screens |
| `assets/withdraw/inst_gold.svg` | Transaction History & Details (purchase gold) |
| `assets/withdraw/inst_silver.svg` | Transaction History & Details (purchase silver) |
| `assets/withdraw/with_gold.svg` | Transaction History & Details (withdrawal gold) |
| `assets/withdraw/with_silver.svg` | Transaction History & Details (withdrawal silver) |
| `assets/withdraw/trans_referal.svg` | Transaction History & Details (referral) |
| `assets/images/startGold.svg` | Login, OTP, Registration, PIN Creation screens |

---

## iOS Build Steps

```bash
flutter clean
cd ios && pod install --repo-update && cd ..
flutter build ios
```

> [!WARNING]
> Test these on iOS:
> 1. `successtik.gif` — GIF rendering can differ on iOS
> 2. SVG icons — Verify all 5 transaction SVGs render correctly
> 3. Logo alignment — Confirm right-side logo positioning on all auth screens
