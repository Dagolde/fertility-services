// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hospital_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hospital _$HospitalFromJson(Map<String, dynamic> json) => Hospital(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      postalCode: json['zip_code'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      licenseNumber: json['license_number'] as String,
      hospitalType: $enumDecode(_$HospitalTypeEnumMap, json['hospital_type']),
      accreditationInfo: json['accreditation_info'] as String?,
      operatingHours: json['operating_hours'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      profilePicture: json['profile_picture'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isVerified: json['is_verified'] as bool,
      isActive: json['is_active'] as bool,
      rating: (json['rating'] as num?)?.toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$HospitalToJson(Hospital instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'website': instance.website,
      'description': instance.description,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'zip_code': instance.postalCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'license_number': instance.licenseNumber,
      'hospital_type': _$HospitalTypeEnumMap[instance.hospitalType]!,
      'accreditation_info': instance.accreditationInfo,
      'operating_hours': instance.operatingHours,
      'emergency_contact': instance.emergencyContact,
      'profile_picture': instance.profilePicture,
      'images': instance.images,
      'is_verified': instance.isVerified,
      'is_active': instance.isActive,
      'rating': instance.rating,
      'total_reviews': instance.totalReviews,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$HospitalTypeEnumMap = {
  HospitalType.ivfCenters: 'IVF Centers',
  HospitalType.fertilityClinics: 'Fertility Clinics',
  HospitalType.spermBanks: 'Sperm Banks',
  HospitalType.surrogacyCenters: 'Surrogacy Centers',
  HospitalType.generalHospital: 'General Hospital',
};

HospitalService _$HospitalServiceFromJson(Map<String, dynamic> json) =>
    HospitalService(
      id: (json['id'] as num).toInt(),
      hospitalId: (json['hospital_id'] as num).toInt(),
      serviceType: $enumDecode(_$ServiceTypeEnumMap, json['service_type']),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      isAvailable: json['is_available'] as bool,
      requirements: json['requirements'] as String?,
      preparationInstructions: json['preparation_instructions'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$HospitalServiceToJson(HospitalService instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hospital_id': instance.hospitalId,
      'service_type': _$ServiceTypeEnumMap[instance.serviceType]!,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'duration_minutes': instance.durationMinutes,
      'is_available': instance.isAvailable,
      'requirements': instance.requirements,
      'preparation_instructions': instance.preparationInstructions,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$ServiceTypeEnumMap = {
  ServiceType.spermDonation: 'sperm_donation',
  ServiceType.eggDonation: 'egg_donation',
  ServiceType.surrogacy: 'surrogacy',
  ServiceType.consultation: 'consultation',
  ServiceType.testing: 'testing',
  ServiceType.treatment: 'treatment',
};

HospitalReview _$HospitalReviewFromJson(Map<String, dynamic> json) =>
    HospitalReview(
      id: (json['id'] as num).toInt(),
      hospitalId: (json['hospital_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      isAnonymous: json['is_anonymous'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['userName'] as String?,
      userProfilePicture: json['userProfilePicture'] as String?,
    );

Map<String, dynamic> _$HospitalReviewToJson(HospitalReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hospital_id': instance.hospitalId,
      'user_id': instance.userId,
      'rating': instance.rating,
      'comment': instance.comment,
      'is_anonymous': instance.isAnonymous,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'userName': instance.userName,
      'userProfilePicture': instance.userProfilePicture,
    };

HospitalSearchRequest _$HospitalSearchRequestFromJson(
        Map<String, dynamic> json) =>
    HospitalSearchRequest(
      query: json['query'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      serviceTypes: (json['service_types'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ServiceTypeEnumMap, e))
          .toList(),
      minRating: (json['min_rating'] as num?)?.toDouble(),
      verifiedOnly: json['verified_only'] as bool?,
      sortBy: json['sort_by'] as String?,
      sortOrder: json['sort_order'] as String?,
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['page_size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HospitalSearchRequestToJson(
        HospitalSearchRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'service_types':
          instance.serviceTypes?.map((e) => _$ServiceTypeEnumMap[e]!).toList(),
      'min_rating': instance.minRating,
      'verified_only': instance.verifiedOnly,
      'sort_by': instance.sortBy,
      'sort_order': instance.sortOrder,
      'page': instance.page,
      'page_size': instance.pageSize,
    };

CreateReviewRequest _$CreateReviewRequestFromJson(Map<String, dynamic> json) =>
    CreateReviewRequest(
      hospitalId: (json['hospital_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      isAnonymous: json['is_anonymous'] as bool,
    );

Map<String, dynamic> _$CreateReviewRequestToJson(
        CreateReviewRequest instance) =>
    <String, dynamic>{
      'hospital_id': instance.hospitalId,
      'rating': instance.rating,
      'comment': instance.comment,
      'is_anonymous': instance.isAnonymous,
    };

HospitalStats _$HospitalStatsFromJson(Map<String, dynamic> json) =>
    HospitalStats(
      totalAppointments: (json['total_appointments'] as num).toInt(),
      completedAppointments: (json['completed_appointments'] as num).toInt(),
      cancelledAppointments: (json['cancelled_appointments'] as num).toInt(),
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      totalPatients: (json['total_patients'] as num).toInt(),
      successRate: (json['success_rate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$HospitalStatsToJson(HospitalStats instance) =>
    <String, dynamic>{
      'total_appointments': instance.totalAppointments,
      'completed_appointments': instance.completedAppointments,
      'cancelled_appointments': instance.cancelledAppointments,
      'average_rating': instance.averageRating,
      'total_reviews': instance.totalReviews,
      'total_patients': instance.totalPatients,
      'success_rate': instance.successRate,
    };
