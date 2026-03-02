// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_record_model_updated.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicalRecord _$MedicalRecordFromJson(Map<String, dynamic> json) =>
    MedicalRecord(
      id: (json['id'] as num).toInt(),
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      description: json['description'] as String,
      recordType: json['recordType'] as String,
      status: json['status'] as String,
      adminNotes: json['adminNotes'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      uploadedBy: json['uploadedBy'] as String,
      reviewedBy: json['reviewedBy'] as String?,
    );

Map<String, dynamic> _$MedicalRecordToJson(MedicalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'description': instance.description,
      'recordType': instance.recordType,
      'status': instance.status,
      'adminNotes': instance.adminNotes,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'uploadedBy': instance.uploadedBy,
      'reviewedBy': instance.reviewedBy,
    };
