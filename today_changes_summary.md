# All Changes — 30 April 2026 & 2 May 2026

Every file modified, with exact details for iOS sync.

---

## 📁 Files Changed (10 files)

---

### 1. `lib/core/network/native_socket_service.dart`
**Purpose:** Fix market-closed detection on app cold-start

**Changes:**
- `marketStatusStream` getter changed from direct stream to `async*` generator that **replays** current `_commodityOpenStatus` to new listeners
- Added `_gracePeriodTimer` field
- In `connect()`: after successful connection, starts a **1-second grace timer** — if no explicit `5|` market-status frame arrives AND rates are still 0, infers market is closed
- In `_handleRateUpdate()`: when a `5|` frame arrives, **cancels** the grace timer (explicit data takes precedence)
- Added `_inferClosedAfterGracePeriod()` method — only infers closed for commodities with no explicit `5|` status AND zero rates
- `disconnect()`: cancels `_gracePeriodTimer`

---

### 2. `lib/features/withdrawal/screens/withdrawal_screen.dart`
**Purpose:** Withdrawal policy validation — moved from real-time debounce to button-submit

**Changes:**
- Removed `import 'dart:async';`
- Removed `_policyDebounce` timer and `_fetchPolicy()` method
- Added `String? _policyError` state field
- `_amountController` listener now clears `_policyError` when user changes input
- Simplified button enablement — no longer depends on pre-fetched policy provider
- **Rewrote `_handleWithdraw()`**: now calls `withdrawal/policy` API on submit → if invalid shows `AppToast` + sets `_policyError` (disables button) → if valid calls `check-eligibility` → navigates
- Removed `_buildValidationError()` widget entirely (was the inline error banner)
- Input border color now uses `_policyError != null` instead of removed `showError`
- Error catch now shows actual API error message instead of generic "Something went wrong"

---

### 3. `lib/features/mpin/change_mpin_screen.dart`
**Purpose:** Typography — numeric "4" in "4-digit MPIN" renders in Lora

**Changes:**
- Added `import '../../../shared/widgets/numeric_styled_text.dart';`
- Subtitle "Enter your existing 4-digit MPIN" changed from `Text` to `NumericStyledText`

---

### 4. `lib/shared/widgets/app_toast.dart`
**Purpose:** All toast messages now use Lora for numeric content

**Changes:**
- Removed `import 'package:google_fonts/google_fonts.dart';`
- Added `import 'numeric_styled_text.dart';`
- In `_buildCard()`: replaced `Text` + `GoogleFonts.playfairDisplay(...)` with `NumericStyledText` widget

---

### 5. `lib/features/withdrawal/screens/withdrawal_success_screen.dart`
**Purpose:** Replace raw SnackBar with AppToast

**Changes:**
- Added `import '../../../shared/widgets/app_toast.dart';`
- "Transaction ID copied" SnackBar → `AppToast.show(context, 'Transaction ID copied', type: ToastType.success)`

---

### 6. `lib/features/instant_saving/screens/purchase_success_screen.dart`
**Purpose:** Replace raw SnackBars with AppToast (2 instances)

**Changes:**
- Added `import '../../../shared/widgets/app_toast.dart';`
- Success card "Order ID copied!" SnackBar → `AppToast.show(context, 'Order ID copied!', type: ToastType.success)`
- Failure card "Order ID copied!" SnackBar → `AppToast.show(context, 'Order ID copied!', type: ToastType.success)`

---

### 7. `lib/features/instant_saving/screens/payment_methods_screen.dart`
**Purpose:** Replace raw SnackBars with AppToast (2 instances)

**Changes:**
- Added `import 'package:startgold/shared/widgets/app_toast.dart';`
- `_createPaymentOrder()` catch: `ScaffoldMessenger.showSnackBar(SnackBar(...))` → `AppToast.show(context, message, type: ToastType.error)`
- `_startCashfreePayment()` catch: `ScaffoldMessenger.showSnackBar(SnackBar(...))` → `AppToast.show(context, message, type: ToastType.error)`

---

### 8. `lib/features/auth/registration/registration_screen.dart`
**Purpose:** Add T&C checkbox + `/register-check` API validation before PIN creation

