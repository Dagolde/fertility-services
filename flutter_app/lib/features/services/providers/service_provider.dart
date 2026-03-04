import 'package:flutter/foundation.dart';
import '../../../core/models/service_model.dart';
import '../../../core/repositories/services_repository.dart';
import '../../../core/services/storage_service.dart';

class ServiceProvider with ChangeNotifier {
  final ServicesRepository _repository = ServicesRepository();
  final StorageService _storageService = StorageService();
  
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  List<Service> _featuredServices = [];
  String? _selectedCategory;
  String _sortBy = 'name';
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Service> get services => _services;
  List<Service> get filteredServices => _filteredServices;
  List<Service> get featuredServices => _featuredServices;
  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Cache keys
  static const String _cacheKeyServices = 'cached_services';
  static const String _cacheKeyFeatured = 'cached_featured_services';
  static const Duration _cacheDuration = Duration(hours: 1);
  
  ServiceProvider() {
    _loadCachedData();
  }
  
  /// Load services from cache for offline access
  Future<void> _loadCachedData() async {
    try {
      final cachedServices = await _storageService.getCachedData(_cacheKeyServices);
      if (cachedServices != null) {
        _services = (cachedServices as List)
            .map((data) => Service.fromJson(data))
            .toList();
        _applyFiltersAndSort();
      }
      
      final cachedFeatured = await _storageService.getCachedData(_cacheKeyFeatured);
      if (cachedFeatured != null) {
        _featuredServices = (cachedFeatured as List)
            .map((data) => Service.fromJson(data))
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached services: $e');
    }
  }
  
  /// Load all services from API
  Future<void> loadServices({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final servicesData = await _repository.getServices();
      _services = servicesData.map((data) => Service.fromJson(data)).toList();
      
      // Cache the data
      await _storageService.cacheData(
        _cacheKeyServices,
        servicesData,
        duration: _cacheDuration,
      );
      
      _applyFiltersAndSort();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load services: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load featured services
  Future<void> loadFeaturedServices() async {
    try {
      final servicesData = await _repository.getFeaturedServices();
      _featuredServices = servicesData.map((data) => Service.fromJson(data)).toList();
      
      // Cache the data
      await _storageService.cacheData(
        _cacheKeyFeatured,
        servicesData,
        duration: _cacheDuration,
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load featured services: ${e.toString()}');
    }
  }
  
  /// Filter services by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }
  
  /// Sort services
  void sortServices(String sortBy) {
    _sortBy = sortBy;
    _applyFiltersAndSort();
    notifyListeners();
  }
  
  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    List<Service> filtered = List.from(_services);
    
    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((service) => 
        service.category == _selectedCategory
      ).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_high':
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'popularity':
        filtered.sort((a, b) => (b.bookingCount ?? 0).compareTo(a.bookingCount ?? 0));
        break;
      case 'name':
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    
    _filteredServices = filtered;
  }
  
  /// Search services by name or description
  List<Service> searchServices(String query) {
    if (query.isEmpty) {
      return _filteredServices;
    }
    
    final lowerQuery = query.toLowerCase();
    return _filteredServices.where((service) {
      return service.name.toLowerCase().contains(lowerQuery) ||
          (service.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
  
  /// Get service by ID
  Service? getServiceById(int id) {
    try {
      return _services.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear cache
  Future<void> clearCache() async {
    await _storageService.clearCache(_cacheKeyServices);
    await _storageService.clearCache(_cacheKeyFeatured);
    _services = [];
    _filteredServices = [];
    _featuredServices = [];
    notifyListeners();
  }
  
  /// Refresh services
  Future<void> refresh() async {
    await loadServices(forceRefresh: true);
    await loadFeaturedServices();
  }
}
