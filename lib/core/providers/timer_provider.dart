import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import '../../features/market/models/market_rates.dart';
import 'market_provider.dart';

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

  RateTimerNotifier(this.ref) : super(TimerState(remainingSeconds: 0)) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate timer when app comes back from background.
      _evaluateTimer();
    }
  }

  void startOrRefresh(int durationSeconds) {
    if (durationSeconds <= 0) return;
    _totalDuration = durationSeconds;

    // Lock the current live rate for the duration of this window.
    final currentRates = ref.read(marketRatesStreamProvider).valueOrNull;
    if (currentRates == null) return; // no rate yet — wait for first socket msg

    _timer?.cancel();
    _targetEndTime = DateTime.now().add(Duration(seconds: _totalDuration));
    state = TimerState(
      remainingSeconds: _totalDuration,
      lockedRates: currentRates,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
      // Timer expired — cancel tick, keep lockedRates alive so the UI never
      // flickers between cycles, then restart immediately with the latest rate.
      _timer?.cancel();
      _targetEndTime = null;
      _refreshAndRestart();
    }
  }

  void _refreshAndRestart() {
    // ── Why there is NO timestamp-based market-closed detection here ────────
    //
    // A previous version compared latestRate.timestamp against _timerStartTime:
    //   "If no new rate arrived during the timer window → market is closed."
    //
    // This BROKE when the socket sends rates infrequently (e.g. one message at
    // connection time and then goes silent even though the market is OPEN):
    //
    //   Socket rate timestamp : T0 = 13:27:29
    //   Timer _timerStartTime : T0+Δ = 13:27:30   ← just after T0
    //   Timer expires at        13:29:50
    //   Check: T0.isAfter(T0+Δ) = false  →  !false = true  →  "market closed"  ✗
    //
    // The false-positive triggered: isMarketClosed=true → isActive=false →
    // build() safety guard fired startOrRefresh() → isMarketClosed=false →
    // tick again → repeat → visible SHAKE on every timer boundary.
    //
    // Market open/closed is already correctly tracked by marketStatusProvider
    // via the socket's dedicated status messages (5|...|1 = open, 5|...|0 =
    // closed). Both withdrawal and instant saving screens read
    // isCurrentMarketClosed from that provider and show the appropriate UI.
    // The timer's only responsibility is to lock a rate and count down —
    // it does NOT need to independently detect market closure.
    startOrRefresh(_totalDuration);
  }

  void clear() {
    _timer?.cancel();
    _targetEndTime = null;
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