**Changes:**
- Added `import 'package:flutter/gestures.dart';` and `import 'package:dio/dio.dart';`
- Added `_agreedToTerms` (bool) and `_isSubmitting` (bool) state fields
- Added `_termsRecognizer` (TapGestureRecognizer) — navigates to `AppRouter.terms`
- **New UI:** Checkbox row with "I agree to the **Terms and Conditions**" (T&C text styled `Colors.orangeAccent` with underline, tappable → opens T&C page)
- **Button disabled** when checkbox is unchecked (`onPressed: canSubmit ? _handleRegistration : null`)
- **Rewrote `_handleRegistration()`:**
  - Step 1: Form validation
  - Step 2: Call `POST users/auth/register-check` via `authService.registerCheck()`
  - If `success: true` → navigate to MPIN creation (no toast)
  - If `success: false` → show error toast, stay on page
  - Full `DioException` error handling with nested `error.message` extraction
- Disposed `_termsRecognizer` in `dispose()`

---

### 9. `lib/core/services/auth_service.dart`
**Purpose:** Add `registerCheck` API method

**Changes:**
- Added `registerCheck()` method — calls `POST users/auth/register-check`
- Sends: `mobile`, `full_name`, `email`, `dob`, `referral_code`, `temp_token`, `device_id`, `device_type`
- Returns raw `Map<String, dynamic>` response for caller to check `success`

---

### 10. `apis.md`
**Purpose:** Document the new `/register-check` endpoint

**Changes:**
- Added **Section 2.3.1 — Pre-Validate Registration Fields**
- Endpoint: `POST users/auth/register-check`
- Full request body, field table, success/error responses, app behaviour matrix, and error scenarios documented

---

## ✅ Summary Table

| # | File | What Changed |
|---|------|-------------|
| 1 | `native_socket_service.dart` | Market-closed detection: stream replay + 1s grace timer fallback |
| 2 | `withdrawal_screen.dart` | Policy API moved to button-submit, removed debounce + error banner |
| 3 | `change_mpin_screen.dart` | "4-digit" subtitle → NumericStyledText (Lora for "4") |
| 4 | `app_toast.dart` | Toast text → NumericStyledText (Lora for all numbers) |
| 5 | `withdrawal_success_screen.dart` | SnackBar → AppToast |
| 6 | `purchase_success_screen.dart` | 2× SnackBar → AppToast |
| 7 | `payment_methods_screen.dart` | 2× SnackBar → AppToast |
| 8 | `registration_screen.dart` | T&C checkbox (mandatory) + `/register-check` API on submit |
| 9 | `auth_service.dart` | Added `registerCheck()` method |
| 10 | `apis.md` | Section 2.3.1 — register-check endpoint docs |

> [!IMPORTANT]
> Zero `ScaffoldMessenger`/`SnackBar` calls remain in the codebase. All notifications go through `AppToast`.

---
---

# All Changes — 2 May 2026

Auto Savings Overview screen, SIP Transactions pill tabs, and NumericStyledText 24KT standardization.

---

## 📁 Files Changed (7 files)

---

### 1. `lib/features/sip/screens/sip_overview_screen.dart` ✨ NEW
**Purpose:** Auto Savings dashboard — Profile → Auto Savings

**Changes:**
- **New screen** at route `/sip-overview`
- Frequency pill tabs: Daily / Weekly / Monthly — always shown, green gradient on selected
- Invest type radio: Gold 24K / Silver — filters plans by commodity
- Plan detail card: Started On, Savings Amount, Frequency, Reference ID, Status (colored badge)
- No plan state: empty state with "Setup Auto Savings" CTA → `/auto-savings`
- Quick actions: "SIP Transactions" → `/sip-transactions`, "New Auto Save" → `/auto-savings`
- Tap on plan card → Manage Savings (`/sip-manage`) with `subscription_id`
- API: reuses `POST /sip/details` — no new endpoint needed
- Data freshness: `sipDetailsProvider` invalidated on every screen entry
- Uses `NumericStyledText` for commodity labels ("Gold **24K**")
- Full error state with retry button

---

### 2. `lib/routes/app_router.dart`
**Purpose:** Register route for new Auto Savings Overview screen

**Changes:**
- Added `import '../features/sip/screens/sip_overview_screen.dart';`
- Added `static const String sipOverview = '/sip-overview';`
- Added route builder: `sipOverview: (context) => const SipOverviewScreen()`

---

### 3. `lib/features/profile/profile_screen.dart`
**Purpose:** Add "Auto Savings" menu entry in Profile Settings

**Changes:**
- Added "Auto Savings" `_buildMenuItem()` in Profile Settings section
- Positioned before "SIP Transactions" menu item
- Icon: `autosaving.svg`
- Navigates to `AppRouter.sipOverview`

