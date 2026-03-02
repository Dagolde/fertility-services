import 'package:flutter/material.dart';

class MedicalRecordStatus {
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

  MedicalRecordStatus({
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

  factory MedicalRecordStatus.fromJson(Map<String, dynamic> json) {
    return MedicalRecordStatus(
      id: json['id'] ?? 0,
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      description: json['description'] ?? '',
      recordType: json['record_type'] ?? '',
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at']) 
          : null,
      uploadedBy: json['uploaded_by'] ?? '',
      reviewedBy: json['reviewed_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'description': description,
      'record_type': recordType,
      'status': status,
      'admin_notes': adminNotes,
      'uploaded_at': uploadedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'uploaded_by': uploadedBy,
      'reviewed_by': reviewedBy,
    };
  }

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
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  MedicalRecordStatus copyWith({
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
    return MedicalRecordStatus(
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
