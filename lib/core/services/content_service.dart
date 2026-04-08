import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class ContentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getOnboardingContent() async {
    try {
      final response = await _apiClient.post('users/content/onboarding');
      if (response.data != null &&
          response.data['data'] != null &&
          response.data['data']['slides'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']['slides']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getTermsAndConditions() async {
    try {
      final response = await _apiClient.post('content/terms');
      return response.data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    try {
      final response = await _apiClient.post('content/privacy');
      return response.data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> getFAQs() async {
    try {
      final response = await _apiClient.post('content/faqs');
      return response.data['data']['faqs'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAboutUs() async {
    try {
      final response = await _apiClient.post('content/about-us');
      return response.data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getContactUs() async {
    try {
      final response = await _apiClient.post('content/contact-us');
      return response.data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }
}

final contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

final onboardingContentProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(contentServiceProvider);
  return service.getOnboardingContent();
});

final termsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(contentServiceProvider).getTermsAndConditions();
});

final privacyPolicyProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(contentServiceProvider).getPrivacyPolicy();
});

final faqsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(contentServiceProvider).getFAQs();
});

final aboutUsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(contentServiceProvider).getAboutUs();
});

final contactUsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(contentServiceProvider).getContactUs();
});