---

### 4. `lib/features/sip/screens/sip_transaction_history_screen.dart`
**Purpose:** Restyle frequency tabs to pill-tab design matching SipOverviewScreen

**Changes:**
- **`_buildFrequencyTabs()`** — fully replaced:
  - Before: `TabBar` with `14.r` rounded-rect background
  - After: Pill container, `50.r` radius, white bg, shadow, green gradient on selected
  - Padding: `16.w` → `40.w` (matching Overview)
  - Swipe support preserved via `TabController` + `animateTo()`
- **`_buildFrequencyBadge()`** — fully replaced:
  - Before: Left-aligned small green pill with "Daily SIP" text
  - After: Full-width pill container (same style as multi-tab version)

---

### 5. `lib/shared/widgets/numeric_styled_text.dart`
**Purpose:** Include K/T in numeric font pattern for commodity purity labels

**Changes:**
- Regex pattern updated:
  ```diff
  -  static final _numericPattern = RegExp(r'[\d₹%\.,:\\/\+\-×Xx]+');
  +  static final _numericPattern = RegExp(r'[\d₹%\.,:\\/\+\-×XxKTkt]+');
  ```
- Effect: "Gold **24K**" / "Gold **24KT**" → "24K"/"24KT" renders in **Lora**, "Gold" stays in PlayfairDisplay
- **Global change** — affects every screen using `NumericStyledText`

---

### 6. `lib/features/sip/screens/auto_savings_screen.dart`
**Purpose:** Apply NumericStyledText to commodity labels

**Changes:**
- Added `import '../../../shared/widgets/numeric_styled_text.dart';`
- Plan card title (line ~328): `Text` → `NumericStyledText` for "You've already subscribed to a Daily Gold 24K Auto-Savings plan"
- Commodity radio label (line ~800): `Text` → `NumericStyledText` for `commodity.name` (e.g., "Gold 24K")

---

### 7. `lib/features/sip/apis.md`
**Purpose:** Document Auto Savings Overview screen behaviour

**Changes:**
- Added section: **"App Behaviour — Auto Savings Overview Screen (`SipOverviewScreen`)"**
- Page name, menu location, route, API used
- Screen behaviour table: Frequency Tabs, Invest Type Radio, Plan Card, No Plan State, Quick Actions
- Data flow: API → client-side filter by `frequency` + `commodity_name`
- Card field mapping table: Started On, Savings Amount, Frequency, Reference ID, Status

---

## ✅ Summary Table

| # | File | What Changed |
|---|------|-------------|
| 1 | `sip_overview_screen.dart` | ✨ NEW — Auto Savings dashboard (Profile → Auto Savings) |
| 2 | `app_router.dart` | `/sip-overview` route + import |
| 3 | `profile_screen.dart` | "Auto Savings" menu item before "SIP Transactions" |
| 4 | `sip_transaction_history_screen.dart` | Frequency tabs → pill style (matching Overview) |
| 5 | `numeric_styled_text.dart` | Regex: `K`, `T` added → "24K" renders fully in Lora |
| 6 | `auto_savings_screen.dart` | `NumericStyledText` for radio label + plan card title |
| 7 | `apis.md` | Auto Savings Overview screen behaviour documented |

> [!IMPORTANT]
> `NumericStyledText` regex change is global — "24K"/"24KT" now renders in Lora on **all** screens using this widget.

---
---

# All Changes — 2 May 2026 (Afternoon Session)

Toast UX fix (center positioning), scroll bottom-padding standardisation, HTML rupee entity normalisation, and full-app `₹` font audit.

---

## 📁 Files Changed (12 files)

---

### 1. `lib/shared/widgets/app_toast.dart`
**Purpose:** Ensure error toasts are always readable — even when the soft keyboard is open

**Changes:**
- Added `ToastPosition` enum: `bottom` | `center` | `top`
- **Default position changed to `ToastPosition.center`** — applies globally to every existing `AppToast.show()` call without touching individual files
- Added `FocusManager.instance.primaryFocus?.unfocus()` call before inserting overlay — keyboard is dismissed before toast appears
- `center` position uses `Positioned.fill` + `Align(alignment: Alignment(0, -0.2))` — sits in screen's visual centre regardless of IME inset
- Slide animation direction adapts to position (bottom ↑, top ↓, center slight ↑)
- Kept `showAtBottom` bool param for backward compatibility (ignored when `position` enum is passed explicitly)
- All `withOpacity()` calls migrated to `withValues(alpha:)` (deprecation fix)

