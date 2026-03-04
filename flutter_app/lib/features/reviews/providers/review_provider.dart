import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class ReviewProvider with ChangeNotifier {
  List<dynamic> _reviews = [];
  bool _isLoading = false;
  String? _error;
  
  int? _selectedRatingFilter;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  
  double _averageRating = 0.0;
  Map<String, int> _ratingDistribution = {};
  
  int? _currentHospitalId;

  // Getters
  List<dynamic> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedRatingFilter => _selectedRatingFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMorePages => _hasMorePages;
  double get averageRating => _averageRating;
  Map<String, int> get ratingDistribution => _ratingDistribution;

  /// Load reviews for a hospital
  Future<void> loadReviews({
    required int hospitalId,
    int? ratingFilter,
    bool loadMore = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    
    if (!loadMore) {
      _currentPage = 1;
      _reviews = [];
      _currentHospitalId = hospitalId;
    }
    
    _selectedRatingFilter = ratingFilter;
    notifyListeners();

    try {
      final queryParams = {
        'hospital_id': hospitalId.toString(),
        'page': _currentPage.toString(),
        'limit': '20',
      };

      if (ratingFilter != null) {
        queryParams['rating'] = ratingFilter.toString();
      }

      final response = await ApiService.get(
        '/reviews',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final reviewsList = data['reviews'] as List;
        final pagination = data['pagination'];
        
        if (loadMore) {
          _reviews.addAll(reviewsList);
        } else {
          _reviews = reviewsList;
        }
        
        _currentPage = pagination['page'];
        _totalPages = pagination['pages'];
        _hasMorePages = _currentPage < _totalPages;
        _averageRating = (data['average_rating'] ?? 0.0).toDouble();
        _ratingDistribution = Map<String, int>.from(
          data['rating_distribution']?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {}
        );
        
        _isLoading = false;
        _error = null;
      } else {
        _isLoading = false;
        _error = 'Failed to load reviews: ${response.statusCode}';
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
    }
    
    notifyListeners();
  }

  /// Load more reviews (pagination)
  Future<void> loadMoreReviews() async {
    if (_hasMorePages && !_isLoading && _currentHospitalId != null) {
      _currentPage++;
      await loadReviews(
        hospitalId: _currentHospitalId!,
        ratingFilter: _selectedRatingFilter,
        loadMore: true,
      );
    }
  }

  /// Submit a new review
  Future<bool> submitReview({
    required int hospitalId,
    required int appointmentId,
    required int rating,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/reviews',
        data: {
          'hospital_id': hospitalId,
          'appointment_id': appointmentId,
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        _error = null;
        notifyListeners();
        
        // Reload reviews to include the new one
        await loadReviews(hospitalId: hospitalId);
        
        return true;
      } else {
        _isLoading = false;
        _error = 'Failed to submit review: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Flag a review for moderation
  Future<bool> flagReview({
    required int reviewId,
    String? reason,
  }) async {
    try {
      final response = await ApiService.post(
        '/reviews/$reviewId/flag',
        data: {
          'reason': reason ?? 'User reported',
        },
      );

      if (response.statusCode == 200) {
        // Update the review in the local list
        final reviewIndex = _reviews.indexWhere((r) => r['id'] == reviewId);
        if (reviewIndex != -1) {
          _reviews[reviewIndex] = response.data;
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Failed to flag review: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a review (within 48 hours)
  Future<bool> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (rating != null) data['rating'] = rating;
      if (comment != null) data['comment'] = comment;

      final response = await ApiService.put(
        '/reviews/$reviewId',
        data: data,
      );

      if (response.statusCode == 200) {
        // Update the review in the local list
        final reviewIndex = _reviews.indexWhere((r) => r['id'] == reviewId);
        if (reviewIndex != -1) {
          _reviews[reviewIndex] = response.data;
        }
        
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = 'Failed to update review: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Apply rating filter
  void applyRatingFilter(int? rating) {
    if (_currentHospitalId != null) {
      loadReviews(
        hospitalId: _currentHospitalId!,
        ratingFilter: rating,
      );
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _reviews = [];
    _isLoading = false;
    _error = null;
    _selectedRatingFilter = null;
    _currentPage = 1;
    _totalPages = 1;
    _hasMorePages = false;
    _averageRating = 0.0;
    _ratingDistribution = {};
    _currentHospitalId = null;
    notifyListeners();
  }
}
