import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/medical_record_model.dart';

class MedicalRecordCacheService {
  static const String _cacheKey = 'medical_records_cache';
  static const String _approvalStatusKey = 'medical_records_approval';

  /// Cache medical records locally
  static Future<void> cacheMedicalRecords(List<MedicalRecord> records) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheKey.json');
      
      final jsonData = records.map((record) => record.toJson()).toList();
      await file.writeAsString(json.encode(jsonData));
      
      debugPrint('✅ Cached ${records.length} medical records');
    } catch (e) {
      debugPrint('❌ Failed to cache medical records: $e');
    }
  }

  /// Get cached medical records
  static Future<List<MedicalRecord>> getCachedMedicalRecords() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheKey.json');
      
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final List<dynamic> data = json.decode(jsonData);
        return data.map((json) => MedicalRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Failed to get cached medical records: $e');
      return [];
    }
  }

  /// Cache approval status
  static Future<void> cacheApprovalStatus(String recordId, String status) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_approvalStatusKey.json');
      
      Map<String, dynamic> approvalMap = {};
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        approvalMap = json.decode(jsonData);
      }
      
      approvalMap[recordId] = status;
      await file.writeAsString(json.encode(approvalMap));
      
      debugPrint('✅ Cached approval status for record $recordId: $status');
    } catch (e) {
      debugPrint('❌ Failed to cache approval status: $e');
    }
  }

  /// Get approval status
  static Future<String?> getApprovalStatus(String recordId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_approvalStatusKey.json');
      
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final Map<String, dynamic> approvalMap = json.decode(jsonData);
        return approvalMap[recordId];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get approval status: $e');
      return null;
    }
  }

  /// Clear medical records cache
  static Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordsFile = File('${directory.path}/$_cacheKey.json');
      final approvalFile = File('${directory.path}/$_approvalStatusKey.json');
      
      if (await recordsFile.exists()) await recordsFile.delete();
      if (await approvalFile.exists()) await approvalFile.delete();
      
      debugPrint('✅ Cleared medical records cache');
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }
}
