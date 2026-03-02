import 'package:flutter/foundation.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/api_service.dart';
import '../repositories/hospitals_repository.dart';

class HospitalsProvider extends ChangeNotifier {
  final HospitalsRepository _hospitalsRepository = HospitalsRepository();
  
  List<Hospital> _hospitals = [];
  List<Hospital> _nearbyHospitals = [];
  Hospital? _selectedHospital;
  List<dynamic> _hospitalServices = [];
  List<dynamic> _hospitalDoctors = [];
  List<dynamic> _hospitalReviews = [];
  
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  // Getters
  List<Hospital> get hospitals => _hospitals;
  List<Hospital> get nearbyHospitals => _nearbyHospitals;
  Hospital? get selectedHospital => _selectedHospital;
  List<dynamic> get hospitalServices => _hospitalServices;
  List<dynamic> get hospitalDoctors => _hospitalDoctors;
  List<dynamic> get hospitalReviews => _hospitalReviews;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  Future<void> loadHospitals({
    String? search,
    String? city,
    String? state,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hospitals = await _hospitalsRepository.getHospitals(
        search: search,
        city: city,
        state: state,
      );
      _hospitals = hospitals;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Load hospitals error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyHospitals({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hospitals = await _hospitalsRepository.getNearbyHospitals(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      _nearbyHospitals = hospitals;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Load nearby hospitals error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHospitalDetails(int hospitalId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load hospital details
      final hospital = await _hospitalsRepository.getHospitalById(hospitalId);
      _selectedHospital = hospital;

      // Load hospital services, doctors, and reviews in parallel
      final results = await Future.wait([
        _hospitalsRepository.getHospitalServices(hospitalId),
        _hospitalsRepository.getHospitalDoctors(hospitalId),
        _hospitalsRepository.getHospitalReviews(hospitalId),
      ]);

      _hospitalServices = results[0];
      _hospitalDoctors = results[1];
      _hospitalReviews = results[2];
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Load hospital details error: $e');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> searchHospitals(String query) async {
    if (query.isEmpty) {
      await loadHospitals();
      return;
    }

    await loadHospitals(search: query);
  }

  Future<void> filterHospitalsByLocation(String? city, String? state) async {
    await loadHospitals(city: city, state: state);
  }

  void selectHospital(Hospital hospital) {
    _selectedHospital = hospital;
    notifyListeners();
  }

  void clearSelectedHospital() {
    _selectedHospital = null;
    _hospitalServices.clear();
    _hospitalDoctors.clear();
    _hospitalReviews.clear();
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
