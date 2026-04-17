import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/market/models/market_rates.dart';
import 'market_provider.dart';

import 'package:flutter/widgets.dart';

class TimerState {
  final int remainingSeconds;
  final MarketRates? lockedRates;
  final bool isMarketClosed;

  TimerState({
    required this.remainingSeconds,
    this.lockedRates,
    this.isMarketClosed = false,
  });

  bool get isActive =>
      remainingSeconds > 0 && lockedRates != null && !isMarketClosed;
}

class RateTimerNotifier extends StateNotifier<TimerState>
    with WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;
  int _totalDuration = 0;
  DateTime? _targetEndTime;

  /// Recorded when the timer starts each cycle.
  /// Used to detect if ANY new rate arrived during the window.
  DateTime? _timerStartTime;

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
    _timerStartTime = DateTime.now(); // ← record when this cycle started
    _targetEndTime = DateTime.now().add(Duration(seconds: _totalDuration));
    state =
        TimerState(remainingSeconds: _totalDuration, lockedRates: currentRates);

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
    final latestRate = ref.read(marketRatesStreamProvider).valueOrNull;

    // ── Market closed detection ────────────────────────────────────────
    // If no NEW rate arrived during the entire timer window, the market
    // is closed. We detect this by comparing the rate's timestamp against
    // when THIS timer cycle started (_timerStartTime).
    //
    // Example:
    //   Timer started at 12:00:00 (locked ₹15,000)
    //   Market closed at 12:00:40 — socket goes silent
    //   Timer expires at 12:01:20
    //   latestRate.timestamp = 12:00:40 < _timerStartTime ← CAUGHT ✅
    if (latestRate != null && _timerStartTime != null) {
      if (!latestRate.timestamp.isAfter(_timerStartTime!)) {
        // No new rate came in during the 80s window → market closed
        _timer?.cancel();
        _targetEndTime = null;
        state = TimerState(
          remainingSeconds: 0,
          lockedRates: null,
          isMarketClosed: true,
        );
        return;
      }
    }

    // Fresh rate arrived during the window — safe to restart
    startOrRefresh(_totalDuration);
  }

  void clear() {
    _timer?.cancel();
    _targetEndTime = null;
    _timerStartTime = null;
    state = TimerState(remainingSeconds: 0, isMarketClosed: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final sellRateTimerProvider =
    StateNotifierProvider<RateTimerNotifier, TimerState>((ref) {
  return RateTimerNotifier(ref);
});

final buyRateTimerProvider =
    StateNotifierProvider<RateTimerNotifier, TimerState>((ref) {
  return RateTimerNotifier(ref);
});
