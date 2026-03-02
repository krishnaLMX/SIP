import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;
  final bool? isRegistered;

  AuthState({
    this.isLoading = false,
    this.error,
    this.data,
    this.isRegistered,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    bool? isRegistered,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      data: data ?? this.data,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState());

  Future<bool> sendOtp(String mobile, String countryCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.sendOtp(
        mobile: mobile,
        countryCode: countryCode,
      );
      state = state.copyWith(isLoading: false, data: data);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send OTP. Please try again.',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp, String otpSessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.verifyOtp(
        mobile: mobile,
        otp: otp,
        otpSessionId: otpSessionId,
      );
      state = state.copyWith(
        isLoading: false,
        isRegistered: data['isRegistered'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid or expired OTP. Please try again.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String mobile,
    required String name,
    required int age,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.register(
        mobile: mobile,
        name: name,
        age: age,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> setPin(String mobile, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.setPin(mobile: mobile, pin: pin);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set PIN. Please try again.',
      );
      return false;
    }
  }

  Future<bool> verifyPin(String mobile, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.verifyPin(mobile: mobile, pin: pin);
      state = state.copyWith(isLoading: false);
      if (!success) {
        state = state.copyWith(error: 'Incorrect PIN. Please try again.');
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'PIN verification failed. Please try again.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthController(service);
});
