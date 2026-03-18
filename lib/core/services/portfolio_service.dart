import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../providers/portfolio_provider.dart';

class PortfolioService {
  final ApiClient _apiClient = ApiClient();

  Future<PortfolioData> getPortfolioSummary(
      String idMetal, String idCustomer) async {
    try {
      final response = await _apiClient.post(
        'portfolio/summary',
        data: {
          'id_metal': idMetal,
          'id_customer': idCustomer,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] ?? {};

        final invested = (data['total_invested'] ?? 0).toDouble();
        final value = (data['current_value_inr'] ?? 0).toDouble();
        final balance = (data['total_holdings_grams'] ?? 0).toDouble();

        final summary = CommodityPortfolio(
          totalInvested: invested,
          currentValue: value,
          returns: value - invested,
          returnsPercentage: (data['growth_percentage'] ?? 0).toDouble(),
          balance: balance,
          hasActiveAccount: balance > 0 || invested > 0,
        );

        return PortfolioData(
          summary: summary,
          isNewCustomer: invested == 0 && balance == 0,
        );
      }
      return PortfolioData.empty();
    } catch (e) {
      return PortfolioData.empty();
    }
  }
}

final portfolioServiceProvider =
    Provider<PortfolioService>((ref) => PortfolioService());
