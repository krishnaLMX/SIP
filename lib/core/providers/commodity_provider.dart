import 'package:flutter_riverpod/flutter_riverpod.dart';

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
