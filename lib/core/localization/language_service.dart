import '../network/api_client.dart';

class LanguageService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, Map<String, String>>?> fetchMegaTranslations() async {
    try {
      final response = await _apiClient.post('users/shared/all-translations');

      if (response.data != null && response.data['success'] == true) {
        final Map<String, dynamic> rawData = response.data['data'] ?? {};

        final Map<String, Map<String, String>> translations = {};

        rawData.forEach((key, value) {
          if (value is Map) {
            translations[key] =
                value.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        });

        return translations;
      }
    } catch (e) {
      print('Mega Localization fetch failed: $e');
    }
    return null;
  }
}
