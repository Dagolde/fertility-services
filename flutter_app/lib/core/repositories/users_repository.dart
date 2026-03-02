import 'package:flutter/foundation.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class UsersRepository {
  static const String _basePath = '/users';

  Future<List<User>> searchUsers({
    String query = '',
    String? userType,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 UsersRepository.searchUsers called with query: "$query", userType: $userType');
      
      final queryParams = <String, dynamic>{
        'q': query,
        'skip': skip,
        'limit': limit,
      };
      
      if (userType != null) {
        queryParams['user_type'] = userType;
      }

      debugPrint('📡 Making API call to: $_basePath/search with params: $queryParams');

      final response = await ApiService.get(
        '$_basePath/search',
        queryParameters: queryParams,
      );

      debugPrint('📡 API Response - Status: ${response.statusCode}, Data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data;
        debugPrint('✅ Successfully received ${usersJson.length} users from API');
        final users = usersJson.map((json) => User.fromJson(json)).toList();
        debugPrint('✅ Successfully parsed ${users.length} User objects');
        return users;
      }
      debugPrint('❌ API call failed with status: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ UsersRepository.searchUsers error: $e');
      rethrow;
    }
  }

  Future<User?> getUserById(int userId) async {
    try {
      final response = await ApiService.get('$_basePath/$userId');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
