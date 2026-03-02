import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/users_repository.dart';
import '../services/api_service.dart';

class UsersProvider extends ChangeNotifier {
  final UsersRepository _usersRepository = UsersRepository();
  
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> searchUsers({
    String query = '',
    String? userType,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔍 Searching users with query: "$query"');
      final users = await _usersRepository.searchUsers(
        query: query,
        userType: userType,
      );
      _searchResults = users;
      debugPrint('✅ Found ${users.length} users');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Search users error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults.clear();
    _errorMessage = null;
    notifyListeners();
  }

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
}
