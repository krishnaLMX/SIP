import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class UserProfile {
  final String name;
  final String email;
  final String phone;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

class ProfileState {
  final UserProfile user;
  final bool isLoading;
  final bool isEditing;
  final String? error;

  ProfileState({
    required this.user,
    this.isLoading = false,
    this.isEditing = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isEditing,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient = ApiClient();

  ProfileNotifier()
      : super(ProfileState(
          user: UserProfile(
            name: 'Lord Alexander',
            email: 'alexander@luxury.com',
            phone: '+91 98765 43210',
          ),
        ));

  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing, error: null);
  }

  Future<bool> updateProfile({required String name, required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Mocking API call
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would call the API:
      // await _apiClient.post('/profile/update', data: {'name': name, 'email': email});
      
      final updatedUser = state.user.copyWith(name: name, email: email);
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        isEditing: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
