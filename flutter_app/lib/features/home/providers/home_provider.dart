import 'package:flutter/foundation.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/repositories/services_repository.dart';
import '../../../core/repositories/medical_records_repository.dart';
import '../../../core/repositories/payment_repository.dart';
import '../../appointments/repositories/appointments_repository.dart';
import '../../messages/repositories/messages_repository.dart';
import '../../wallet/providers/wallet_provider.dart';

class HomeProvider extends ChangeNotifier {
  final ServicesRepository _servicesRepository = ServicesRepository();
  final AppointmentsRepository _appointmentsRepository = AppointmentsRepository();
  final MessagesRepository _messagesRepository = MessagesRepository();
  final MedicalRecordsRepository _medicalRecordsRepository = MedicalRecordsRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  
  List<dynamic> _services = [];
  List<dynamic> _featuredServices = [];
  List<AppointmentModel> _recentAppointments = [];
  List<dynamic> _recentActivity = [];
  int _unreadMessageCount = 0;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<dynamic> get services => _services;
  List<dynamic> get featuredServices => _featuredServices;
  List<AppointmentModel> get recentAppointments => _recentAppointments;
  List<dynamic> get recentActivity => _recentActivity;
  int get unreadMessageCount => _unreadMessageCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    debugPrint('🏠 HomeProvider.loadHomeData() started (forceRefresh: $forceRefresh)');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📡 Loading home data individually to handle failures gracefully...');
      
      // Load services (critical for home screen)
      try {
        _services = await _servicesRepository.getServices(limit: 10);
        debugPrint('✅ Services loaded: ${_services.length}');
      } catch (e) {
        debugPrint('❌ Failed to load services: $e');
        _services = [];
      }

      // Load featured services (critical for home screen)
      try {
        _featuredServices = await _servicesRepository.getFeaturedServices();
        debugPrint('✅ Featured services loaded: ${_featuredServices.length}');
        
        // Debug log featured services data
        for (int i = 0; i < _featuredServices.length; i++) {
          final service = _featuredServices[i];
          debugPrint('   Featured Service $i: ${service['name']} (${service['service_type']}) - Active: ${service['is_active']}');
        }
      } catch (e) {
        debugPrint('❌ Failed to load featured services: $e');
        _featuredServices = [];
      }

      // Load appointments (non-critical, can fail)
      try {
        _recentAppointments = await _appointmentsRepository.getMyAppointments(limit: 5);
        debugPrint('✅ Recent appointments loaded: ${_recentAppointments.length}');
      } catch (e) {
        debugPrint('❌ Failed to load appointments (non-critical): $e');
        _recentAppointments = [];
      }

      // Load unread message count (non-critical, can fail)
      try {
        _unreadMessageCount = await _messagesRepository.getUnreadMessageCount();
        debugPrint('✅ Unread message count loaded: $_unreadMessageCount');
      } catch (e) {
        debugPrint('❌ Failed to load unread message count (non-critical): $e');
        _unreadMessageCount = 0;
      }

      debugPrint('✅ Home data loading completed:');
      debugPrint('   - Services: ${_services.length}');
      debugPrint('   - Featured Services: ${_featuredServices.length}');
      debugPrint('   - Recent Appointments: ${_recentAppointments.length}');
      debugPrint('   - Unread Messages: $_unreadMessageCount');

      // Generate recent activity from appointments and messages
      await _generateRecentActivity();
      
