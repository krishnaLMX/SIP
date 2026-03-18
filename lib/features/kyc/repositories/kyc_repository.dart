import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/kyc_document.dart';

final kycRepositoryProvider = Provider((ref) => KycRepository());

class KycRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<KycDocumentType>> getDocumentTypes({
    required String customerId,
    required String requestFrom,
  }) async {
    final response = await _apiClient.post('kyc/document-types', data: {
      'id_customer': customerId,
      'request_from': requestFrom,
    });

    if (response.data['success'] == true) {
      final List documents = response.data['data']['documents'];
      return documents.map((e) => KycDocumentType.fromJson(e)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to load documents');
    }
  }

  Future<bool> uploadKyc({
    required String customerId,
    required String requestFrom,
    required String documentId,
    required Map<String, dynamic> fields,
    String? frontPath,
    String? backPath,
  }) async {
    final Map<String, dynamic> data = {
      'id_customer': customerId,
      'request_from': requestFrom,
      'id_document': documentId,
      'fields': fields, 
    };

    if (frontPath != null) {
      data['front_image'] = await MultipartFile.fromFile(frontPath);
    }

    if (backPath != null) {
      data['back_image'] = await MultipartFile.fromFile(backPath);
    }

    final formData = FormData.fromMap(data);
    final response = await _apiClient.post('kyc/upload', data: formData);

    return response.data['success'] == true;
  }
}
