1️⃣ Project Identity
This is a fintech-grade Flutter mobile application.
Security-first architecture is mandatory.
All authentication and financial logic must be server-driven.
2️⃣ Folder Structure Rule (Mandatory)

Define your structure strictly:

Follow this folder structure exactly:
- core/
- features/
- shared/
- routes/

And:

Never mix UI and API logic in same file.
Never place business logic inside UI layer.
3️⃣ Security Rules (Very Important)

Add:

SECURITY STANDARDS:

- Use flutter_secure_storage for tokens.
- Never store MPIN locally.
- Never hardcode secrets.
- Implement Dio interceptors.
- Prepare certificate pinning.
- Handle 401 globally.
- No sensitive logs in release mode.
- Root detection required.
4️⃣ API Architecture Rules
All API calls must go through api_client.dart.
Use Dio.
Add request and response interceptors.
Do not call APIs directly from UI files.
5️⃣ Navigation Rules
Navigation must be centralized in routes/app_router.dart.
Do not use Navigator.push directly inside UI.
Use named routes or router-based navigation.
6️⃣ UI Design Standards
Premium fintech minimal UI.
Jar-style clean layout.
Rounded corners.
Smooth transitions.
Dark & Light theme support.
Responsive design.
7️⃣ State Management Rule

If you choose Riverpod or Bloc:

Use Riverpod for state management.
Do not use setState for business logic.
Keep UI reactive and clean.
🏆 Example brain.md for Your App

You can literally put this:

brain.md

This project is a production-grade fintech Flutter mobile application.

ARCHITECTURE:

Clean architecture required.

Strict separation of UI, business logic, and network layers.

Folder structure must be followed exactly as defined.

SECURITY:

Tokens must be stored using flutter_secure_storage only.

MPIN must never be stored locally.

All authentication must be validated by server.

Implement Dio interceptors.

Prepare certificate pinning.

No hardcoded API keys.

No sensitive logging.

Root/jailbreak detection required.

Disable screenshots on OTP and MPIN screens.

NETWORK:

All APIs must go through api_client.dart.

Use centralized interceptor handling.

Handle 401 responses globally.

Use short-lived access tokens with refresh flow support.

NAVIGATION:

Use centralized routing in routes/app_router.dart.

Do not use direct Navigator.push in UI files.

UI:

Premium fintech minimal design.

Jar-style inspiration.

Responsive layout.

Dark and light theme support.

GOAL:
Build a secure, scalable, VAPT-ready fintech authentication system.