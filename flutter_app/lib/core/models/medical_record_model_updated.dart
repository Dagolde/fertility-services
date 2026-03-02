import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'medical_record_model_updated.g.dart';

@JsonSerializable()
class MedicalRecord {
  final int id;
  final String fileName;
  final String filePath;
  final String description;
  final String recordType;
  final String status;
  final String? adminNotes;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final String uploadedBy;
  final String? reviewedBy;

  MedicalRecord({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.description,
    required this.recordType,
    required this.status,
    this.adminNotes,
    required this.uploadedAt,
    this.reviewedAt,
    required this.uploadedBy,
    this.reviewedBy,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) =>
      _$MedicalRecordFromJson(json);

  Map<String, dynamic> toJson() => _$MedicalRecordToJson(this);

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isUnderReview => status == 'under_review';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'under_review':
        return 'Under Review';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'approved':
        return const Color(0xFF4CAF50); // Green
      case 'rejected':
        return const Color(0xFFF44336); // Red
      case 'under_review':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  MedicalRecord copyWith({
    int? id,
    String? fileName,
    String? filePath,
    String? description,
    String? recordType,
    String? status,
    String? adminNotes,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? uploadedBy,
    String? reviewedBy,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      recordType: recordType ?? this.recordType,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}
