import 'package:flutter/foundation.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service_simple.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isOnboarded = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _isOnboarded;
  String? get errorMessage => _errorMessage;
  
  // Get auth token from storage
  Future<String?> get token async {
    return await StorageService.getAuthToken();
  }

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is onboarded
      _isOnboarded = StorageService.isOnboardingCompleted();

      // Check for existing auth token
      final token = await StorageService.getAuthToken();
      if (token != null) {
        ApiService.setAuthToken(token);
        
        // Get current user profile
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
          
          // Update FCM token on server
          await NotificationService.updateFCMTokenOnServer();
        } else {
          // Token might be expired, clear it
          await _clearAuthData();
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await _clearAuthData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginRequest = LoginRequest(email: email, password: password);
      final authUser = await _authRepository.login(loginRequest);

      if (authUser != null) {
        // Store tokens
        await StorageService.storeAuthToken(authUser.accessToken);
        if (authUser.refreshToken != null) {
          await StorageService.storeRefreshToken(authUser.refreshToken!);
        }
        
        // Set API token
        ApiService.setAuthToken(authUser.accessToken);
        
        // Store user data
        _currentUser = authUser.user;
        _isAuthenticated = true;
        
        // Store user credentials for biometric login (if enabled)
        if (StorageService.isBiometricEnabled()) {
          await StorageService.storeUserCredentials(email, password);
        }
        
        // Update FCM token on server
        try {
          await NotificationService.updateFCMTokenOnServer();
        } catch (e) {
          debugPrint('FCM token update error: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final registerRequest = RegisterRequest(
        email: userData['email'],
        password: userData['password'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        phone: userData['phone'],
        userType: _getUserTypeFromRole(userData['role']),
        dateOfBirth: userData['dateOfBirth'],
        gender: userData['gender'],
      );
      
      final authUser = await _authRepository.register(registerRequest);

      if (authUser != null) {
        // Store tokens
        await StorageService.storeAuthToken(authUser.accessToken);
        if (authUser.refreshToken != null) {
          await StorageService.storeRefreshToken(authUser.refreshToken!);
        }
        
        // Set API token
        ApiService.setAuthToken(authUser.accessToken);
        
        // Store user data
        _currentUser = authUser.user;
        _isAuthenticated = true;
        
        // Update FCM token on server
        try {
          await NotificationService.updateFCMTokenOnServer();
        } catch (e) {
          debugPrint('FCM token update error: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Registration error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ForgotPasswordRequest(email: email);
      final success = await _authRepository.forgotPassword(request);
      
      if (!success) {
        _errorMessage = 'Failed to send reset email. Please try again.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Forgot password error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ResetPasswordRequest(token: token, newPassword: newPassword);
      final success = await _authRepository.resetPassword(request);
      
      if (!success) {
        _errorMessage = 'Failed to reset password. Please try again.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Reset password error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      final success = await _authRepository.changePassword(request);
      
      if (!success) {
        _errorMessage = 'Failed to change password. Please check your current password.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Change password error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest updateRequest) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authRepository.updateProfile(updateRequest);
      
      if (updatedUser != null) {
        _currentUser = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update profile. Please try again.';
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Update profile error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> uploadProfilePicture(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authRepository.uploadProfilePicture(filePath);
      
      if (updatedUser != null) {
        _currentUser = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to upload profile picture. Please try again.';
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Upload profile picture error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Call logout API
      await _authRepository.logout();
    } catch (e) {
      debugPrint('Logout API error: $e');
    }

    // Clear all user data regardless of API call result
    await _clearAuthData();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    
    // Clear stored data
    await StorageService.clearAllUserData();
    ApiService.clearAuthToken();
    
    // Cancel all notifications
    await NotificationService.cancelAllNotifications();
  }

  Future<void> completeOnboarding() async {
    await StorageService.setOnboardingCompleted(true);
    _isOnboarded = true;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
    }
  }

  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.verifyEmail(token);
      
      if (success && _currentUser != null) {
        // Update user verification status
        _currentUser = _currentUser!.copyWith(isVerified: true);
      } else if (!success) {
        _errorMessage = 'Failed to verify email. Please try again.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Email verification error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.resendVerificationEmail();
      
      if (!success) {
        _errorMessage = 'Failed to send verification email. Please try again.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Resend verification email error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.deleteAccount();
      
      if (success) {
        await _clearAuthData();
      } else {
        _errorMessage = 'Failed to delete account. Please try again.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Delete account error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Biometric authentication
  Future<bool> loginWithBiometrics() async {
    try {
      final credentials = await StorageService.getUserCredentials();
      if (credentials != null) {
        return await login(credentials['email']!, credentials['password']!);
      }
    } catch (e) {
      debugPrint('Biometric login error: $e');
    }
    return false;
  }

  Future<void> enableBiometricAuth(bool enable) async {
    await StorageService.setBiometricEnabled(enable);
    
    if (!enable) {
      // Clear stored credentials when disabling biometric auth
      await StorageService.clearUserCredentials();
      await StorageService.clearBiometricKey();
    }
    
    notifyListeners();
  }

  bool get isBiometricEnabled => StorageService.isBiometricEnabled();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
  
  UserType _getUserTypeFromRole(String role) {
    switch (role.toLowerCase()) {
      case 'donor':
      case 'sperm_donor':
        return UserType.spermDonor;
      case 'egg_donor':
        return UserType.eggDonor;
      case 'surrogate':
        return UserType.surrogate;
      case 'hospital':
        return UserType.hospital;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.patient;
    }
  }

  // Check if user profile is complete
  bool get isProfileComplete {
    if (_currentUser == null) return false;
    
    return _currentUser!.profileCompleted &&
           _currentUser!.firstName.isNotEmpty &&
           _currentUser!.lastName.isNotEmpty &&
           _currentUser!.phone != null &&
           _currentUser!.phone!.isNotEmpty;
  }

  // Get user type specific requirements
  bool get needsAdditionalInfo {
    if (_currentUser == null) return false;
    
    switch (_currentUser!.userType) {
      case UserType.spermDonor:
      case UserType.eggDonor:
      case UserType.surrogate:
        // These user types need additional medical information
        return !_currentUser!.profileCompleted;
      case UserType.hospital:
        // Hospitals need verification
        return !_currentUser!.isVerified;
      default:
        return false;
    }
  }

  // Check if user can access certain features
  bool get canBookAppointments {
    return _isAuthenticated && 
           _currentUser != null && 
           _currentUser!.isActive && 
           isProfileComplete;
  }

  bool get canSendMessages {
    return _isAuthenticated && 
           _currentUser != null && 
           _currentUser!.isActive;
  }

  bool get canAccessHospitalFeatures {
    return _isAuthenticated && 
           _currentUser != null && 
           _currentUser!.userType == UserType.hospital &&
           _currentUser!.isVerified;
  }
}
