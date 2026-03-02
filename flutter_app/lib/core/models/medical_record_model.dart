import 'package:json_annotation/json_annotation.dart';

part 'medical_record_model.g.dart';

@JsonSerializable()
class MedicalRecord {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'file_path')
  final String filePath;
  @JsonKey(name: 'file_type')
  final String fileType;
  @JsonKey(name: 'file_size')
  final int fileSize;
  final String? description;
  @JsonKey(name: 'record_type')
  final MedicalRecordType recordType;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'verified_by')
  final int? verifiedBy;
  @JsonKey(name: 'verified_at')
  final DateTime? verifiedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MedicalRecord({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.description,
    required this.recordType,
    required this.isVerified,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => _$MedicalRecordFromJson(json);
  Map<String, dynamic> toJson() => _$MedicalRecordToJson(this);

  String get fileUrl => filePath;
  
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get recordTypeLabel {
    switch (recordType) {
      case MedicalRecordType.license:
        return 'Medical License';
      case MedicalRecordType.certification:
        return 'Certification';
      case MedicalRecordType.diploma:
        return 'Medical Diploma';
      case MedicalRecordType.identification:
        return 'Identification';
      case MedicalRecordType.medicalHistory:
        return 'Medical History';
      case MedicalRecordType.labResults:
        return 'Lab Results';
      case MedicalRecordType.other:
        return 'Other';
    }
  }
}

@JsonEnum()
enum MedicalRecordType {
  @JsonValue('LICENSE')
  license,
  @JsonValue('CERTIFICATION')
  certification,
  @JsonValue('DIPLOMA')
  diploma,
  @JsonValue('IDENTIFICATION')
  identification,
  @JsonValue('MEDICAL_HISTORY')
  medicalHistory,
  @JsonValue('LAB_RESULTS')
  labResults,
  @JsonValue('OTHER')
  other,
}

@JsonSerializable()
class UploadMedicalRecordRequest {
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'file_type')
  final String fileType;
  @JsonKey(name: 'file_size')
  final int fileSize;
  final String? description;
  @JsonKey(name: 'record_type')
  final MedicalRecordType recordType;

  UploadMedicalRecordRequest({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.description,
    required this.recordType,
  });

  factory UploadMedicalRecordRequest.fromJson(Map<String, dynamic> json) => 
      _$UploadMedicalRecordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UploadMedicalRecordRequestToJson(this);
}

@JsonSerializable()
class MedicalRecordResponse {
  final bool success;
  final String message;
  final MedicalRecord? record;

  MedicalRecordResponse({
    required this.success,
    required this.message,
    this.record,
  });

  factory MedicalRecordResponse.fromJson(Map<String, dynamic> json) => 
      _$MedicalRecordResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MedicalRecordResponseToJson(this);
}
