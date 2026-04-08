import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_control_model.dart';
import '../services/app_control_service.dart';

// ─── Intervals ────────────────────────────────────────────────────────────────
const _kAlertPollInterval = Duration(minutes: 5);
const _kMaintenancePollInterval = Duration(minutes: 2); // faster while in maintenance

class AppControlState {
  final AppControlData? data;
  final bool isLoading;
  final bool updateRequired;
  final bool forceUpdate;
  final bool showAlert;
  final bool isMaintenance;
  final String currentVersion;

  const AppControlState({
    this.data,
    this.isLoading = false,
    this.updateRequired = false,
    this.forceUpdate = false,
    this.showAlert = false,
    this.isMaintenance = false,
    this.currentVersion = '',
  });

  AppAlert? get alert => data?.alert;
  AppVersionInfo? get versionInfo => data?.versionInfo;
  MaintenanceInfo? get maintenanceInfo => data?.maintenance;

  AppControlState copyWith({
    AppControlData? data,
    bool? isLoading,
    bool? updateRequired,
    bool? forceUpdate,
    bool? showAlert,
    bool? isMaintenance,
    String? currentVersion,
  }) =>
      AppControlState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        updateRequired: updateRequired ?? this.updateRequired,
        forceUpdate: forceUpdate ?? this.forceUpdate,
        showAlert: showAlert ?? this.showAlert,
        isMaintenance: isMaintenance ?? this.isMaintenance,
        currentVersion: currentVersion ?? this.currentVersion,
      );
}

class AppControlNotifier extends StateNotifier<AppControlState> {
  final AppControlService _service;
  Timer? _pollTimer;
  Timer? _maintenancePollTimer;

  AppControlNotifier(this._service) : super(const AppControlState());

  /// Call once at app startup and begin periodic alert refresh
  Future<void> initialize() async {
    await _fetch();
    _startPolling();
  }

  /// Faster polling while maintenance screen is showing.
  /// Automatically stops when maintenance is lifted.
  void startMaintenancePolling() {
    _maintenancePollTimer?.cancel();
    _maintenancePollTimer =
        Timer.periodic(_kMaintenancePollInterval, (_) => _fetch());
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_kAlertPollInterval, (_) => _fetch());
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true);

    try {
      final raw = await _service.fetchAppControl();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (raw == null) {
        state = state.copyWith(isLoading: false, currentVersion: currentVersion);
        return;
      }

      final controlData = AppControlData.fromJson(raw);
      final versionInfo = controlData.versionInfo;
      final maintenance = controlData.maintenance;

      // ── Maintenance takes priority over everything ──
      if (maintenance.isEnabled) {
        state = state.copyWith(
          data: controlData,
          isLoading: false,
          isMaintenance: true,
          currentVersion: currentVersion,
        );
        return;
      }

      // ── Maintenance was lifted — stop fast polling ──
      if (state.isMaintenance && !maintenance.isEnabled) {
        _maintenancePollTimer?.cancel();
        _maintenancePollTimer = null;
      }

      // ── Version check ──
      bool updateRequired = false;
      bool forceUpdate = false;

      if (versionInfo != null && currentVersion.isNotEmpty) {
        updateRequired = _isLower(currentVersion, versionInfo.latestVersion);
        forceUpdate = versionInfo.forceUpdate ||
            _isLower(currentVersion, versionInfo.minVersion);
      }

      final alert = controlData.alert;
      final showAlert = alert != null && alert.isActive;

      state = state.copyWith(
        data: controlData,
        isLoading: false,
        updateRequired: updateRequired,
        forceUpdate: forceUpdate,
        showAlert: showAlert,
        isMaintenance: false,
        currentVersion: currentVersion,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void dismissUpdate() {
    if (!state.forceUpdate) {
      state = state.copyWith(updateRequired: false);
    }
  }

  void dismissAlert() {
    state = state.copyWith(showAlert: false);
  }

  Future<void> refresh() => _fetch();

  /// Compare semantic versions: returns true if [a] < [b]
  bool _isLower(String a, String b) {
    try {
      final av = a.split('.').map(int.parse).toList();
      final bv = b.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final ai = i < av.length ? av[i] : 0;
        final bi = i < bv.length ? bv[i] : 0;
        if (ai < bi) return true;
        if (ai > bi) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _maintenancePollTimer?.cancel();
    super.dispose();
  }
}

final _appControlServiceProvider =
    Provider<AppControlService>((ref) => AppControlService());

final appControlProvider =
    StateNotifierProvider<AppControlNotifier, AppControlState>(
  (ref) => AppControlNotifier(ref.read(_appControlServiceProvider)),
);
