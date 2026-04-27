import '../../../core/network/api_client.dart';
import '../../../core/security/secure_logger.dart';
import '../models/sip_models.dart';

/// SIP API service.
///
/// All endpoints are POST as specified in the requirements.
/// Encryption of sensitive fields (`amount`, `transaction_pin`, etc.) is
/// handled automatically by [ApiSecurityInterceptor].
class SipService {
  final ApiClient _apiClient = ApiClient();

  // ─── Config ─────────────────────────────────────────────────────────────
  /// Fetches SIP configuration (frequencies, commodities, min/max amounts).
  Future<SipConfig> getConfig() async {
    SecureLogger.d('SIP: Fetching SIP config');
    final response = await _apiClient.post('sip/config');
    if (response.data != null && response.data['data'] != null) {
      return SipConfig.fromJson(response.data['data']);
    }
    throw Exception('Failed to load SIP configuration');
  }

  // ─── Denominations ──────────────────────────────────────────────────────
  /// Gold denominations for SIP, optionally filtered by frequency.
  Future<List<SipDenomination>> getGoldDenominations({int? frequencyId}) async {
    SecureLogger.d('SIP: Fetching gold denominations (freq=$frequencyId)');
    final Map<String, dynamic> payload = {};
    if (frequencyId != null) payload['frequency'] = frequencyId;
    final response =
        await _apiClient.post('sip/gold-denominations', data: payload);
    if (response.data != null && response.data['data'] != null) {
      final List list = response.data['data'];
      return list.map((e) => SipDenomination.fromJson(e)).toList();
    }
    return [];
  }

  /// Silver denominations for SIP, optionally filtered by frequency.
  Future<List<SipDenomination>> getSilverDenominations(
      {int? frequencyId}) async {
    SecureLogger.d('SIP: Fetching silver denominations (freq=$frequencyId)');
    final Map<String, dynamic> payload = {};
    if (frequencyId != null) payload['frequency'] = frequencyId;
    final response =
        await _apiClient.post('sip/silver-denominations', data: payload);
    if (response.data != null && response.data['data'] != null) {
      final List list = response.data['data'];
      return list.map((e) => SipDenomination.fromJson(e)).toList();
    }
    return [];
  }

  // ─── Create SIP Plan ────────────────────────────────────────────────────
  /// Creates a new SIP plan.
  ///
  /// [frequencyId]:  1 = Daily, 2 = Weekly, 3 = Monthly.
  /// [day]:          Required for Weekly (e.g., "Monday").
  /// [date]:         Required for Monthly (1–28).
  Future<SipCreateResponse> createSip({
    required int frequencyId,
    required int commodityId,
    required int amount,
    String? day,
    int? date,
  }) async {
    SecureLogger.d(
        'SIP: Creating SIP – frequency=$frequencyId, commodity=$commodityId');

    final Map<String, dynamic> payload = {
      'frequency': frequencyId,
      'commodity_id': commodityId,
      'amount': amount,
    };

    if (frequencyId == 2 && day != null) {
      payload['day'] = day;
    }
    if (frequencyId == 3 && date != null) {
      payload['date'] = date;
    }

    final response = await _apiClient.post('sip/create', data: payload);
    return SipCreateResponse.fromJson(response.data);
  }

  // ─── SIP Details (active plans list) ────────────────────────────────────
  /// Retrieves current SIP plan details.
  Future<List<SipPlanDetail>> getSipDetails() async {
    SecureLogger.d('SIP: Fetching SIP details');
    final response = await _apiClient.post('sip/details');
    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => SipPlanDetail.fromJson(e)).toList();
      } else if (data is Map<String, dynamic>) {
        return [SipPlanDetail.fromJson(data)];
      }
    }
    return [];
  }

  // ─── Manage Details ─────────────────────────────────────────────────────
  /// Fetches detailed info for the manage savings screen.
  Future<SipManageDetails> getManageDetails({
    required String subscriptionId,
  }) async {
    SecureLogger.d('SIP: Fetching manage details for $subscriptionId');
    final response = await _apiClient.post('sip/manage-details', data: {
      'subscription_id': subscriptionId,
    });
    if (response.data != null && response.data['data'] != null) {
      return SipManageDetails.fromJson(response.data['data']);
    }
    throw Exception('Failed to load manage details');
  }

  // ─── Pause ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> pauseSip({
    required String subscriptionId,
  }) async {
    SecureLogger.d('SIP: Pausing subscription $subscriptionId');
    final response = await _apiClient.post('sip/pause', data: {
      'subscription_id': subscriptionId,
    });
    return response.data;
  }

  // ─── Resume ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resumeSip({
    required String subscriptionId,
  }) async {
    SecureLogger.d('SIP: Resuming subscription $subscriptionId');
    final response = await _apiClient.post('sip/resume', data: {
      'subscription_id': subscriptionId,
    });
    return response.data;
  }

  // ─── Cancel ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> cancelSip({
    required String subscriptionId,
    required String reason,
  }) async {
    SecureLogger.d('SIP: Cancelling subscription $subscriptionId');
    final response = await _apiClient.post('sip/cancel', data: {
      'subscription_id': subscriptionId,
      'reason': reason,
    });
    return response.data;
  }

  // ─── Confirm (After Cashfree mandate auth callback) ────────────────────
  /// Verifies mandate authorization status with the backend.
  ///
  /// Called after Cashfree SDK returns a success/failure callback.
  /// Backend checks the mandate status with Cashfree and returns
  /// the verified result.
  Future<Map<String, dynamic>> confirmSip({
    required String orderId,
    String? subscriptionId,
  }) async {
    SecureLogger.d('SIP: Confirming mandate auth for order $orderId');
    final Map<String, dynamic> payload = {
      'order_id': orderId,
    };
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      payload['subscription_id'] = subscriptionId;
    }
    print('payload confirm sip: $payload');
    final response = await _apiClient.post('sip/confirm', data: payload);
    return response.data;
  }
}
