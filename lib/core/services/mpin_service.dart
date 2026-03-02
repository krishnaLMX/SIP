import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/secure_storage_service.dart';

// --- SERVICE LAYER ---

class MpinService {
  /// Sets the MPIN locally in secure storage.
  Future<void> setMpin(String mpin) async {
    // Mocking server sync
    await Future.delayed(const Duration(seconds: 1));
    await SecureStorageService.saveMpin(mpin);
    await SecureStorageService.setMpinEnabled(true);
  }

  /// Verifies the MPIN from secure storage.
  Future<bool> verifyMpin(String mpin) async {
    // Mocking server validation
    await Future.delayed(const Duration(seconds: 1));
    final savedMpin = await SecureStorageService.getMpin();
    return savedMpin == mpin;
  }
}

// --- STATE MANAGEMENT LAYER ---

final mpinServiceProvider = Provider<MpinService>((ref) => MpinService());

class MpinState {
  final String mpin;
  final bool isComplete;
  final bool isLoading;
  final String? error;

  MpinState({
    this.mpin = '',
    this.isComplete = false,
    this.isLoading = false,
    this.error,
  });

  MpinState copyWith({
    String? mpin,
    bool? isComplete,
    bool? isLoading,
    String? error,
  }) {
    return MpinState(
      mpin: mpin ?? this.mpin,
      isComplete: isComplete ?? this.isComplete,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isValid = await _mpinService.verifyMpin(state.mpin);
      if (isValid) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Incorrect PIN. Verification failed.',
          mpin: '',
          isComplete: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Technical error. Please try again.',
        mpin: '',
        isComplete: false,
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
