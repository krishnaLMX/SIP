import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/portfolio_service.dart';
import 'commodity_provider.dart';
import 'user_provider.dart';

class CommodityPortfolio {
  final double totalInvested;
  final double currentValue;
  final double returns;
  final double returnsPercentage;
  final double balance; // in grams
  final bool hasActiveAccount;

  CommodityPortfolio({
    required this.totalInvested,
    required this.currentValue,
    required this.returns,
    required this.returnsPercentage,
    required this.balance,
    required this.hasActiveAccount,
  });

  factory CommodityPortfolio.empty() => CommodityPortfolio(
        totalInvested: 0,
        currentValue: 0,
        returns: 0,
        returnsPercentage: 0,
        balance: 0,
        hasActiveAccount: false,
      );
}

class PortfolioData {
  final CommodityPortfolio summary;
  final bool isNewCustomer;

  PortfolioData({
    required this.summary,
    required this.isNewCustomer,
  });

  factory PortfolioData.empty() => PortfolioData(
        summary: CommodityPortfolio.empty(),
        isNewCustomer: true,
      );
}

class PortfolioNotifier extends StateNotifier<AsyncValue<PortfolioData>> {
  final PortfolioService _portfolioService;
  final String _idMetal;
  final String _idCustomer;

  PortfolioNotifier(this._portfolioService, this._idMetal, this._idCustomer)
      : super(const AsyncValue.loading()) {
    fetchPortfolio();
  }

  Future<void> fetchPortfolio() async {
    if (_idCustomer.isEmpty) {
      state = AsyncValue.data(PortfolioData.empty());
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data =
          await _portfolioService.getPortfolioSummary(_idMetal, _idCustomer);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final portfolioProvider =
    StateNotifierProvider.autoDispose<PortfolioNotifier, AsyncValue<PortfolioData>>((ref) {
  final service = ref.watch(portfolioServiceProvider);
  final userProfile = ref.watch(userProvider);

  final String idCustomer = userProfile?.id ?? '';
  // Reads id_metal dynamically from the API commodity list
  final String idMetal = ref.watch(selectedMetalIdProvider);

  return PortfolioNotifier(service, idMetal, idCustomer);
});

