import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_control_provider.dart';
import '../../routes/app_router.dart';
import '../../main.dart' show navigatorKey;
import '../widgets/offline_banner.dart';
import '../widgets/app_alert_banner.dart';
import '../widgets/app_update_dialog.dart';

/// Root-level wrapper that injects global runtime controls:
///   • Offline / slow network banner
///   • Backend-driven alert banner
///   • Maintenance redirect (pushes /maintenance when flag becomes enabled while in-app)
///   • Version update dialog (shows blocking update when detected mid-session)
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
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Primary initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControlProvider.notifier).initialize();
    });
    // Safety net — retry after 3s in case the first call didn't fire
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(appControlProvider.notifier).ensureInitialized();
      }
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

    // ── Version update dialog (shows on ANY page when detected) ────────────
    // Skip if already shown, or if we're still on the splash screen
    // (splash handles its own dialog to avoid double-showing).
    if (appControl.updateRequired && !_updateDialogShown) {
      _updateDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = navigatorKey.currentContext;
        if (!mounted || navContext == null) {
          _updateDialogShown = false;
          return;
        }

        // Don't show if user is still on splash (splash has its own dialog)
        final currentRoute = ModalRoute.of(navContext)?.settings.name;
        if (currentRoute == AppRouter.splash) {
          _updateDialogShown = false;
          return;
        }

        final versionInfo = appControl.versionInfo;
        if (versionInfo != null) {
          AppUpdateDialog.show(
            navContext,
            versionInfo: versionInfo,
            forceUpdate: appControl.forceUpdate,
          );
        } else {
          _updateDialogShown = false;
        }
      });
    }
    // Reset flag if update is no longer required (e.g. user updated)
    if (!appControl.updateRequired) {
      _updateDialogShown = false;
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
          child: SafeArea(
            bottom: false,
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
        ),
      ],
    );
  }
}
