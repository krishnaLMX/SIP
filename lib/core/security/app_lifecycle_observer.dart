import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';
import '../security/session_manager.dart';
import '../security/secure_logger.dart';
import '../network/api_client.dart';

/// Observes app lifecycle to manage socket connection and session validation.
/// NOTE: MPIN auto-lock is temporarily disabled.
/// It will be re-added with proper payment gateway awareness.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;
  final GlobalKey<NavigatorState> navigatorKey;

  AppLifecycleObserver(this.ref, this.navigatorKey);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Pause socket when app goes to background
      ref.read(socketIOServiceProvider).disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // Reconnect socket when app comes back to foreground
      ref.read(socketIOServiceProvider).connect();

      // ── Session validation on resume ──────────────────────────────────
      // When the app returns from background, make a lightweight API call
      // to verify the session is still valid. If the server returns 409,
      // the interceptor will handle it automatically.
      _validateSessionOnResume();
    }
  }

  /// Validates the current session by making a lightweight API call.
  /// If the session was invalidated while the app was in the background
  /// (e.g. user logged in on another device), the interceptor's 409
  /// handler will trigger the force-logout dialog automatically.
  Future<void> _validateSessionOnResume() async {
    // Skip if already force-logged-out or not authenticated
    if (SessionManager.isForceLoggedOut) return;

    final isAuth = await SessionManager.isAuthenticated();
    if (!isAuth) return;

    try {
      // Use a lightweight endpoint to validate session.
      // The interceptor will handle 409 automatically.
      final apiClient = ApiClient();
      await apiClient.get('users/auth/session-check');
      SecureLogger.d('SESSION CHECK: Session is valid (resume).');
    } catch (e) {
      // Errors are handled by the interceptor (409 → force logout).
      // Other errors (network, 500, etc.) are silently ignored here
      // since they don't indicate session invalidation.
      SecureLogger.d('SESSION CHECK: Validation skipped or failed ($e).');
    }
  }
}

final lifecycleObserverProvider =
    Provider.family<AppLifecycleObserver, GlobalKey<NavigatorState>>(
        (ref, navigatorKey) {
  final observer = AppLifecycleObserver(ref, navigatorKey);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return observer;
});
