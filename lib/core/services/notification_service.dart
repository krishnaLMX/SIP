import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../security/secure_storage_service.dart';
import 'device_id_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      isRead: (json['is_read'] == true || json['is_read'] == 1),
      createdAt: json['created_at'] ?? '',
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  final ApiClient _api = ApiClient();

  /// GET /notifications — fetch full notification list.
  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _api.post('users/notifications');
    final data = response.data;
    if (data != null && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /notifications/read — mark a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    await _api.post('users/notifications/read',
        data: {'notification_id': notificationId});
  }

  /// POST /notifications/read-all — mark all notifications as read.
  Future<void> markAllAsRead() async {
    await _api.post('users/notifications/read-all');
  }

  /// POST /notifications/delete — delete a single notification.
  Future<void> deleteNotification(int notificationId) async {
    await _api.post('users/notifications/delete',
        data: {'notification_id': notificationId});
  }

  /// POST /notifications/unread-count — get badge number.
  Future<int> fetchUnreadCount() async {
    final response = await _api.post('users/notifications/unread-count');
    final data = response.data;
    if (data != null && data['data'] != null) {
      return (data['data']['count'] ?? 0) as int;
    }
    return 0;
  }

  // ── FCM Token Registration ──────────────────────────────────────────────

  /// POST users/notifications/register-token
  /// Registers the FCM device token + device_id so the server
  /// knows which physical device to target for push notifications.
  ///
  /// device_id comes from DeviceIdService — guaranteed non-null.
  /// Only sends when the token has changed (SecureStorage dedup).
  Future<void> registerFcmToken(String token) async {
    try {
      final storedToken = await SecureStorageService.getFcmToken();
      if (storedToken == token) {
        debugPrint('[FCM] Token unchanged — skipping registration.');
        return;
      }

      final deviceId = await DeviceIdService.getDeviceId();
      final deviceType = await DeviceIdService.getDeviceType();
      final deviceInfo = await DeviceIdService.getDeviceInfo();

      await _api.post('users/notifications/register-token', data: {
        'fcm_token': token,
        'device_id': deviceId,
        'device_type': deviceType,
        'device_model': deviceInfo['device_model'],
        'device_name': deviceInfo['device_name'],
        'os': deviceInfo['os'],
        'os_version': deviceInfo['os_version'],
      });

      await SecureStorageService.saveFcmToken(token);
      debugPrint('[FCM] Token registered — device: $deviceId ($deviceType) '
          'model: ${deviceInfo['device_model']} '
          'os: ${deviceInfo['os']} ${deviceInfo['os_version']}');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

// ── State notifier ────────────────────────────────────────────────────────────

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  int get computedUnread => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(const NotificationState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.fetchNotifications();
      final unread = list.where((n) => !n.isRead).length;
      state = state.copyWith(
          notifications: list, isLoading: false, unreadCount: unread);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      // Optimistic update — mark locally immediately
      final updated = state.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    } catch (_) {
      // Silently fail — list is still accurate from last load
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      // Optimistic update — mark all locally
      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _service.deleteNotification(id);
      // Optimistic: remove from list
      final updated =
          state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    } catch (_) {}
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _service.fetchUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.read(notificationServiceProvider));
});

/// Lightweight provider just for the badge count (used in nav bar / home).
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
