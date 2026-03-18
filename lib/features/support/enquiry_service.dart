import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sip/core/network/api_client.dart';

class Enquiry {
  final String enquiryId;
  final String subject;
  final String status;
  final String createdAt;
  final String lastUpdate;

  Enquiry({
    required this.enquiryId,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastUpdate,
  });

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      enquiryId: json['enquiry_id'] ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'OPEN',
      createdAt: json['created_at'] ?? '',
      lastUpdate: json['last_update'] ?? '',
    );
  }
}

class EnquiryService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> submitEnquiry({
    required String subject,
    required String message,
    required String category,
  }) async {
    try {
      final response = await _apiClient.post('users/support/submit', data: {
        'subject': subject,
        'message': message,
        'category': category,
      });
      return response.data ?? {};
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Enquiry>> getEnquiries() async {
    try {
      final response = await _apiClient.post('users/support/list');
      if (response.data != null && response.data['data'] != null) {
        final List enquiriesData = response.data['data']['enquiries'] ?? [];
        return enquiriesData.map((e) => Enquiry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final enquiryServiceProvider = Provider<EnquiryService>((ref) => EnquiryService());

final enquiriesProvider = FutureProvider<List<Enquiry>>((ref) {
  return ref.watch(enquiryServiceProvider).getEnquiries();
});
