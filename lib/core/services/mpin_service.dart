import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

// --- SERVICE LAYER ---

class MpinService {
  final ApiClient _apiClient = ApiClient();

  /// Sets the MPIN on the server. Never stored locally.
  Future<void> setMpin(String mpin) async {
    await _apiClient.post(
      '/auth/set-mpin',
      data: {'mpin': mpin},
    );
  }

  /// Verifies the MPIN with the server.
  Future<bool> verifyMpin(String mpin) async {
    final response = await _apiClient.post(
      '/auth/verify-mpin',
      data: {'mpin': mpin},
    );
    return response.statusCode == 200;
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

  void clear() {
    state = MpinState();
  }
}

final mpinProvider = StateNotifierProvider<MpinNotifier, MpinState>((ref) {
  final service = ref.watch(mpinServiceProvider);
  return MpinNotifier(service);
});
