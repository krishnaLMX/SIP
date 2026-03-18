import '../../../core/network/api_client.dart';
import '../models/saving_models.dart';

class SavingService {
  final ApiClient _apiClient = ApiClient();

  Future<SavingConfig> getSavingConfig() async {
    try {
      final response = await _apiClient.post('savings/config');
      if (response.data != null && response.data['data'] != null) {
        return SavingConfig.fromJson(response.data['data']);
      }
      return SavingConfig.defaultConfig();
    } catch (e) {
      return SavingConfig.defaultConfig();
    }
  }

  Future<EligibilityResponse> checkEligibility({
    required String customerId,
    required String metalId,
    required String mobile,
    required double amount,
    required double rate,
    String? couponCode,
  }) async {
    final response = await _apiClient.post('savings/check-eligibility', data: {
      'id_customer': customerId,
      'id_metal': metalId,
      'mobile': mobile,
      'amount_inr': amount,
      'rate_per_gram': rate,
      'device_id': 'device-id-placeholder',
      'coupon_code': couponCode,
    });
    return EligibilityResponse.fromJson(response.data['data']);
  }

  Future<PurchaseInitiateResponse> initiatePurchase({
    required String customerId,
    required String metalId,
    required String mobile,
    required String buyType,
    required double amount,
    required double rate,
    String? couponCode,
  }) async {
    final response = await _apiClient.post('savings/initiate', data: {
      'id_customer': customerId,
      'id_metal': metalId,
      'mobile': mobile,
      'buy_type': buyType,
      'amount_inr': amount,
      'rate_per_gram': rate,
      'device_id': 'device-id-placeholder',
      'coupon_code': couponCode,
    });
    return PurchaseInitiateResponse.fromJson(response.data['data']);
  }
}

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _apiClient.post('payments/methods');
    if (response.data != null && response.data['data'] != null) {
      final List list = response.data['data']['methods'];
      return list.map((item) => PaymentMethod.fromJson(item)).toList();
    }
    return [];
  }

  Future<PaymentOrder> createOrder({
    required double amount,
    required String methodId,
    required String transactionId,
  }) async {
    final response = await _apiClient.post('payments/create-order', data: {
      'amount': amount,
      'method_id': methodId,
      'transaction_id': transactionId,
    });
    return PaymentOrder.fromJson(response.data['data']);
  }

  Future<String> verifyPaymentStatus(String orderId) async {
    final response = await _apiClient.post('payments/status', data: {
      'order_id': orderId,
    });
    return response.data['data']['status'];
  }
}
