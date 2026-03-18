import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

// --- SERVICE LAYER ---

class MpinService {
  final ApiClient _apiClient = ApiClient();

  /// Sets the MPIN on the server. Never stored locally.
  Future<void> setMpin(String mpin) async {
    await _apiClient.post(
      'mpin/create',
      data: {'mpin': mpin},
    );
  }

  /// Verifies the MPIN with the server.
  Future<bool> verifyMpin(String mpin) async {
    final response = await _apiClient.post(
      'mpin/validate',
      data: {'mpin': mpin},
    );
    return response.statusCode == 200;
  }

  /// Checks if the user already has an MPIN set on the backend.
  Future<bool> hasMpinSet() async {
    final response = await _apiClient.post('auth/has-mpin');
    return response.data['hasMpin'] ?? false;
  }
}

// --- STATE MANAGEMENT LAYER ---

final mpinServiceProvider = Provider<MpinService>((ref) => MpinService());

class MpinState {
  final String mpin;
  final bool isComplete;
  final bool isLoading;
  final String? error;

  final int failedAttempts;
  final bool isLocked;

  MpinState({
    this.mpin = '',
    this.isComplete = false,
    this.isLoading = false,
    this.error,
    this.failedAttempts = 0,
    this.isLocked = false,
  });

  MpinState copyWith({
    String? mpin,
    bool? isComplete,
    bool? isLoading,
    String? error,
    int? failedAttempts,
    bool? isLocked,
  }) {
    return MpinState(
      mpin: mpin ?? this.mpin,
      isComplete: isComplete ?? this.isComplete,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class MpinNotifier extends StateNotifier<MpinState> {
  final MpinService _mpinService;
  static const int pinLength = 4;

  MpinNotifier(this._mpinService) : super(MpinState());

  void addKey(String key) {
    if (state.mpin.length < pinLength) {
      final newMpin = state.mpin + key;
      state = state.copyWith(
        mpin: newMpin,
        isComplete: newMpin.length == pinLength,
      );
    }
  }

  void backspace() {
    if (state.mpin.isNotEmpty) {
      final newMpin = state.mpin.substring(0, state.mpin.length - 1);
      state = state.copyWith(
        mpin: newMpin,
        isComplete: false,
      );
    }
  }

  Future<bool> setMpin() async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mpinService.setMpin(state.mpin);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set security PIN. Try again.',
      );
      return false;
    }
  }

  Future<bool> verifyMpin() async {
    if (state.isLoading || state.isLocked) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _mpinService.verifyMpin(state.mpin);
      if (success) {
        state = state.copyWith(isLoading: false, failedAttempts: 0);
        return true;
      } else {
        final newAttempts = state.failedAttempts + 1;
        final isLocked = newAttempts >= 5;
        state = state.copyWith(
          isLoading: false,
          mpin: '',
          isComplete: false,
          failedAttempts: newAttempts,
          isLocked: isLocked,
          error: isLocked
              ? 'ACCOUNT LOCKED: Too many failed attempts. Contact support.'
              : 'Invalid PIN. $newAttempts/5 attempts used.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Validation failed. Check your connection.',
      );
      return false;
    }
  }

  void clear() {
    state = MpinState();
  }
}

final mpinProvider = StateNotifierProvider<MpinNotifier, MpinState>((ref) {
  final service = ref.watch(mpinServiceProvider);
  return MpinNotifier(service);
});
