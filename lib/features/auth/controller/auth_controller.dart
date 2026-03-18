import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

class AuthController extends AuthNotifier {
  AuthController(AuthService authService) : super(authService);

  // You can add extra feature-specific logic here if needed

  Future<bool> setPin(String mobile, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // simulate network
      await Future.delayed(const Duration(seconds: 1));
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
      // simulate network
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'PIN verification failed. Please try again.',
      );
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthController(service);
});
