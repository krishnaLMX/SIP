import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../security/secure_storage_service.dart';

// --- SERVICE LAYER ---

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_id';
      }
    } catch (e) {
      return 'placeholder_id';
    }
    return 'placeholder_id';
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  Future<Map<String, dynamic>> sendOtp({
    required String mobile,
    required String countryCode,
  }) async {
    final deviceId = await _getDeviceId();
    final appVersion = await _getAppVersion();

    final response = await _apiClient.post(
      '/auth/send-otp',
      data: {
        'mobile': mobile,
        'countryCode': countryCode,
        'deviceId': deviceId,
        'appVersion': appVersion,
      },
    );
    return response.data;
  }

  Future<void> verifyOtp({
    required String mobile,
    required String otp,
    required String otpSessionId,
  }) async {
    final deviceId = await _getDeviceId();

    final response = await _apiClient.post(
      '/auth/verify-otp',
      data: {
        'mobile': mobile,
        'otp': otp,
        'otpSessionId': otpSessionId,
        'deviceId': deviceId,
      },
    );

    if (response.data != null) {
      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      if (accessToken != null) {
        await SecureStorageService.saveToken(accessToken);
      }
      if (refreshToken != null) {
        await SecureStorageService.saveRefreshToken(refreshToken);
      }
    }
  }
}

// --- STATE MANAGEMENT LAYER ---

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  AuthState({this.isLoading = false, this.error, this.data});

  AuthState copyWith(
      {bool? isLoading, String? error, Map<String, dynamic>? data}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      data: data ?? this.data,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  Future<bool> sendOtp(String mobile, String countryCode) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data =
          await _authService.sendOtp(mobile: mobile, countryCode: countryCode);
      state = state.copyWith(isLoading: false, data: data);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to send OTP. Please try again.');
      return false;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp, String otpSessionId) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.verifyOtp(
        mobile: mobile,
        otp: otp,
        otpSessionId: otpSessionId,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Invalid or expired OTP. Please try again.');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});
