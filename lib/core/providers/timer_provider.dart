import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/market/models/market_rates.dart';
import 'market_provider.dart';

import 'package:flutter/widgets.dart';

class TimerState {
  final int remainingSeconds;
  final MarketRates? lockedRates;

  TimerState({
    required this.remainingSeconds,
    this.lockedRates,
  });

  bool get isActive => remainingSeconds > 0 && lockedRates != null;
}

class RateTimerNotifier extends StateNotifier<TimerState> with WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;
  int _totalDuration = 0;
  DateTime? _targetEndTime;

  RateTimerNotifier(this.ref) : super(TimerState(remainingSeconds: 0)) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force an immediate recalculation of the timer when app reopens
      _evaluateTimer();
    }
  }

  void startOrRefresh(int durationSeconds) {
    if (durationSeconds <= 0) return;
    _totalDuration = durationSeconds;
    
    // Capture and lock the current rates
    final currentRates = ref.read(marketRatesStreamProvider).valueOrNull;
    if (currentRates == null) return;

    _timer?.cancel();
    _targetEndTime = DateTime.now().add(Duration(seconds: _totalDuration));
    state = TimerState(remainingSeconds: _totalDuration, lockedRates: currentRates);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _evaluateTimer();
    });
  }

  void _evaluateTimer() {
    if (_targetEndTime == null || state.lockedRates == null) return;
    
    final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;
    
    if (remaining > 0) {
      state = TimerState(
        remainingSeconds: remaining,
        lockedRates: state.lockedRates,
      );
    } else {
      // Expired -> refresh to latest and restart
      _timer?.cancel();
      _targetEndTime = null;
      _refreshAndRestart();
    }
  }

  void _refreshAndRestart() {
    startOrRefresh(_totalDuration);
  }

  void clear() {
    _timer?.cancel();
    _targetEndTime = null;
    state = TimerState(remainingSeconds: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final sellRateTimerProvider = StateNotifierProvider<RateTimerNotifier, TimerState>((ref) {
  return RateTimerNotifier(ref);
});

final buyRateTimerProvider = StateNotifierProvider<RateTimerNotifier, TimerState>((ref) {
  return RateTimerNotifier(ref);
});

