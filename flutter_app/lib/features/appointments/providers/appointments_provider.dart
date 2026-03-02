import 'package:flutter/foundation.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/api_service.dart';
import '../repositories/appointments_repository.dart';

class AppointmentsProvider extends ChangeNotifier {
  final AppointmentsRepository _appointmentsRepository = AppointmentsRepository();
  
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  Future<bool> createAppointment({
    required int hospitalId,
    required int serviceId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    debugPrint('📅 AppointmentsProvider.createAppointment() started');
    _isLoading = true;
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
        _appointments.add(appointment);
        debugPrint('✅ Appointment created successfully: ${appointment.id}');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create appointment';
        debugPrint('❌ Create appointment failed: null response');
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Create appointment error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    debugPrint('📅 AppointmentsProvider.cancelAppointment() started for ID: $appointmentId');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _appointmentsRepository.cancelAppointment(appointmentId);
      
      if (success) {
        // Update local appointment status
        final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
        if (index != -1) {
          _appointments[index] = _appointments[index].copyWith(status: 'cancelled');
        }
        debugPrint('✅ Appointment cancelled successfully: $appointmentId');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to cancel appointment';
        debugPrint('❌ Cancel appointment failed for ID: $appointmentId');
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Cancel appointment error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
