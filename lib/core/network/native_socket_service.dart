import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/market/models/market_rates.dart';
import '../security/secure_logger.dart';

enum SocketStatus { connecting, connected, disconnected, error }

class NativeSocketService {
  final String _wsUrl = 'ws://13.202.62.253:57200';
  final List<String> _protocols = [
    '0b286a8b1100f097e7c8e879dbd4174e468a9e92f888e6e289595efdd4747b89'
  ];

  WebSocketChannel? _channel;

  final _ratesController = StreamController<MarketRates>.broadcast();
  final _statusController = StreamController<SocketStatus>.broadcast();

  Stream<MarketRates> get ratesStream async* {
    if (_lastRate != null) {
      yield _lastRate!;
    }
    yield* _ratesController.stream;
  }

  Stream<SocketStatus> get statusStream => _statusController.stream;

  bool _isDisposed = false;
  MarketRates? _lastRate;
  Timer? _reconnectTimer;

  String goldId = '1';
  String silverId = '3';
  String goldName = 'Gold 24KT';
  String silverName = 'Silver 999';

  void updateCommodityConfig(
      String gId, String gName, String sId, String sName) {
    goldId = gId;
    goldName = gName;
    silverId = sId;
    silverName = sName;

    // If we already have rates, update their names and re-emit
    if (_lastRate != null) {
      final updatedRates = _lastRate!.copyWith(
        goldName: gName,
        silverName: sName,
      );
      _lastRate = updatedRates;
      _ratesController.add(updatedRates);
    }
  }

  Future<void> connect() async {
    if (_isDisposed || _channel != null) return;

    _statusController.add(SocketStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(_wsUrl),
        protocols: _protocols,
      );

      // Provide web compatibility and wait for actual connection via ready future
      await _channel!.ready;

      _statusController.add(SocketStatus.connected);
      SecureLogger.d('NativeSocket: Connected to $_wsUrl');

      _channel!.stream.listen(
        (data) => _handleRateUpdate(data),
        onError: (error) {
          SecureLogger.e('NativeSocket: Error: $error');
          _statusController.add(SocketStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          SecureLogger.d('NativeSocket: Disconnected');
          _statusController.add(SocketStatus.disconnected);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      SecureLogger.e('NativeSocket: Connection failed: $e');
      _statusController.add(SocketStatus.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _channel?.sink.close();
    _channel = null;
    if (_isDisposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void _handleRateUpdate(dynamic data) {
    try {
      MarketRates newRates;
      String rawData;

      if (data is String) {
        rawData = data;
      } else if (data is List<int>) {
        rawData = String.fromCharCodes(data);
      } else {
        return; // Ignore unknown payloads
      }

      newRates = MarketRates.fromRawString(rawData, _lastRate,
          goldId: goldId,
          silverId: silverId,
          goldName: goldName,
          silverName: silverName);

      if (_lastRate == null || newRates.isSignificantChange(_lastRate!)) {
        _lastRate = newRates;
        _ratesController.add(newRates);
      }
    } catch (e) {
      SecureLogger.e('NativeSocket: Data parsing error: $e');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.add(SocketStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _ratesController.close();
    _statusController.close();
  }
}
