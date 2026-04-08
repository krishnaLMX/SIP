import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_control_provider.dart';
import '../../routes/app_router.dart';
import '../widgets/offline_banner.dart';
import '../widgets/app_alert_banner.dart';
import '../widgets/app_update_dialog.dart';

/// Root-level wrapper that injects global runtime controls:
///   • Offline / slow network banner
///   • Backend-driven alert banner
///   • App version update dialog (force / optional)
///   • Maintenance redirect (pushes /maintenance when flag becomes enabled while in-app)
class AppControlWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppControlWrapper({super.key, required this.child});

  @override
  ConsumerState<AppControlWrapper> createState() => _AppControlWrapperState();
}

class _AppControlWrapperState extends ConsumerState<AppControlWrapper> {
  bool _updateDialogShown = false;
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
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
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

    // ── Update dialog (once per session) ──────────────────────────────────
    if (appControl.updateRequired && !_updateDialogShown) {
      _updateDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && appControl.versionInfo != null) {
          AppUpdateDialog.show(
            context,
            versionInfo: appControl.versionInfo!,
            forceUpdate: appControl.forceUpdate,
            onDismiss: () =>
                ref.read(appControlProvider.notifier).dismissUpdate(),
          );
        }
      });
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
