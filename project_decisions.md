# Project Architecture & Design Decisions

This document tracks key architectural and design decisions made for the SIP project to ensure consistency and scalability as the application grows.

---

## 🎨 Design System: "Midnight & Aurora"
**Date:** Feb 26, 2026
**Context:** The project needed a unique, premium identity that stands out from typical Fintech apps.
**Decision:** 
- Abandoned specific app clones (Gullak, Jar) in favor of a bespoke **"Midnight & Aurora"** theme.
- **Palette:** Deep Navy (`0xFF020617`), Arctic Blue, Aurora Purple, and Electric Cyan.
- **Typography:** Primary font set to **Google Fonts Outfit** for a modern, sophisticated look.
- **Visual Style:** Extensive use of **Glassmorphism** (BackdropFilter, blur, translucent containers) and animated background orbs to create depth.

## 🏗️ Architectural Pattern: Global Service Layer
**Date:** Feb 27, 2026
**Context:** Initial feature-based service structure led to fragmentation and difficulty in discovering API logic.
**Decision:**
- Centralized all business-logic services that interact with the API into the `lib/core/services/` directory.
- Features (Login, OTP, KYC) now purely handle UI/UX and delegate all network requests and logic (like token secure storage) to these global services.
- This ensures a single source of truth for API endpoints and data processing.

## 🛡️ Identity & Identity Management
**Date:** Feb 27, 2026
**Context:** Production-ready security requires real device and application telemetry.
**Decision:**
- Integrated `device_info_plus` to retrieve persistent, unique hardware IDs (e.g., Android ID, iOS IdentifierForVendor).
- Integrated `package_info_plus` to dynamically fetch application version and build numbers.
- **Secure Token Storage:** All access and refresh tokens are managed centrally in `AuthService` using `SecureStorageService` (wrapping `flutter_secure_storage`).

## 🧱 UI Component Strategy
**Date:** Feb 26, 2026
**Context:** Consistency across various screens (Authentication, Onboarding, KYC).
**Decision:**
- Created a standard `CustomButton` that respects the "Midnight & Aurora" design tokens and supports loading states.
- Implemented `FadeInAnimation` as a reusable kinetic wrapper to give the app a premium, fluid feel during page transitions.

---
*Last Updated: February 27, 2026*
