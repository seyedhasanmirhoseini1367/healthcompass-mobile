class UserProfile {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final String roleDisplay;
  final bool isApproved;
  final String? profilePicture;
  final String? phoneNumber;
  final String? dateOfBirth;

  const UserProfile({
    required this.id,
    this.username = '',
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.fullName = '',
    this.role = '',
    this.roleDisplay = '',
    this.isApproved = false,
    this.profilePicture,
    this.phoneNumber,
    this.dateOfBirth,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        firstName: (json['first_name'] ?? '').toString(),
        lastName: (json['last_name'] ?? '').toString(),
        fullName: (json['full_name'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        roleDisplay: (json['role_display'] ?? '').toString(),
        isApproved: json['is_approved'] == true,
        profilePicture: json['profile_picture']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        dateOfBirth: json['date_of_birth']?.toString(),
      );
}

/// Shape returned by /auth/emergency-card/ — distinct from [UserProfile];
/// combines user + PatientProfile fields plus the public share token.
class EmergencyCard {
  final String fullName;
  final String email;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String bloodType;
  final String allergies;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String token;

  const EmergencyCard({
    this.fullName = '',
    this.email = '',
    this.dateOfBirth,
    this.phoneNumber,
    this.bloodType = '',
    this.allergies = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.token = '',
  });

  factory EmergencyCard.fromJson(Map<String, dynamic> json) => EmergencyCard(
        fullName: (json['full_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        dateOfBirth: json['date_of_birth']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        bloodType: (json['blood_type'] ?? '').toString(),
        allergies: (json['allergies'] ?? '').toString(),
        emergencyContactName: (json['emergency_contact_name'] ?? '').toString(),
        emergencyContactPhone: (json['emergency_contact_phone'] ?? '').toString(),
        token: (json['token'] ?? '').toString(),
      );
}
