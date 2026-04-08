import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';

/// Observes app lifecycle to manage socket connection.
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
