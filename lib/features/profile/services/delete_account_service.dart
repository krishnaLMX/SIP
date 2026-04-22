import '../../../core/network/api_client.dart';

class DeleteAccountService {
  final ApiClient _apiClient = ApiClient();

  /// POST /delete-account/info — fetch policy text & is_allowed flag.
  Future<Map<String, dynamic>> fetchDeleteInfo() async {
    final response =
        await _apiClient.post('users/delete-account/info', data: {});
    if (response.data != null && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return {
        'content': data['content']?.toString() ?? '',
        'is_allowed': data['is_allowed'] == true,
      };
    }
    throw Exception(
        response.data?['message'] ?? 'Failed to load delete account info.');
  }

  /// POST /delete-account — permanently delete the account.
  Future<void> confirmDelete() async {
    final response =
        await _apiClient.post('delete-account', data: {'confirm': true});
    if (response.data == null || response.data['success'] != true) {
      throw Exception(response.data?['message'] ??
          'Account deletion failed. Please try again.');
    }
  }
}
