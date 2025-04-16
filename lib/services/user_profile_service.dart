import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/models/user_profile.dart';

/// Service class to manage user profile-related operations
class UserProfileService {
  // Singleton instance
  static final UserProfileService _instance = UserProfileService._internal();

  // Factory constructor to return the same instance
  factory UserProfileService() {
    return _instance;
  }

  // Private constructor
  UserProfileService._internal();

  // Key for storing user profile in shared preferences
  static const String _userProfileKey = 'user_profile';

  // Current user profile (cached in memory)
  UserProfile? _currentProfile;

  /// Get the current user profile from cache or storage
  Future<UserProfile?> getCurrentProfile() async {
    if (_currentProfile != null) {
      return _currentProfile;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);

      if (profileJson != null) {
        _currentProfile = UserProfile.fromJson(profileJson);
        log('Loaded user profile from storage: ${_currentProfile?.name}');
        return _currentProfile;
      }

      // If no profile exists, return null
      log('No user profile found in storage');
      return null;
    } catch (e) {
      log('Error loading user profile: $e');
      return null;
    }
  }

  /// Save user profile to storage
  Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_userProfileKey, profile.toJson());

      if (success) {
        _currentProfile = profile;
        log('User profile saved: ${profile.name}');
      }

      return success;
    } catch (e) {
      log('Error saving user profile: $e');
      return false;
    }
  }

  /// Update an existing profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final currentProfile = await getCurrentProfile();

    if (currentProfile == null) {
      log('Cannot update profile: No profile exists');
      return false;
    }

    final updatedProfile = currentProfile.copyWith(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
    );

    return saveProfile(updatedProfile);
  }

  /// Clear the user profile (for logout)
  Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_userProfileKey);

      if (success) {
        _currentProfile = null;
        log('User profile cleared');
      }

      return success;
    } catch (e) {
      log('Error clearing user profile: $e');
      return false;
    }
  }

  /// Check if a user is logged in
  Future<bool> isUserLoggedIn() async {
    final profile = await getCurrentProfile();
    return profile != null;
  }

  // For demo/dev purposes: Create a sample profile
  Future<UserProfile> createSampleProfile() async {
    final sampleProfile = UserProfile(
      id: 'sample_user_id',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phoneNumber: '+1 (555) 123-4567',
      profileImageUrl: null,
    );

    await saveProfile(sampleProfile);
    return sampleProfile;
  }
}
