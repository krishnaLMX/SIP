import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/commodity_provider.dart';
import '../models/withdrawal_method.dart';

class WithdrawalService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all saved UPI/bank accounts for the customer.
  Future<List<WithdrawalMethod>> fetchAccountDetails({
    required String customerId,
    required String mobile,
  }) async {
    try {
      final response = await _apiClient.post('profile/accountdetails', data: {
        'id_customer': customerId,
        'mobile': mobile,
      });

      if (response.data != null && response.data['success'] == true) {
        final List data = response.data['data']?['accounts'] ??
            response.data['data']?['upi_list'] ??
            response.data['data'] ??
            [];
        return data.map((e) => WithdrawalMethod.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitWithdrawal({
    required String metalId,
    required double amount,
    required double weight,
    required double buyRate,
    required String withdrawalMethodId,
    required String withdrawalMethod,
  }) async {
    try {
      final response = await _apiClient.post('withdrawal/withdraw', data: {
        'id_metal': metalId,
        'amount': amount,
        'weight': weight,
        'buy_rate': buyRate,
        'withdrawal_method_id': withdrawalMethodId,
        'withdrawal_method': withdrawalMethod,
      });
      return response.data ?? {};
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> checkEligibility({
    required String customerId,
    required String mobile,
    required double amount,
    required String metalId,
  }) async {
    try {
      final response =
          await _apiClient.post('savings/check-eligibility', data: {
        'id_customer': customerId,
        'mobile': mobile,
        'id_metal': metalId,
        'amount_inr': amount,
        'request_from': 'withdraw',
      });

      if (response.data != null && response.data['success'] == true) {
        return response.data['data']?['next_step']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verify and add a UPI handle.
  Future<Map<String, dynamic>> verifyAndAddUpi({
    required String customerId,
    required String mobile,
    required String upiId,
  }) async {
    final response = await _apiClient.post('account/verify-upi', data: {
      'mobile': mobile,
      'upi_id': upiId,
    });
    return response.data ?? {};
  }

  /// Verify and add a bank account.
  Future<Map<String, dynamic>> verifyAndAddBank({
    required String customerId,
    required String mobile,
    required String holderName,
    required String bankName,
    required String accNo,
    required String ifsc,
  }) async {
    final response = await _apiClient.post('account/verify-bank', data: {
      'mobile': mobile,
      'account_holder': holderName,
      'bank_name': bankName,
      'account_no': accNo,
      'ifsc_code': ifsc,
    });
    return response.data ?? {};
  }

  /// Fetch withdrawable balance for the selected metal.
  /// Endpoint: POST referrals/reward-balance
  /// Payload:  { "id_metal": "1" }
  /// Response: data is a List — returns first element containing
  ///   withdrawable_qty, total_qty, on_hold_qty, commodity_name.
  Future<Map<String, dynamic>> fetchRewardBalance({
    required String metalId,
  }) async {
    try {
      final response =
          await _apiClient.post('referrals/reward-balance', data: {
        'id_metal': metalId,
      });
      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        if (rawData is List && rawData.isNotEmpty) {
          return Map<String, dynamic>.from(rawData.first);
        }
        if (rawData is Map) {
          return Map<String, dynamic>.from(rawData);
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}

final withdrawalServiceProvider = Provider((ref) => WithdrawalService());

/// Provider that fetches saved accounts (UPI + Bank) from `accountdetails` API.
final accountDetailsProvider =
    FutureProvider.autoDispose<List<WithdrawalMethod>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return const [];
  return ref.read(withdrawalServiceProvider).fetchAccountDetails(
        customerId: user.id,
        mobile: user.mobile,
      );
});

/// Fetches the referral reward balance for the currently selected metal.
/// Auto-disposes and rebuilds whenever the commodity tab changes.
final rewardBalanceProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final metalId = ref.watch(selectedMetalIdProvider);
  return ref.read(withdrawalServiceProvider).fetchRewardBalance(
        metalId: metalId,
      );
});
