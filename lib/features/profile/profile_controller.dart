import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/profile_service.dart';
import '../../core/providers/user_provider.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.photoUrl,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
  }) {
    return UserProfile(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class ProfileState {
  final UserProfile user;
  final bool isLoading;
  final bool isPhotoLoading;
  final bool isEditing;
  final String? error;

  ProfileState({
    required this.user,
    this.isLoading = false,
    this.isPhotoLoading = false,
    this.isEditing = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isPhotoLoading,
    bool? isEditing,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isPhotoLoading: isPhotoLoading ?? this.isPhotoLoading,
      isEditing: isEditing ?? this.isEditing,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;
  final String _customerId;

  ProfileNotifier(this._profileService, this._customerId)
      : super(ProfileState(
          user: UserProfile(
            id: _customerId,
            name: 'Investor',
            email: '',
            phone: '',
            address: '',
          ),
        )) {
    fetchProfileDetails();
  }

  Future<void> fetchProfileDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _profileService.getProfileDetails(_customerId);
      if (data != null) {
        state = state.copyWith(
          user: UserProfile(
            id: _customerId,
            name: data['name'] ?? data['full_name'] ?? 'Investor',
            email: data['email'] ?? '',
            phone: data['mobile'] ?? data['phone'] ?? '',
            address: data['address'] ?? '',
            photoUrl: data['photo_url'],
          ),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load profile');
    }
  }

  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing, error: null);
  }

  Future<bool> updateProfile(
      {required String name,
      required String email,
      required String address}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _profileService.updateProfile(
        customerId: _customerId,
        name: name,
        email: email,
        address: address,
      );

      if (success) {
        final updatedUser =
            state.user.copyWith(name: name, email: email, address: address);
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          isEditing: false,
        );
        return true;
      } else {
        throw Exception('Server failed to update');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }

  Future<bool> updateProfilePhoto(File photo) async {
    state = state.copyWith(isPhotoLoading: true, error: null);

    try {
      final success = await _profileService.updateProfilePhoto(
        photo: photo,
        customerId: state.user.id,
      );

      if (success) {
        // In a real app, the server might return the new URL
        // For now, we update local state with a mock URL or just use the File path for immediate preview if needed
        // but since we want to simulate a real upload, we'll keep it simple
        state = state.copyWith(
          isPhotoLoading: false,
          error: null,
        );
        return true;
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      state = state.copyWith(
        isPhotoLoading: false,
        error: 'Failed to upload photo. Please try again.',
      );
      return false;
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final service = ref.watch(profileServiceProvider);
  final user = ref.watch(userProvider);
  final customerId = user?.id ?? '';
  return ProfileNotifier(service, customerId);
});
