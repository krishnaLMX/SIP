import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/native_socket_service.dart';
import '../../features/market/models/market_rates.dart';
import '../services/shared_service.dart';

// Provides the singleton instance of the service
final socketIOServiceProvider = Provider<NativeSocketService>((ref) {
  final service = NativeSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Provides the stream of rates
final marketRatesStreamProvider = StreamProvider<MarketRates>((ref) {
  final service = ref.watch(socketIOServiceProvider);

  // Watch commodities to dynamic update socket IDs
  final commodities = ref.watch(commoditiesProvider).valueOrNull;
  if (commodities != null) {
    String? gId;
    String? sId;
    String? gName;
    String? sName;
    for (var c in commodities) {
      if (c.name.toLowerCase().contains('gold')) {
        gId = c.webSocketId > 0 ? c.webSocketId.toString() : '91';
        gName = c.name;
      }
      if (c.name.toLowerCase().contains('silver')) {
        sId = c.webSocketId > 0 ? c.webSocketId.toString() : '98';
        sName = c.name;
      }
    }
    if (gId != null && sId != null && gName != null && sName != null) {
      service.updateCommodityConfig(gId, gName, sId, sName);
    }
  }

  // Auto-connect when this provider is first watched
  service.connect();
  return service.ratesStream;
});

// Provides the connection status
final socketStatusProvider = StreamProvider<SocketStatus>((ref) {
  final service = ref.watch(socketIOServiceProvider);
  return service.statusStream;
});
