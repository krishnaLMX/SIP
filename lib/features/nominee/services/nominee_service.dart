import '../../../core/network/api_client.dart';
import '../../../core/security/secure_logger.dart';
import '../models/nominee_model.dart';

/// Nominee API service.
///
/// Encryption of sensitive fields (`mobile`, `aadhaar_number`, etc.)
/// is handled automatically by [ApiSecurityInterceptor].
class NomineeService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch existing nominee details.
  Future<NomineeDetails?> getNomineeDetails() async {
    SecureLogger.d('NOMINEE: Fetching nominee details');
    final response = await _apiClient.post('users/nominee/details');
    if (response.data != null &&
        response.data['success'] == true &&
        response.data['data'] != null) {
      final data = response.data['data'] as Map<String, dynamic>;
      // API might return empty object when no nominee exists
      if (data.isEmpty ||
          (data['name'] == null && data['relationship'] == null)) {
        return null;
      }
      return NomineeDetails.fromJson(data);
    }
    return null;
  }

  /// Create or update nominee details.
  Future<Map<String, dynamic>> updateNominee(NomineeDetails nominee) async {
    SecureLogger.d('NOMINEE: Updating nominee');
    final response = await _apiClient.post(
      'users/nominee/update',
      data: nominee.toJson(),
    );
    return response.data;
  }

  /// Fetch dynamic relationship list from server.
  ///
  /// Returns a list of [NomineeRelationship] objects (id + name).
  /// Returns `null` on failure so the caller can fall back to the
  /// hardcoded [nomineeRelationships] list.
  Future<List<NomineeRelationship>?> fetchRelationships() async {
    try {
      SecureLogger.d('NOMINEE: Fetching relationship list');
      final response = await _apiClient.post('users/nominee/relationships');
      if (response.data != null &&
          response.data['success'] == true &&
          response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final list = data['relationships'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => NomineeRelationship.fromJson(e))
              .where((r) => r.name.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      SecureLogger.e('NOMINEE: Failed to fetch relationships: $e');
    }
    return null;
  }
}
