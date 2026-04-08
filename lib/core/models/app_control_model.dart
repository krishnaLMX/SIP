import 'dart:io';

/// Platform-specific version/alert payload
class PlatformMessage {
  final String title;
  final String message;
  final String buttonText;

  const PlatformMessage({
    required this.title,
    required this.message,
    required this.buttonText,
  });

  factory PlatformMessage.fromJson(Map<String, dynamic> json) =>
      PlatformMessage(
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        buttonText: json['button_text'] ?? 'Update',
      );
}

/// Version info returned by backend
class AppVersionInfo {
  final String latestVersion;
  final String minVersion;
  final String storeUrl;
  final bool forceUpdate;
  final PlatformMessage android;
  final PlatformMessage ios;

  const AppVersionInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.storeUrl,
    required this.forceUpdate,
    required this.android,
    required this.ios,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      latestVersion: json['latest_version'] ?? '',
      minVersion: json['min_version'] ?? '',
      storeUrl: json['store_url'] ?? '',
      forceUpdate: json['force_update'] == true,
      android: PlatformMessage.fromJson(
          (json['android'] as Map<String, dynamic>?) ?? {}),
      ios: PlatformMessage.fromJson(
          (json['ios'] as Map<String, dynamic>?) ?? {}),
    );
  }

  PlatformMessage get platformMessage =>
      Platform.isAndroid ? android : ios;
}

/// Live global alert banner
class AppAlert {
  final bool isActive;
  final String title;
  final String message;
  final String type; // "info" | "warning" | "maintenance"
  final String? actionUrl;
  final String? actionLabel;

  const AppAlert({
    required this.isActive,
    required this.title,
    required this.message,
    required this.type,
    this.actionUrl,
    this.actionLabel,
  });

  factory AppAlert.fromJson(Map<String, dynamic> json) => AppAlert(
        isActive: json['is_active'] == true,
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'info',
        actionUrl: json['action_url'],
        actionLabel: json['action_label'],
      );

  bool get isMaintenance => type == 'maintenance';
}

/// Maintenance mode — when enabled the entire app is blocked.
class MaintenanceInfo {
  final bool isEnabled;
  final String title;
  final String subtitle;
  final String? expectedResume;

  const MaintenanceInfo({
    required this.isEnabled,
    required this.title,
    required this.subtitle,
    this.expectedResume,
  });

  factory MaintenanceInfo.fromJson(Map<String, dynamic> json) =>
      MaintenanceInfo(
        isEnabled: json['is_enabled'] == true,
        title: json['title'] ?? 'Under Maintenance',
        subtitle: json['subtitle'] ??
            "We're upgrading our systems for a better experience.",
        expectedResume: json['expected_resume'],
      );

  static const MaintenanceInfo off = MaintenanceInfo(
    isEnabled: false,
    title: '',
    subtitle: '',
  );
}

/// Combined response from GET /app/control
class AppControlData {
  final AppVersionInfo? versionInfo;
  final AppAlert? alert;
  final MaintenanceInfo maintenance;

  const AppControlData({
    this.versionInfo,
    this.alert,
    this.maintenance = MaintenanceInfo.off,
  });

  factory AppControlData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AppControlData(
      versionInfo: data.containsKey('version')
          ? AppVersionInfo.fromJson(data['version'])
          : null,
      alert: data.containsKey('alert') && data['alert'] != null
          ? AppAlert.fromJson(data['alert'])
          : null,
      maintenance: data.containsKey('maintenance') && data['maintenance'] != null
          ? MaintenanceInfo.fromJson(data['maintenance'])
          : MaintenanceInfo.off,
    );
  }
}
