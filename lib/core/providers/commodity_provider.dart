import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:startgold/core/services/shared_service.dart';

enum CommodityType { gold, silver }

class CommodityNotifier extends StateNotifier<CommodityType> {
  CommodityNotifier() : super(CommodityType.gold);

  void setCommodity(CommodityType type) {
    state = type;
  }
}

final commodityProvider =
    StateNotifierProvider<CommodityNotifier, CommodityType>((ref) {
  return CommodityNotifier();
});

/// Derives the API `id_metal` for the currently selected commodity.
///
/// Reads the commodity list fetched from the API (via [commoditiesProvider]),
/// matches on the name ('gold' or 'silver'), and returns the real `id_metal`.
///
/// Falls back to '1' for Gold and '3' for Silver only when the API list is
/// unavailable (loading / network error) — these should match your backend.
final selectedMetalIdProvider = Provider<String>((ref) {
  final selectedType = ref.watch(commodityProvider);
  final commodities = ref.watch(commoditiesProvider).valueOrNull;

  if (commodities != null && commodities.isNotEmpty) {
    final keyword = selectedType == CommodityType.gold ? 'gold' : 'silver';
    final match = commodities.firstWhere(
      (c) => c.name.toLowerCase().contains(keyword),
      orElse: () => commodities.first,
    );
    if (match.id.isNotEmpty) return match.id;
  }

  // Fallback — only used while commodities API is still loading
  return selectedType == CommodityType.gold ? '1' : '3';
});
