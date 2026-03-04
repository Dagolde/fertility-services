import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ServicesRepository {
  static const String _basePath = '/services';

  Future<List<dynamic>> getServices({
    String? category,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 ServicesRepository.getServices() called with skip=$skip, limit=$limit, category=$category');
      
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      debugPrint('📡 Making API call to: $_basePath with params: $queryParams');
      final response = await ApiService.get(
        _basePath,
        queryParameters: queryParams,
      );

      debugPrint('📦 getServices response status: ${response.statusCode}');
      debugPrint('📦 getServices response data type: ${response.data.runtimeType}');
      debugPrint('📦 getServices response data: ${response.data}');

      if (response.statusCode == 200) {
        // API returns {services: [...], total: X, page: Y, limit: Z}
        final responseData = response.data;
        final services = responseData is Map 
            ? (responseData['services'] as List<dynamic>? ?? [])
            : (responseData as List<dynamic>? ?? []);
        debugPrint('✅ getServices returning ${services.length} services');
        return services;
      }
      debugPrint('❌ getServices returning empty list due to status code: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getServices error: $e');
      rethrow;
    }
  }

  Future<dynamic> getServiceById(int serviceId) async {
    try {
      debugPrint('🔍 ServicesRepository.getServiceById() called with serviceId=$serviceId');
      
      final response = await ApiService.get('$_basePath/$serviceId');

      debugPrint('📦 getServiceById response status: ${response.statusCode}');
      debugPrint('📦 getServiceById response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ getServiceById error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getServiceCategories() async {
    try {
      debugPrint('🔍 ServicesRepository.getServiceCategories() called');
      
      final response = await ApiService.get('$_basePath/categories');

      debugPrint('📦 getServiceCategories response status: ${response.statusCode}');
      debugPrint('📦 getServiceCategories response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } catch (e) {
      debugPrint('❌ getServiceCategories error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getFeaturedServices() async {
    try {
      debugPrint('🔍 ServicesRepository.getFeaturedServices() called');
      debugPrint('📡 Making API call to: $_basePath/featured');
      
      final response = await ApiService.get('$_basePath/featured');

      debugPrint('📦 getFeaturedServices response status: ${response.statusCode}');
      debugPrint('📦 getFeaturedServices response data type: ${response.data.runtimeType}');
      debugPrint('📦 getFeaturedServices response data: ${response.data}');

      if (response.statusCode == 200) {
        // API returns a list of services directly for /featured endpoint
        final services = response.data as List<dynamic>;
        debugPrint('✅ getFeaturedServices returning ${services.length} featured services');
        for (int i = 0; i < services.length; i++) {
          final service = services[i];
          debugPrint('   Service $i: ${service['name']} (${service['service_type']}) - Active: ${service['is_active']}');
        }
        return services;
      }
      debugPrint('❌ getFeaturedServices returning empty list due to status code: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getFeaturedServices error: $e');
      rethrow;
    }
  }
}
