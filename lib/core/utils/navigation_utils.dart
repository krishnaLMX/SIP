import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../security/session_manager.dart';
import '../security/secure_storage_service.dart';

/// Navigation helper utilities.
///
/// Provides safe-pop behaviour: if the navigator has a previous route
/// to go back to, pop normally; otherwise fall back to the appropriate
/// screen so the user never sees a "Page Not Found" error.
///
/// • Authenticated users → MPIN screen (re-verify identity)
/// • Unauthenticated users → Login screen
class NavigationUtils {
  NavigationUtils._();

  /// Pops the current route if possible, otherwise navigates to the
  /// correct fallback screen (clearing the stack).
  ///
  /// Use this instead of `Navigator.pop(context)` on screens that might
  /// be the only route in the navigator stack (e.g. OTP reached via
  /// `pushReplacementNamed` from the Forgot PIN flow).
  static void safePop(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _navigateToFallback(context);
    }
  }

  /// Determines the correct fallback based on auth state:
  /// - Logged in with MPIN → go to MPIN
  /// - Otherwise → go to Login
  static Future<void> _navigateToFallback(BuildContext context) async {
    String fallbackRoute = AppRouter.login;
    try {
      final loggedIn = await SessionManager.isAuthenticated();
      final mpinEnabled = await SecureStorageService.isMpinEnabled();
      if (loggedIn && mpinEnabled) {
        fallbackRoute = AppRouter.mpin;
      }
    } catch (_) {
      // On error, default to login for safety
    }
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        fallbackRoute,
        (route) => false,
      );
    }
  }
}
