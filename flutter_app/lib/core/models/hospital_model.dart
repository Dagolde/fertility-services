import 'package:json_annotation/json_annotation.dart';

part 'hospital_model.g.dart';

@JsonEnum()
enum HospitalType {
  @JsonValue('IVF Centers')
  ivfCenters,
  @JsonValue('Fertility Clinics')
  fertilityClinics,
  @JsonValue('Sperm Banks')
  spermBanks,
  @JsonValue('Surrogacy Centers')
  surrogacyCenters,
  @JsonValue('General Hospital')
  generalHospital,
}

@JsonSerializable()
class Hospital {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? website;
  final String? description;
  final String address;
  final String city;
  final String state;
  final String country;
  @JsonKey(name: 'zip_code')
  final String? postalCode;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'license_number')
  final String licenseNumber;
  @JsonKey(name: 'hospital_type')
  final HospitalType hospitalType;
  @JsonKey(name: 'accreditation_info')
  final String? accreditationInfo;
  @JsonKey(name: 'operating_hours')
  final String? operatingHours;
  @JsonKey(name: 'emergency_contact')
  final String? emergencyContact;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  final List<String>? images;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final double? rating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Hospital({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.website,
    this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.licenseNumber,
    required this.hospitalType,
    this.accreditationInfo,
    this.operatingHours,
    this.emergencyContact,
    this.profilePicture,
    this.images,
    required this.isVerified,
    required this.isActive,
    this.rating,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => _$HospitalFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalToJson(this);

  String get fullAddress => '$address, $city, $state, $country $postalCode';

  String get displayRating => rating != null ? rating!.toStringAsFixed(1) : 'No rating';

  bool get hasImages => images != null && images!.isNotEmpty;

  String get statusText => isActive ? (isVerified ? 'Verified' : 'Pending Verification') : 'Inactive';

  Hospital copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? website,
    String? description,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? licenseNumber,
    HospitalType? hospitalType,
    String? accreditationInfo,
    String? operatingHours,
    String? emergencyContact,
    String? profilePicture,
    List<String>? images,
    bool? isVerified,
    bool? isActive,
    double? rating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hospitalType: hospitalType ?? this.hospitalType,
      accreditationInfo: accreditationInfo ?? this.accreditationInfo,
      operatingHours: operatingHours ?? this.operatingHours,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      profilePicture: profilePicture ?? this.profilePicture,
      images: images ?? this.images,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class HospitalService {
  final int id;
  @JsonKey(name: 'hospital_id')
  final int hospitalId;
  @JsonKey(name: 'service_type')
  final ServiceType serviceType;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'requirements')
  final String? requirements;
  @JsonKey(name: 'preparation_instructions')
  final String? preparationInstructions;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  HospitalService({
    required this.id,
    required this.hospitalId,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.isAvailable,
    this.requirements,
    this.preparationInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HospitalService.fromJson(Map<String, dynamic> json) => _$HospitalServiceFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalServiceToJson(this);

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  String get serviceTypeLabel {
    switch (serviceType) {
      case ServiceType.spermDonation:
        return 'Sperm Donation';
      case ServiceType.eggDonation:
        return 'Egg Donation';
      case ServiceType.surrogacy:
        return 'Surrogacy';
      case ServiceType.consultation:
        return 'Consultation';
      case ServiceType.testing:
        return 'Testing';
      case ServiceType.treatment:
        return 'Treatment';
    }
  }
}

@JsonEnum()
enum ServiceType {
  @JsonValue('sperm_donation')
  spermDonation,
  @JsonValue('egg_donation')
  eggDonation,
  @JsonValue('surrogacy')
  surrogacy,
  @JsonValue('consultation')
  consultation,
  @JsonValue('testing')
  testing,
  @JsonValue('treatment')
  treatment,
}

@JsonSerializable()
class HospitalReview {
  final int id;
  @JsonKey(name: 'hospital_id')
  final int hospitalId;
  @JsonKey(name: 'user_id')
  final int userId;
  final int rating;
  final String? comment;
  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final String? userName;
  final String? userProfilePicture;

  HospitalReview({
    required this.id,
    required this.hospitalId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userProfilePicture,
  });

  factory HospitalReview.fromJson(Map<String, dynamic> json) => _$HospitalReviewFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalReviewToJson(this);

  String get displayName => isAnonymous ? 'Anonymous' : (userName ?? 'User');

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

@JsonSerializable()
class HospitalSearchRequest {
  final String? query;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final double? radius;
  @JsonKey(name: 'service_types')
  final List<ServiceType>? serviceTypes;
  @JsonKey(name: 'min_rating')
  final double? minRating;
  @JsonKey(name: 'verified_only')
  final bool? verifiedOnly;
  @JsonKey(name: 'sort_by')
  final String? sortBy;
  @JsonKey(name: 'sort_order')
  final String? sortOrder;
  final int? page;
  @JsonKey(name: 'page_size')
  final int? pageSize;

  HospitalSearchRequest({
    this.query,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.radius,
    this.serviceTypes,
    this.minRating,
    this.verifiedOnly,
    this.sortBy,
    this.sortOrder,
    this.page,
    this.pageSize,
  });

  factory HospitalSearchRequest.fromJson(Map<String, dynamic> json) => _$HospitalSearchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalSearchRequestToJson(this);
}

@JsonSerializable()
class CreateReviewRequest {
  @JsonKey(name: 'hospital_id')
  final int hospitalId;
  final int rating;
  final String? comment;
  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;

  CreateReviewRequest({
    required this.hospitalId,
    required this.rating,
    this.comment,
    required this.isAnonymous,
  });

  factory CreateReviewRequest.fromJson(Map<String, dynamic> json) => _$CreateReviewRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateReviewRequestToJson(this);
}

@JsonSerializable()
class HospitalStats {
  @JsonKey(name: 'total_appointments')
  final int totalAppointments;
  @JsonKey(name: 'completed_appointments')
  final int completedAppointments;
  @JsonKey(name: 'cancelled_appointments')
  final int cancelledAppointments;
  @JsonKey(name: 'average_rating')
  final double averageRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'total_patients')
  final int totalPatients;
  @JsonKey(name: 'success_rate')
  final double? successRate;

  HospitalStats({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.averageRating,
    required this.totalReviews,
    required this.totalPatients,
    this.successRate,
  });

  factory HospitalStats.fromJson(Map<String, dynamic> json) => _$HospitalStatsFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalStatsToJson(this);

  double get completionRate {
    if (totalAppointments == 0) return 0.0;
    return (completedAppointments / totalAppointments) * 100;
  }

  double get cancellationRate {
    if (totalAppointments == 0) return 0.0;
    return (cancelledAppointments / totalAppointments) * 100;
  }
}