---

### 2. `lib/features/withdrawal/screens/withdrawal_screen.dart`
**Purpose:** Error toasts explicitly set to center (now redundant but documents intent)

**Changes:**
- Policy validation error toast: added `position: ToastPosition.center`
- API error catch toast: added `position: ToastPosition.center`

---

### 3. `lib/features/withdrawal/screens/withdrawal_confirmation_screen.dart`
**Purpose:** All error/warning toasts set to center for keyboard-safe visibility

**Changes:**
- "Missing required information" warning toast: added `position: ToastPosition.center`
- API error response toast: added `position: ToastPosition.center`
- API catch error toast: added `position: ToastPosition.center`

---

### 4. `lib/features/instant_saving/instant_saving_screen.dart`
**Purpose:** Error toasts set to center for keyboard-safe visibility

**Changes:**
- "Market rates not ready" warning toast: added `position: ToastPosition.center`
- Catch-all error toast: added `position: ToastPosition.center`

---

### 5. `lib/features/sip/screens/sip_transaction_history_screen.dart`
**Purpose:** Bottom scroll padding — last card no longer clips at screen edge

**Changes:**
- `_buildList()` `ListView.builder` padding: `bottom: 120.h` → `bottom: 140.h`

---

### 6. `lib/features/sip/screens/sip_transaction_details_screen.dart`
**Purpose:** Bottom scroll padding — expandable "SIP Order Details" card was flush with screen edge

**Changes:**
- `_buildContent()` `SingleChildScrollView` padding: `EdgeInsets.symmetric(vertical: 16.h)` → `EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h)`

---

### 7. `lib/features/content/screens/content_screen.dart`
**Purpose:** (1) Scroll bottom padding; (2) Rupee HTML entity normalisation

**Changes:**
- `SingleChildScrollView` bottom padding: `32.h` → `80.h`
- `_wrapNumericsInText()`: added `text.replaceAll('&#8377;', '₹')` before regex — rupee sent as HTML entity by server now correctly renders in **Lora**

---

### 8. `lib/features/content/screens/faq_screen.dart`
**Purpose:** (1) Scroll bottom padding; (2) Rupee HTML entity normalisation

**Changes:**
- `ListView.builder` bottom padding: `32.h` → `80.h`
- `_wrapNumericsInText()`: same `&#8377;` → `₹` normalisation as `content_screen.dart`

---

### 9. `lib/features/home/widgets/micro_savings_banner.dart`
**Purpose:** `₹` coin thumb font — Playfair Display → Lora

**Changes:**
- `_buildSwipeTrack()` thumb `Text('₹')` style: `GoogleFonts.playfairDisplay(...)` → `GoogleFonts.lora(...)`

---

### 10. `lib/features/home/home_screen.dart`
**Purpose:** `₹` coin GIF error-fallback font — system default → Lora

**Changes:**
- `_buildLiveRatePill()` coin `errorBuilder` fallback `Text('₹')` style: `TextStyle(...)` → `GoogleFonts.lora(...)`

---

### 11. `lib/routes/app_router.dart`
**Purpose:** Payment loading screen `₹` amount — system default → Lora

**Changes:**
- Added `import 'package:google_fonts/google_fonts.dart';`
- "Completing Payment for ₹..." `Text` style: `const TextStyle(...)` → `GoogleFonts.lora(...)`

---

## 🔍 Full `₹` Font Audit — All Clear

Verified every `₹` occurrence across the entire codebase:

| File | Context | Font | Status |
|------|---------|------|--------|
| `micro_savings_banner.dart` | Swipe thumb coin | `GoogleFonts.lora` | ✅ Fixed |
| `home_screen.dart` | `₹10` RichText banner | `fontFamily: 'Lora'` | ✅ |
| `home_screen.dart` | Coin GIF error fallback | `GoogleFonts.lora` | ✅ Fixed |
| `home_screen.dart` | Chart rate labels `₹rate/g` | `NumericStyledText` → auto-Lora | ✅ |
| `withdrawal_screen.dart` | `₹` prefix input | `GoogleFonts.lora` | ✅ |
| `instant_saving_screen.dart` | `₹` prefix + totals | `GoogleFonts.lora` | ✅ |
| `manage_savings_screen.dart` | `₹amount` detail row | `GoogleFonts.lora` (via `_buildDetailRow`) | ✅ |
| `sip_transaction_history_screen.dart` | `₹amount` card | `GoogleFonts.lora` | ✅ |
| `sip_transaction_details_screen.dart` | `₹amount`, `₹scheme` | `GoogleFonts.lora` | ✅ |
| `app_router.dart` | Payment loading text | `GoogleFonts.lora` | ✅ Fixed |
| `content_screen.dart` / `faq_screen.dart` | HTML `&#8377;` entity | Lora span injection | ✅ Fixed |

