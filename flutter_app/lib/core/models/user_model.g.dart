// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      userType: $enumDecode(_$UserTypeEnumMap, json['user_type']),
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      profileCompleted: json['profile_completed'] as bool,
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'user_type': _$UserTypeEnumMap[instance.userType]!,
      'is_active': instance.isActive,
      'is_verified': instance.isVerified,
      'profile_completed': instance.profileCompleted,
      'profile_picture': instance.profilePicture,
      'bio': instance.bio,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'postal_code': instance.postalCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$UserTypeEnumMap = {
  UserType.patient: 'patient',
  UserType.spermDonor: 'sperm_donor',
  UserType.eggDonor: 'egg_donor',
  UserType.surrogate: 'surrogate',
  UserType.hospital: 'hospital',
  UserType.admin: 'admin',
};

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      bio: json['bio'] as String?,
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      interests: json['interests'] as String?,
      medicalHistory: json['medical_history'] as String?,
      familyHistory: json['family_history'] as String?,
      lifestyleInfo: json['lifestyle_info'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelationship:
          json['emergency_contact_relationship'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'bio': instance.bio,
      'occupation': instance.occupation,
      'education': instance.education,
      'interests': instance.interests,
      'medical_history': instance.medicalHistory,
      'family_history': instance.familyHistory,
      'lifestyle_info': instance.lifestyleInfo,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
      'emergency_contact_relationship': instance.emergencyContactRelationship,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => AuthUser(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'user': instance.user,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      userType: $enumDecode(_$UserTypeEnumMap, json['user_type']),
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'user_type': _$UserTypeEnumMap[instance.userType]!,
    };

UpdateProfileRequest _$UpdateProfileRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateProfileRequest(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UpdateProfileRequestToJson(
        UpdateProfileRequest instance) =>
    <String, dynamic>{
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'bio': instance.bio,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'postal_code': instance.postalCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

ChangePasswordRequest _$ChangePasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ChangePasswordRequest(
      currentPassword: json['current_password'] as String,
      newPassword: json['new_password'] as String,
    );

Map<String, dynamic> _$ChangePasswordRequestToJson(
        ChangePasswordRequest instance) =>
    <String, dynamic>{
      'current_password': instance.currentPassword,
      'new_password': instance.newPassword,
    };

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ForgotPasswordRequest(
      email: json['email'] as String,
    );

Map<String, dynamic> _$ForgotPasswordRequestToJson(
        ForgotPasswordRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
    };

ResetPasswordRequest _$ResetPasswordRequestFromJson(
        Map<String, dynamic> json) =>
    ResetPasswordRequest(
      token: json['token'] as String,
      newPassword: json['new_password'] as String,
    );

Map<String, dynamic> _$ResetPasswordRequestToJson(
        ResetPasswordRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'new_password': instance.newPassword,
    };
