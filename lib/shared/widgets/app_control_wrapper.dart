import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_control_provider.dart';
import '../../routes/app_router.dart';
import '../../main.dart' show navigatorKey;
import '../widgets/offline_banner.dart';
import '../widgets/app_alert_banner.dart';

/// Root-level wrapper that injects global runtime controls:
///   • Offline / slow network banner
///   • Backend-driven alert banner
///   • Maintenance redirect (pushes /maintenance when flag becomes enabled while in-app)
///
/// NOTE: Version update dialog is handled exclusively by SplashScreen at
/// app startup. The 5-minute polling here is only for alerts and maintenance.
///
/// IMPORTANT: This widget sits ABOVE the Navigator (inside MaterialApp.builder),
/// so we must use [navigatorKey] to get a context that has a Navigator ancestor
/// for pushing routes.
class AppControlWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppControlWrapper({super.key, required this.child});

  @override
  ConsumerState<AppControlWrapper> createState() => _AppControlWrapperState();
}

class _AppControlWrapperState extends ConsumerState<AppControlWrapper> {
  bool _maintenanceRedirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControlProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appControl = ref.watch(appControlProvider);

    // ── Maintenance redirect while already inside the app ──────────────────
    if (appControl.isMaintenance && !_maintenanceRedirected) {
      _maintenanceRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = navigatorKey.currentState;
        if (mounted && nav != null) {
          nav.pushNamedAndRemoveUntil(
            AppRouter.maintenance,
            (route) => false,
            arguments: {'resumeRoute': AppRouter.login},
          );
        }
      });
    }
    // Reset so it can re-trigger if maintenance toggles again
    if (!appControl.isMaintenance) {
      _maintenanceRedirected = false;
    }

    return Stack(
      children: [
        // ── App content (fills entire space) ──────────────────────────
        Positioned.fill(child: widget.child),

        // ── Banners overlay on top (do NOT push content down) ─────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Offline / slow network banner
              const OfflineBanner(),

              // Live alert banner from backend
              if (appControl.showAlert && appControl.alert != null)
                AppAlertBanner(
                  alert: appControl.alert!,
                  onDismiss: () =>
                      ref.read(appControlProvider.notifier).dismissAlert(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
