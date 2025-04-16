import 'dart:convert';

/// Model class representing a user profile in the StartWell app
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
  });

  /// Create a copy of this UserProfile with the given fields replaced with new values
  UserProfile copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  /// Create a UserProfile from JSON map
  factory UserProfile.fromMap(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  /// Create a JSON map from this UserProfile
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Create a UserProfile from JSON string
  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Create a JSON string from this UserProfile
  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, profileImageUrl: $profileImageUrl)';
  }
}
