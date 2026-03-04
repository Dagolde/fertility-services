import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/api_service.dart';
import '../repositories/appointments_repository.dart';

class AppointmentsProvider extends ChangeNotifier {
  final AppointmentsRepository _appointmentsRepository = AppointmentsRepository();
  
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Reservation timeout tracking
  final Map<int, Timer> _reservationTimers = {};
  final Map<int, DateTime> _reservationExpirations = {};

  // Getters
  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Get reservation expiration time for an appointment
  DateTime? getReservationExpiration(int appointmentId) {
    return _reservationExpirations[appointmentId];
  }
  
  /// Get remaining seconds for a reservation
  int? getReservationRemainingSeconds(int appointmentId) {
    final expiration = _reservationExpirations[appointmentId];
    if (expiration == null) return null;
    
    final remaining = expiration.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  List<AppointmentModel> get upcomingAppointments {
    return _appointments
        .where((apt) => apt.appointmentDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  List<AppointmentModel> get pastAppointments {
    return _appointments
        .where((apt) => apt.appointmentDate.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  Future<void> loadAppointments({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    debugPrint('📅 AppointmentsProvider.loadAppointments() started');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appointments = await _appointmentsRepository.getMyAppointments();
      debugPrint('✅ Appointments loaded successfully: ${_appointments.length}');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Load appointments error: $e');
    } finally {
      _isLoading = false;
      debugPrint('📅 AppointmentsProvider.loadAppointments() completed');
      notifyListeners();
    }
  }

  /// Book appointment with optimistic update
  Future<bool> bookAppointment({
    required int hospitalId,
    required int serviceId,
    required DateTime appointmentDate,
    String? notes,
    String hospitalName = 'Hospital',
    String serviceName = 'Service',
  }) async {
    debugPrint('📅 AppointmentsProvider.bookAppointment() started');
    
    // Create optimistic appointment
    final optimisticAppointment = AppointmentModel(
      id: -DateTime.now().millisecondsSinceEpoch, // Temporary negative ID
      hospitalName: hospitalName,
      serviceName: serviceName,
      appointmentDate: appointmentDate,
      status: 'pending',
      doctorName: 'Dr. ${hospitalName.split(' ').first}',
      notes: notes,
      hospitalId: hospitalId,
      serviceId: serviceId,
    );
    
    // Optimistic update: Add to list immediately
    _appointments.add(optimisticAppointment);
    _errorMessage = null;
    notifyListeners();

    try {
      final appointment = await _appointmentsRepository.createAppointment(
        hospitalId: hospitalId,
        serviceId: serviceId,
        appointmentDate: appointmentDate,
        notes: notes,
      );

      if (appointment != null) {
        // Replace optimistic appointment with real one
        final index = _appointments.indexWhere((apt) => apt.id == optimisticAppointment.id);
        if (index != -1) {
          _appointments[index] = appointment;
        }
        
        // Start reservation timeout (10 minutes)
        _startReservationTimer(appointment.id);
        
        debugPrint('✅ Appointment booked successfully: ${appointment.id}');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        // Revert optimistic update
        _appointments.removeWhere((apt) => apt.id == optimisticAppointment.id);
        _errorMessage = 'Failed to book appointment';
        debugPrint('❌ Book appointment failed: null response');
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert optimistic update
      _appointments.removeWhere((apt) => apt.id == optimisticAppointment.id);
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Book appointment error: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Legacy method for backward compatibility
  Future<bool> createAppointment({
    required int hospitalId,
    required int serviceId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    return bookAppointment(
      hospitalId: hospitalId,
      serviceId: serviceId,
      appointmentDate: appointmentDate,
      notes: notes,
    );
  }

  /// Cancel appointment with optimistic update
  Future<bool> cancelAppointment(int appointmentId) async {
    debugPrint('📅 AppointmentsProvider.cancelAppointment() started for ID: $appointmentId');
    
    // Store original appointment for rollback
    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index == -1) {
      _errorMessage = 'Appointment not found';
      return false;
    }
    
    final originalAppointment = _appointments[index];
    
    // Optimistic update: Update status immediately
    _appointments[index] = originalAppointment.copyWith(status: 'cancelled');
    _errorMessage = null;
    
    // Cancel reservation timer if exists
    _cancelReservationTimer(appointmentId);
    
    notifyListeners();

    try {
      final success = await _appointmentsRepository.cancelAppointment(appointmentId);
      
      if (success) {
        debugPrint('✅ Appointment cancelled successfully: $appointmentId');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        // Revert optimistic update
        _appointments[index] = originalAppointment;
        _errorMessage = 'Failed to cancel appointment';
        debugPrint('❌ Cancel appointment failed for ID: $appointmentId');
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert optimistic update
      _appointments[index] = originalAppointment;
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Cancel appointment error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Reschedule appointment with optimistic update
  Future<bool> rescheduleAppointment({
    required int appointmentId,
    required DateTime newDate,
  }) async {
    debugPrint('📅 AppointmentsProvider.rescheduleAppointment() started for ID: $appointmentId');
    
    // Store original appointment for rollback
    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index == -1) {
      _errorMessage = 'Appointment not found';
      return false;
    }
    
    final originalAppointment = _appointments[index];
    
    // Optimistic update: Update date immediately
    _appointments[index] = originalAppointment.copyWith(appointmentDate: newDate);
    _errorMessage = null;
    notifyListeners();

    try {
      final appointment = await _appointmentsRepository.rescheduleAppointment(
        appointmentId: appointmentId,
        newDate: newDate,
      );
      
      if (appointment != null) {
        // Replace with server response
        _appointments[index] = appointment;
        
        // Restart reservation timer if needed
        _startReservationTimer(appointment.id);
        
        debugPrint('✅ Appointment rescheduled successfully: $appointmentId');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        // Revert optimistic update
        _appointments[index] = originalAppointment;
        _errorMessage = 'Failed to reschedule appointment';
        debugPrint('❌ Reschedule appointment failed for ID: $appointmentId');
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert optimistic update
      _appointments[index] = originalAppointment;
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Reschedule appointment error: $e');
      notifyListeners();
      return false;
    }
  }

  List<AppointmentModel> getAppointmentsForDay(DateTime day) {
    return _appointments
        .where((apt) => 
            apt.appointmentDate.year == day.year &&
            apt.appointmentDate.month == day.month &&
            apt.appointmentDate.day == day.day)
        .toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Start a 10-minute reservation timer for an appointment
  void _startReservationTimer(int appointmentId) {
    // Cancel existing timer if any
    _cancelReservationTimer(appointmentId);
    
    // Set expiration time (10 minutes from now)
    final expiration = DateTime.now().add(const Duration(minutes: 10));
    _reservationExpirations[appointmentId] = expiration;
    
    // Create timer that fires when reservation expires
    _reservationTimers[appointmentId] = Timer(const Duration(minutes: 10), () {
      debugPrint('⏰ Reservation expired for appointment: $appointmentId');
      _handleReservationExpired(appointmentId);
    });
    
    debugPrint('⏰ Started reservation timer for appointment: $appointmentId, expires at: $expiration');
  }
  
  /// Cancel reservation timer for an appointment
  void _cancelReservationTimer(int appointmentId) {
    _reservationTimers[appointmentId]?.cancel();
    _reservationTimers.remove(appointmentId);
    _reservationExpirations.remove(appointmentId);
  }
  
  /// Handle reservation expiration
  void _handleReservationExpired(int appointmentId) {
    debugPrint('⏰ Handling reservation expiration for appointment: $appointmentId');
    
    // Remove from local list if still pending
    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index != -1 && _appointments[index].status == 'pending') {
      _appointments.removeAt(index);
      _errorMessage = 'Reservation expired. Please book again.';
      notifyListeners();
    }
    
    // Clean up timer references
    _reservationTimers.remove(appointmentId);
    _reservationExpirations.remove(appointmentId);
  }
  
  /// Clean up all timers when provider is disposed
  @override
  void dispose() {
    for (final timer in _reservationTimers.values) {
      timer.cancel();
    }
    _reservationTimers.clear();
    _reservationExpirations.clear();
    super.dispose();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
