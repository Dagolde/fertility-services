import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/medical_record_model.dart';
import '../services/medical_record_cache_service.dart';
class MedicalRecordsRepository {
  static const String _basePath = '/medical-records/';

  Future<List<MedicalRecord>> getMedicalRecords() async {
    try {
      debugPrint('🔍 MedicalRecordsRepository.getMedicalRecords() called');
      final response = await ApiService.get(_basePath);

      debugPrint('📦 getMedicalRecords response status: ${response.statusCode}');
      debugPrint('📦 getMedicalRecords response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final records = data.map((json) => MedicalRecord.fromJson(json)).toList();
        debugPrint('✅ getMedicalRecords returning ${records.length} records');
        return records;
      }
      debugPrint('❌ getMedicalRecords returning empty list due to status code: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getMedicalRecords error: $e');
      rethrow;
    }
  }

  Future<MedicalRecord> uploadMedicalRecord({
    required File file,
    required String description,
    required String recordType,
  }) async {
    try {
      debugPrint('🔍 MedicalRecordsRepository.uploadMedicalRecord() called');
      debugPrint('   file: ${file.path}, description: $description, recordType: $recordType');
      debugPrint('   recordType type: ${recordType.runtimeType}');
      debugPrint('   recordType value: "$recordType"');

      // Determine content type based on file extension
      String contentType = 'application/octet-stream'; // default
      final extension = file.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
      }

      debugPrint('📄 Detected content type: $contentType for extension: $extension');

      // Ensure recordType is uppercase
      final normalizedRecordType = recordType.toUpperCase();
      debugPrint('🔍 Normalized recordType: "$normalizedRecordType"');
      debugPrint('🔍 Original recordType: "$recordType"');
      
      // Create form data with explicit content type
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: DioMediaType.parse(contentType),
        ),
        'description': description,
        'record_type': normalizedRecordType,
      });
      
      debugPrint('🔍 Form data created with record_type: "$normalizedRecordType"');

      debugPrint('📡 Making API call to: $_basePath with form data');
      debugPrint('📡 Form data fields: ${formData.fields.map((f) => '${f.key}=${f.value}').join(', ')}');
      debugPrint('📡 Form data record_type: "${formData.fields.firstWhere((field) => field.key == 'record_type').value}"');
      final response = await ApiService.post(
        _basePath,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      debugPrint('📦 uploadMedicalRecord response status: ${response.statusCode}');
      debugPrint('📦 uploadMedicalRecord response data: ${response.data}');

      if (response.statusCode == 200) {
        final record = MedicalRecord.fromJson(response.data);
        debugPrint('✅ uploadMedicalRecord successful: ${record.id}');
        
        // Cache the uploaded record
        await MedicalRecordCacheService.cacheMedicalRecords([record]);
        
        // Cache approval status
        await MedicalRecordCacheService.cacheApprovalStatus(
          record.id.toString(), 
          record.isVerified ? 'approved' : 'pending'
        );
        
        return record;
      }
      debugPrint('❌ uploadMedicalRecord failed with status: ${response.statusCode}');
      throw Exception('Failed to upload medical record');
    } catch (e) {
      debugPrint('❌ uploadMedicalRecord error: $e');
      rethrow;
    }
  }

  Future<MedicalRecord> getMedicalRecord(int recordId) async {
    try {
      final response = await ApiService.get('$_basePath$recordId');

      if (response.statusCode == 200) {
        return MedicalRecord.fromJson(response.data);
      }
      throw Exception('Medical record not found');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedicalRecord(int recordId) async {
    try {
      final response = await ApiService.delete('$_basePath$recordId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medical record');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      debugPrint('🔍 MedicalRecordsRepository.uploadProfileImage() called');
      debugPrint('   file: ${imageFile.path}');

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // default
      final extension = imageFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
      }

      debugPrint('📄 Detected content type: $contentType for extension: $extension');

      // Create form data with explicit content type
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: DioMediaType.parse(contentType),
        ),
      });

      debugPrint('📡 Making API call to: /users/me/profile/image with form data');
      final response = await ApiService.post(
        '/users/me/profile/image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      debugPrint('📦 uploadProfileImage response status: ${response.statusCode}');
      debugPrint('📦 uploadProfileImage response data: ${response.data}');

      if (response.statusCode == 200) {
        final filePath = response.data['file_path'] ?? '';
        debugPrint('✅ uploadProfileImage successful: $filePath');
        return filePath;
      }
      debugPrint('❌ uploadProfileImage failed with status: ${response.statusCode}');
      throw Exception('Failed to upload profile image');
    } catch (e) {
      debugPrint('❌ uploadProfileImage error: $e');
      rethrow;
    }
  }
}
