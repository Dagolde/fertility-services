import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class AuthRepository {
  static const String _basePath = '/auth';

  Future<AuthUser?> login(LoginRequest loginRequest) async {
    try {
      final response = await ApiService.post(
        '$_basePath/login',
        data: loginRequest.toJson(),
      );

      if (response.statusCode == 200) {
        return AuthUser.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthUser?> register(RegisterRequest registerRequest) async {
    try {
      final response = await ApiService.post(
        '$_basePath/register',
        data: registerRequest.toJson(),
      );

      if (response.statusCode == 201) {
        return AuthUser.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await ApiService.post(
        '$_basePath/forgot-password',
        data: request.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await ApiService.post(
        '$_basePath/reset-password',
        data: request.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await ApiService.post(
        '$_basePath/change-password',
        data: request.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await ApiService.get('/users/me');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await ApiService.put(
        '/users/me',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> uploadProfilePicture(String filePath) async {
    try {
      final response = await ApiService.uploadFile(
        '$_basePath/profile-picture',
        filePath,
        fileName: 'profile_picture.jpg',
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      final response = await ApiService.post(
        '$_basePath/verify-email',
        data: {'token': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      final response = await ApiService.post('$_basePath/resend-verification');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthUser?> refreshToken(String refreshToken) async {
    try {
      final response = await ApiService.post(
        '$_basePath/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        return AuthUser.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await ApiService.post('$_basePath/logout');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await ApiService.delete('$_basePath/account');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateFCMToken(String token) async {
    try {
      final response = await ApiService.post(
        '$_basePath/fcm-token',
        data: {'fcm_token': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile(int userId) async {
    try {
      final response = await ApiService.get('/users/$userId/profile');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile?> updateUserProfile(UserProfile profile) async {
    try {
      final response = await ApiService.put(
        '/users/${profile.userId}/profile',
        data: profile.toJson(),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> searchUsers({
    String? query,
    UserType? userType,
    String? city,
    String? state,
    bool? isVerified,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (query != null) queryParams['query'] = query;
      if (userType != null) queryParams['user_type'] = userType.name;
      if (city != null) queryParams['city'] = city;
      if (state != null) queryParams['state'] = state;
      if (isVerified != null) queryParams['is_verified'] = isVerified;

      final response = await ApiService.get(
        '/users/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data['items'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserById(int userId) async {
    try {
      final response = await ApiService.get('/users/$userId');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reportUser(int userId, String reason, String? description) async {
    try {
      final response = await ApiService.post(
        '/users/$userId/report',
        data: {
          'reason': reason,
          'description': description,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> blockUser(int userId) async {
    try {
      final response = await ApiService.post('/users/$userId/block');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      final response = await ApiService.delete('/users/$userId/block');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> getBlockedUsers() async {
    try {
      final response = await ApiService.get('/users/blocked');

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data;
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final response = await ApiService.put(
        '$_basePath/notification-settings',
        data: settings,
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, bool>?> getNotificationSettings() async {
    try {
      final response = await ApiService.get('$_basePath/notification-settings');

      if (response.statusCode == 200) {
        return Map<String, bool>.from(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updatePrivacySettings(Map<String, dynamic> settings) async {
    try {
      final response = await ApiService.put(
        '$_basePath/privacy-settings',
        data: settings,
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPrivacySettings() async {
    try {
      final response = await ApiService.get('$_basePath/privacy-settings');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deactivateAccount() async {
    try {
      final response = await ApiService.post('$_basePath/deactivate');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reactivateAccount() async {
    try {
      final response = await ApiService.post('$_basePath/reactivate');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getAccountStats() async {
    try {
      final response = await ApiService.get('$_basePath/stats');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLoginHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_basePath/login-history',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> historyJson = response.data['items'];
        return historyJson.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> enableTwoFactorAuth() async {
    try {
      final response = await ApiService.post('$_basePath/2fa/enable');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> disableTwoFactorAuth(String code) async {
    try {
      final response = await ApiService.post(
        '$_basePath/2fa/disable',
        data: {'code': code},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyTwoFactorAuth(String code) async {
    try {
      final response = await ApiService.post(
        '$_basePath/2fa/verify',
        data: {'code': code},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
