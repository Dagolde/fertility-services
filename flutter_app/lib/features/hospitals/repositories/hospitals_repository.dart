import '../../../core/models/hospital_model.dart';
import '../../../core/services/api_service.dart';

class HospitalsRepository {
  static const String _basePath = '/hospitals';

  Future<List<Hospital>> getHospitals({
    String? search,
    String? city,
    String? state,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }

      final response = await ApiService.get(
        '$_basePath/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> hospitalsJson = response.data;
        return hospitalsJson.map((json) => Hospital.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Hospital?> getHospitalById(int hospitalId) async {
    try {
      final response = await ApiService.get('$_basePath/$hospitalId');

      if (response.statusCode == 200) {
        return Hospital.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Hospital>> getNearbyHospitals({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_basePath/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> hospitalsJson = response.data;
        return hospitalsJson.map((json) => Hospital.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getHospitalServices(int hospitalId) async {
    try {
      final response = await ApiService.get('$_basePath/$hospitalId/services');

      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getHospitalDoctors(int hospitalId) async {
    try {
      final response = await ApiService.get('$_basePath/$hospitalId/doctors');

      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getHospitalReviews(int hospitalId) async {
    try {
      final response = await ApiService.get('$_basePath/$hospitalId/reviews');

      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
