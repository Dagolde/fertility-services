// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicalRecord _$MedicalRecordFromJson(Map<String, dynamic> json) =>
    MedicalRecord(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileType: json['file_type'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      description: json['description'] as String?,
      recordType: $enumDecode(_$MedicalRecordTypeEnumMap, json['record_type']),
      isVerified: json['is_verified'] as bool,
      verifiedBy: (json['verified_by'] as num?)?.toInt(),
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MedicalRecordToJson(MedicalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'file_name': instance.fileName,
      'file_path': instance.filePath,
      'file_type': instance.fileType,
      'file_size': instance.fileSize,
      'description': instance.description,
      'record_type': _$MedicalRecordTypeEnumMap[instance.recordType]!,
      'is_verified': instance.isVerified,
      'verified_by': instance.verifiedBy,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$MedicalRecordTypeEnumMap = {
  MedicalRecordType.license: 'LICENSE',
  MedicalRecordType.certification: 'CERTIFICATION',
  MedicalRecordType.diploma: 'DIPLOMA',
  MedicalRecordType.identification: 'IDENTIFICATION',
  MedicalRecordType.medicalHistory: 'MEDICAL_HISTORY',
  MedicalRecordType.labResults: 'LAB_RESULTS',
  MedicalRecordType.other: 'OTHER',
};

UploadMedicalRecordRequest _$UploadMedicalRecordRequestFromJson(
        Map<String, dynamic> json) =>
    UploadMedicalRecordRequest(
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      description: json['description'] as String?,
      recordType: $enumDecode(_$MedicalRecordTypeEnumMap, json['record_type']),
    );

Map<String, dynamic> _$UploadMedicalRecordRequestToJson(
        UploadMedicalRecordRequest instance) =>
    <String, dynamic>{
      'file_name': instance.fileName,
      'file_type': instance.fileType,
      'file_size': instance.fileSize,
      'description': instance.description,
      'record_type': _$MedicalRecordTypeEnumMap[instance.recordType]!,
    };

MedicalRecordResponse _$MedicalRecordResponseFromJson(
        Map<String, dynamic> json) =>
    MedicalRecordResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      record: json['record'] == null
          ? null
          : MedicalRecord.fromJson(json['record'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MedicalRecordResponseToJson(
        MedicalRecordResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'record': instance.record,
    };
