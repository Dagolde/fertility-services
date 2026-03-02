import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String? phone;
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  final String? gender;
  @JsonKey(name: 'user_type')
  final UserType userType;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'profile_completed')
  final bool profileCompleted;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  final String? bio;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    this.gender,
    required this.userType,
    required this.isActive,
    required this.isVerified,
    required this.profileCompleted,
    this.profilePicture,
    this.bio,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName => '$firstName $lastName';

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  bool get hasLocation => latitude != null && longitude != null;

  String get userTypeLabel {
    switch (userType) {
      case UserType.patient:
        return 'Patient';
      case UserType.spermDonor:
        return 'Sperm Donor';
      case UserType.eggDonor:
        return 'Egg Donor';
      case UserType.surrogate:
        return 'Surrogate';
      case UserType.hospital:
        return 'Hospital';
      case UserType.admin:
        return 'Admin';
    }
  }

  // Compatibility getter for profileImageUrl
  String? get profileImageUrl => profilePicture;

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    UserType? userType,
    bool? isActive,
    bool? isVerified,
    bool? profileCompleted,
    String? profilePicture,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonEnum()
enum UserType {
  @JsonValue('patient')
  patient,
  @JsonValue('sperm_donor')
  spermDonor,
  @JsonValue('egg_donor')
  eggDonor,
  @JsonValue('surrogate')
  surrogate,
  @JsonValue('hospital')
  hospital,
  @JsonValue('admin')
  admin,
}

@JsonSerializable()
class UserProfile {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String? bio;
  final String? occupation;
  final String? education;
  final String? interests;
  @JsonKey(name: 'medical_history')
  final String? medicalHistory;
  @JsonKey(name: 'family_history')
  final String? familyHistory;
  @JsonKey(name: 'lifestyle_info')
  final String? lifestyleInfo;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;
  @JsonKey(name: 'emergency_contact_relationship')
  final String? emergencyContactRelationship;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.bio,
    this.occupation,
    this.education,
    this.interests,
    this.medicalHistory,
    this.familyHistory,
    this.lifestyleInfo,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable()
class AuthUser {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'expires_in')
  final int? expiresIn;
  final User? user;

  AuthUser({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);
  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String? phone;
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  final String? gender;
  @JsonKey(name: 'user_type')
  final UserType userType;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    this.gender,
    required this.userType,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class UpdateProfileRequest {
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? phone;
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  final String? bio;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.phone,
    this.dateOfBirth,
    this.bio,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}

@JsonSerializable()
class ChangePasswordRequest {
  @JsonKey(name: 'current_password')
  final String currentPassword;
  @JsonKey(name: 'new_password')
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) => _$ChangePasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

@JsonSerializable()
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({
    required this.email,
  });

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) => _$ForgotPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

@JsonSerializable()
class ResetPasswordRequest {
  final String token;
  @JsonKey(name: 'new_password')
  final String newPassword;

  ResetPasswordRequest({
    required this.token,
    required this.newPassword,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) => _$ResetPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}