      // Clear any previous error since we got some data
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Critical error in load home data: $e');
    } finally {
      _isLoading = false;
      debugPrint('🏠 HomeProvider.loadHomeData() completed - isLoading: $_isLoading');
      notifyListeners();
    }
  }

  Future<void> loadServices({bool forceRefresh = false}) async {
    try {
      final services = await _servicesRepository.getServices();
      _services = services;
      notifyListeners();
    } catch (e) {
      debugPrint('Load services error: $e');
    }
  }

  Future<void> loadFeaturedServices() async {
    try {
      final featuredServices = await _servicesRepository.getFeaturedServices();
      _featuredServices = featuredServices;
      notifyListeners();
    } catch (e) {
      debugPrint('Load featured services error: $e');
    }
  }

  Future<void> loadRecentAppointments() async {
    try {
      final appointments = await _appointmentsRepository.getMyAppointments(limit: 5);
      _recentAppointments = appointments;
      await _generateRecentActivity();
      notifyListeners();
    } catch (e) {
      debugPrint('Load recent appointments error: $e');
    }
  }

  Future<void> loadUnreadMessageCount() async {
    try {
      final count = await _messagesRepository.getUnreadMessageCount();
      _unreadMessageCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Load unread message count error: $e');
    }
  }

  Future<void> _generateRecentActivity() async {
    _recentActivity.clear();

    // Add recent appointments to activity
    for (final appointment in _recentAppointments.take(3)) {
      final now = DateTime.now();
      final appointmentDate = appointment.appointmentDate;
      
      String activityTitle;
      String activityTime;
      String activityIcon;
      String activityColor;

      if (appointmentDate.isAfter(now)) {
        // Upcoming appointment
        final difference = appointmentDate.difference(now);
        if (difference.inDays > 0) {
          activityTime = '${difference.inDays} days from now';
        } else if (difference.inHours > 0) {
          activityTime = '${difference.inHours} hours from now';
        } else {
          activityTime = 'Soon';
        }
        activityTitle = 'Upcoming Appointment';
        activityIcon = 'calendar_today';
        activityColor = 'blue';
      } else {
        // Past appointment
        final difference = now.difference(appointmentDate);
        if (difference.inDays > 0) {
          activityTime = '${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          activityTime = '${difference.inHours} hours ago';
        } else {
          activityTime = 'Recently';
        }
        activityTitle = 'Appointment Completed';
        activityIcon = 'check_circle';
        activityColor = 'green';
      }

      _recentActivity.add({
        'title': activityTitle,
        'subtitle': '${appointment.serviceName} at ${appointment.hospitalName}',
        'time': activityTime,
        'icon': activityIcon,
        'color': activityColor,
        'type': 'appointment',
        'data': appointment,
        'timestamp': appointmentDate,
      });
    }

    // Add wallet transactions activity
    try {
      final walletProvider = WalletProvider();
      await walletProvider.getWalletTransactions();
      
      for (final transaction in walletProvider.transactions.take(3)) {
        final createdAt = DateTime.parse(transaction['created_at']);
        final now = DateTime.now();
        final difference = now.difference(createdAt);
        
        String activityTime;
        if (difference.inDays > 0) {
          activityTime = '${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          activityTime = '${difference.inHours} hours ago';
        } else if (difference.inMinutes > 0) {
          activityTime = '${difference.inMinutes} minutes ago';
        } else {
          activityTime = 'Just now';
        }

        String activityTitle;
        String activityIcon;
        String activityColor;
        
        switch (transaction['transaction_type']) {
          case 'fund':
            activityTitle = 'Wallet Funded';
            activityIcon = 'account_balance_wallet';
            activityColor = 'green';
            break;
          case 'payment':
            activityTitle = 'Payment Made';
            activityIcon = 'payment';
            activityColor = 'blue';
            break;
          case 'withdrawal':
            activityTitle = 'Withdrawal';
            activityIcon = 'money_off';
            activityColor = 'orange';
            break;
          case 'refund':
            activityTitle = 'Refund Received';
            activityIcon = 'money';
            activityColor = 'purple';
            break;
          default:
            activityTitle = 'Wallet Transaction';
            activityIcon = 'account_balance_wallet';
            activityColor = 'grey';
        }

        _recentActivity.add({
          'title': activityTitle,
          'subtitle': '₦${transaction['amount']} - ${transaction['description']}',
          'time': activityTime,
          'icon': activityIcon,
          'color': activityColor,
          'type': 'wallet',
          'data': transaction,
          'timestamp': createdAt,
        });
      }
    } catch (e) {
      debugPrint('Failed to load wallet transactions for activity: $e');
    }

    // Add medical records activity
    try {
      final medicalRecords = await _medicalRecordsRepository.getMedicalRecords();
      
      for (final record in medicalRecords.take(3)) {
        final createdAt = record.createdAt;
        final now = DateTime.now();
        final difference = now.difference(createdAt);
        
        String activityTime;
        if (difference.inDays > 0) {
          activityTime = '${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          activityTime = '${difference.inHours} hours ago';
        } else if (difference.inMinutes > 0) {
          activityTime = '${difference.inMinutes} minutes ago';
        } else {
          activityTime = 'Just now';
        }

        _recentActivity.add({
          'title': 'Medical Record Added',
          'subtitle': record.fileName,
          'time': activityTime,
          'icon': 'medical_services',
          'color': 'red',
          'type': 'medical_record',
          'data': record,
          'timestamp': createdAt,
        });
      }
    } catch (e) {
      debugPrint('Failed to load medical records for activity: $e');
    }

    // Add payment activity (using wallet transactions instead since payment repository doesn't have getPaymentHistory)
    // This is already covered by wallet transactions above, so we'll skip this section

    // Add unread messages activity
    if (_unreadMessageCount > 0) {
      _recentActivity.add({
        'title': 'New Messages',
        'subtitle': 'You have $_unreadMessageCount unread message${_unreadMessageCount > 1 ? 's' : ''}',
        'time': 'Recent',
        'icon': 'message',
        'color': 'orange',
        'type': 'message',
        'data': _unreadMessageCount,
        'timestamp': DateTime.now(),
      });
    }

    // Sort by most recent timestamp
    _recentActivity.sort((a, b) {
      final aTimestamp = a['timestamp'] as DateTime;
      final bTimestamp = b['timestamp'] as DateTime;
      return bTimestamp.compareTo(aTimestamp);
    });

    // Limit to 8 items for better variety
    if (_recentActivity.length > 8) {
      _recentActivity = _recentActivity.take(8).toList();
    }
  }

  List<dynamic> getServicesByCategory(String category) {
    return _services.where((service) => 
        service['category']?.toString().toLowerCase() == category.toLowerCase()
    ).toList();
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
