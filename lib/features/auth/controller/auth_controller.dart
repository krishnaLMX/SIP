import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mpin_service.dart';

class AuthController extends AuthNotifier {
  AuthController(AuthService authService) : super(authService);

  /// Calls POST mpin/create — sets the MPIN after registration.
  Future<bool> setPin(String mobile, String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final mpinService = MpinService();
      await mpinService.setMpin(pin);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: msg.isNotEmpty ? msg : 'Failed to set PIN. Please try again.',
      );
      return false;
    }
  }

  /// Calls POST mpin/validate — verifies MPIN on login.
  Future<bool> verifyPin(String mobile, String pin) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final mpinService = MpinService();
      final success = await mpinService.verifyMpin(pin);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: msg.isNotEmpty ? msg : 'PIN verification failed. Please try again.',
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