---

## ✅ Summary Table

| # | File | What Changed |
|---|------|-------------|
| 1 | `app_toast.dart` | `ToastPosition` enum; default → `center`; keyboard auto-dismiss |
| 2 | `withdrawal_screen.dart` | Error toasts → `position: ToastPosition.center` |
| 3 | `withdrawal_confirmation_screen.dart` | All toasts → `position: ToastPosition.center` |
| 4 | `instant_saving_screen.dart` | Error toasts → `position: ToastPosition.center` |
| 5 | `sip_transaction_history_screen.dart` | List bottom padding `120.h` → `140.h` |
| 6 | `sip_transaction_details_screen.dart` | Scroll bottom padding `16.h` → `80.h` |
| 7 | `content_screen.dart` | Bottom padding `32.h` → `80.h`; `&#8377;` → `₹` normalisation |
| 8 | `faq_screen.dart` | Bottom padding `32.h` → `80.h`; `&#8377;` → `₹` normalisation |
| 9 | `micro_savings_banner.dart` | `₹` coin thumb: Playfair → **Lora** |
| 10 | `home_screen.dart` | `₹` GIF fallback: `TextStyle` → **`GoogleFonts.lora`** |
| 11 | `app_router.dart` | Payment screen `₹` amount: `TextStyle` → **`GoogleFonts.lora`** |

> [!IMPORTANT]
> `AppToast` default position is now `center` — **all screens app-wide** automatically show toasts in the visual center. No per-screen changes needed. To opt out, pass `position: ToastPosition.bottom` explicitly.

> [!NOTE]
> Rupee symbol `₹` is now correctly rendered in **Lora** across 100% of the app, covering both direct `Text()` widgets and HTML content from the server (entity form `&#8377;` normalised before Lora span injection).

---
---

# All Changes — 4 May 2026

Home page commodity toggle redesign (pill-style matching Instant Saving), and global 409 session-invalidated handling with premium dialog.

---

## 📁 Files Changed (3 files)

---

### 1. `lib/features/home/home_screen.dart`
**Purpose:** Replace iOS-style switch toggle with pill-style Gold/Silver buttons matching Instant Saving page

**Changes:**
- **`_buildCommodityToggle()`** — fully rewritten:
  - Before: `Row` with `Text("Gold")` → gradient switch knob → `Text("Silver")`
  - After: Pill `Container` with `Colors.white.withValues(alpha: 0.12)` background, `100.r` radius, wrapping two `_buildCommodityPillTab()` buttons
  - `mainAxisSize: MainAxisSize.min` — pill auto-sizes to content width
  - Referral message and market-closed banner logic unchanged
- **New `_buildCommodityPillTab()`** method added:
  - `AnimatedContainer` with 200ms transition
  - **Gold active gradient**: 6-stop amber (`0xFFEF9B00` → `0xFFE78400`) — identical to `instant_saving_screen.dart` `_buildTabItem()`
  - **Silver active gradient**: 7-stop silver (`0xFFABABAB` → `0xFFAFB1AE`) — identical to Instant Saving
  - **Inactive state**: transparent background, white text at `alpha: 0.7`
  - **Active text color**: Gold → `Color(0xFF5C3300)`, Silver → `Color(0xFF3D3D3D)`
  - **Box shadow**: `blurRadius: 10`, `offset: Offset(0, 4)` — gold amber or silver grey shadow
  - Padding: `horizontal: 28.w, vertical: 10.h`
- **`_buildPortfolioSkeleton()`** — commodity toggle placeholder updated:
  - Before: `Row` with `shimmerBlock(36.w)` + `shimmerPill(52.w)` + `shimmerBlock(42.w)`
  - After: Single `Center` → `headerShimmerPill(height: 40.h, width: 180.w)`
- Toggle used in **two places**: existing customer portfolio overview (line ~1411) and new customer banner (line ~1766) — both call `_buildCommodityToggle()` which now uses the new pill style

