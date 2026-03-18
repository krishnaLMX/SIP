import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  Future<Map<String, dynamic>?> getProfileDetails(String customerId) async {
    try {
      final response = await _apiClient.post(
        'profile/customer_details',
        data: {'id_customer': customerId},
      );
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile({
    required String customerId,
    required String name,
    required String email,
    required String address,
  }) async {
    try {
      final response = await _apiClient.post(
        'profile/update',
        data: {
          'id_customer': customerId,
          'name': name,
          'email': email,
          'address': address,
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfilePhoto({
    required File photo,
    required String customerId,
  }) async {
    try {
      final fileName = photo.path.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
        ),
        'id_customer': customerId,
      });

      final response = await _apiClient.post(
        'customer/update-profile-photo',
        data: formData,
      );

      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ApiClient());
});
