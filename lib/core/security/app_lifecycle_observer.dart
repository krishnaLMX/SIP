import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';
import '../../routes/app_router.dart';
import '../providers/market_provider.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;
  final GlobalKey<NavigatorState> navigatorKey;
  DateTime? _backgroundTime;
  static const int lockTimeoutSeconds = 30;

  AppLifecycleObserver(this.ref, this.navigatorKey);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
      // Optimization: Pause Socket.IO when app goes to background
      ref.read(socketIOServiceProvider).disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // Security: Refresh Socket.IO on resume
      ref.read(socketIOServiceProvider).connect();
      if (_backgroundTime != null) {
        final difference =
            DateTime.now().difference(_backgroundTime!).inSeconds;
        final mpinEnabled = await SecureStorageService.isMpinEnabled();

        if (mpinEnabled && difference >= lockTimeoutSeconds) {
          _lockApp();
        }
      }
      _backgroundTime = null;
    }
  }

  void _lockApp() {
    // Navigate to MPIN screen if not already there
    final context = navigatorKey.currentContext;
    if (context != null) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != AppRouter.mpin &&
          currentRoute != AppRouter.login &&
          currentRoute != AppRouter.otp) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.mpin,
          (route) => false,
        );
      }
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
