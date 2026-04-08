import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline, slow }

class ConnectivityState {
  final ConnectivityStatus status;
  final bool isChecking;

  const ConnectivityState({
    this.status = ConnectivityStatus.online,
    this.isChecking = false,
  });

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;
  bool get isSlow => status == ConnectivityStatus.slow;

  ConnectivityState copyWith({ConnectivityStatus? status, bool? isChecking}) =>
      ConnectivityState(
        status: status ?? this.status,
        isChecking: isChecking ?? this.isChecking,
      );
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  StreamSubscription? _subscription;

  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  Future<void> _init() async {
    // Initial check
    await _check();

    // Listen to changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(
        status: hasConnection
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline,
      );
    });
  }

  Future<void> _check() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(
      status:
          hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline,
    );
  }

  Future<void> recheck() => _check();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);