---

### 2. `lib/shared/widgets/session_invalidated_dialog.dart` ✨ NEW
**Purpose:** Premium full-screen dialog for 409 Conflict / `session_invalidated` — user logged in from another device

**Changes:**
- **`SessionInvalidatedDialog`** static class:
  - `show({String? message})` — entry point called from API interceptor
  - `_isShowing` guard flag — prevents stacking multiple dialogs from concurrent 409 responses
  - Calls `SessionManager.logout()` first to clear all secure storage (tokens, user info)
  - Uses `navigatorKey.currentContext` + `navigatorKey.currentState.mounted` check
  - Shows via `showGeneralDialog()` with 350ms transition
- **`_SessionInvalidatedOverlay`** widget:
  - **Frosted glass backdrop**: `BackdropFilter` with `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` + dark overlay at `alpha: 0.75`
  - **Slide + fade animation**: enters from `Offset(0, 0.15)` with `Curves.easeOutCubic`
  - **Dialog card**: white, `28.r` radius, dual box shadow (dark + subtle red glow)
  - **Shield icon**: 80r circle with gradient ring (`FFF1F0` → `FFE0DE`), inner 52r red gradient circle (`FF6B6B` → `E53935`), `Icons.shield_outlined`
  - **Title**: "Session Expired" in Playfair Display 20sp bold
  - **Device badge**: red pill with `Icons.devices_other_rounded` + "Logged in on another device"
  - **Message**: server-provided message or default fallback, Playfair Display 13sp
  - **Gradient divider**: transparent → `E2E8F0` → transparent
  - **"Log In Again" button**: green gradient (`1B882C` → `003716`), `Icons.login_rounded`, 16r radius
  - **Non-dismissible**: `PopScope(canPop: false)` blocks back button, `barrierDismissible: false`
  - Button calls `navigatorKey.currentState.pushNamedAndRemoveUntil(AppRouter.login, (route) => false)` — clears entire nav stack

---

### 3. `lib/core/security/api_interceptor.dart`
**Purpose:** Add 409 Conflict / `session_invalidated` detection in the global API error interceptor

**Changes:**
- Added `import 'package:flutter/widgets.dart';`
- Added `import '../../shared/widgets/session_invalidated_dialog.dart';`
- **`onError()`** — new block after existing 401 token-refresh handling (lines 209–225):
  - Checks `err.response?.statusCode == 409`
  - Parses `err.response.data['error']['code'] == 'session_invalidated'`
  - Extracts `data['error']['message']` as server message
  - Logs via `SecureLogger.e()`: `SESSION INVALIDATED: 409 Conflict — <message>`
  - Calls `WidgetsBinding.instance.addPostFrameCallback()` → `SessionInvalidatedDialog.show(message: serverMsg)`
  - `addPostFrameCallback` ensures dialog is shown safely outside the Dio async handler context

---

## 🔄 409 Session Invalidated Flow

```
Any authenticated API → Server returns 409 + {"error":{"code":"session_invalidated"}}
  ↓
ApiSecurityInterceptor.onError()
  ↓ detects statusCode == 409 && code == "session_invalidated"
  ↓
WidgetsBinding.addPostFrameCallback()
  ↓
SessionInvalidatedDialog.show(message: serverMsg)
  ↓
SessionManager.logout() → SecureStorageService.deleteAll()
  ↓
Premium frosted-glass dialog shown (non-dismissible)
  ↓
User taps "Log In Again"
  ↓
pushNamedAndRemoveUntil('/login') → entire nav stack cleared
```

---

## ✅ Summary Table

| # | File | What Changed |
|---|------|-------------|
| 1 | `home_screen.dart` | Gold/Silver toggle: iOS switch → pill buttons (matching Instant Saving gradients) |
| 2 | `session_invalidated_dialog.dart` | ✨ NEW — Premium 409 session-expired dialog with frosted backdrop + forced logout |
| 3 | `api_interceptor.dart` | 409 `session_invalidated` detection → shows dialog + clears session |

> [!IMPORTANT]
> The 409 handler is **global** — every API call in the app is now protected. If the user logs in from another device, the current session is immediately terminated with a premium non-dismissible dialog. No per-screen changes are needed.

> [!NOTE]
> The Gold/Silver pill toggle now uses the **exact same gradient colors** as the Instant Saving page's `_buildTabItem()` — ensuring visual consistency across the app.
