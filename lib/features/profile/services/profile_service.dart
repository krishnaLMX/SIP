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
    required String dob,
    required String pincode,
    required String state,
    required String city,
    required String address,
    required String idCountry,
    required String idState,
    required String idCity,
  }) async {
    try {
      final response = await _apiClient.post(
        'profile/update',
        data: {
          'id_customer': customerId,
          'name': name,
          'email': email,
          'dob': dob,
          'pincode': pincode,
          'state': state,
          'city': city,
          'address': address,
          'id_country': idCountry,
          'id_state': idState,
          'id_city': idCity,
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkPincode(String pincode) async {
    try {
      final response = await _apiClient.post(
        'users/shared/check-pincode',
        data: {'pincode': pincode},
      );
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
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

      final fileSize = await photo.length();
      final ext = fileName.split('.').last.toLowerCase();
      print('── Photo Upload ──');
      print('  path: ${photo.path}');
      print('  filename: $fileName');
      print('  format/ext: $ext');
      print('  file size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      print('  fields: ${formData.fields}');
      print('  files: ${formData.files.map((f) => '${f.key}: ${f.value.filename} (contentType: ${f.value.contentType})').toList()}');
      print('── End ──');

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
