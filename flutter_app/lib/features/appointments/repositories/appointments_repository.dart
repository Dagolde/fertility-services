import 'package:flutter/foundation.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/api_service.dart';

class AppointmentsRepository {
  static const String _basePath = '/appointments/';

  Future<List<AppointmentModel>> getMyAppointments({
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 AppointmentsRepository.getMyAppointments() called');
      
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      debugPrint('📡 Making API call to: ${_basePath}my-appointments with params: $queryParams');
      final response = await ApiService.get(
        '${_basePath}my-appointments',
        queryParameters: queryParams,
      );

      debugPrint('📦 getMyAppointments response status: ${response.statusCode}');
      debugPrint('📦 getMyAppointments response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> appointmentsJson = response.data;
        debugPrint('📦 Raw appointments data: $appointmentsJson');
        final appointments = appointmentsJson.map((json) => AppointmentModel.fromJson(json)).toList();
        debugPrint('✅ getMyAppointments returning ${appointments.length} appointments');
        for (int i = 0; i < appointments.length; i++) {
          final apt = appointments[i];
          debugPrint('   Appointment $i: ID=${apt.id}, Date=${apt.appointmentDate}, Status=${apt.status}, Service=${apt.serviceName}');
        }
        return appointments;
      }
      debugPrint('❌ getMyAppointments returning empty list due to status code: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ getMyAppointments error: $e');
      rethrow;
    }
  }

  Future<AppointmentModel?> createAppointment({
    required int hospitalId,
    required int serviceId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    try {
      debugPrint('🔍 AppointmentsRepository.createAppointment() called');
      debugPrint('   hospitalId: $hospitalId, serviceId: $serviceId');
      debugPrint('   appointmentDate: $appointmentDate, notes: $notes');
      
      final appointmentData = {
        'hospital_id': hospitalId,
        'service_id': serviceId,
        'appointment_date': appointmentDate.toIso8601String(),
        'notes': notes,
      };

      debugPrint('📡 Making API call to: $_basePath with data: $appointmentData');
      final response = await ApiService.post(
        _basePath,
        data: appointmentData,
      );

      debugPrint('📦 createAppointment response status: ${response.statusCode}');
      debugPrint('📦 createAppointment response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final appointment = AppointmentModel.fromJson(response.data);
        debugPrint('✅ createAppointment successful: ${appointment.id}');
        return appointment;
      }
      debugPrint('❌ createAppointment failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ createAppointment error: $e');
      rethrow;
    }
  }

  Future<AppointmentModel?> getAppointmentById(int appointmentId) async {
    try {
      final response = await ApiService.get('$_basePath$appointmentId');

      if (response.statusCode == 200) {
        return AppointmentModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> updateAppointment({
    required int appointmentId,
    DateTime? appointmentDate,
    String? status,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (appointmentDate != null) {
        data['appointment_date'] = appointmentDate.toIso8601String();
      }
      if (status != null) {
        data['status'] = status;
      }
      if (notes != null) {
        data['notes'] = notes;
      }

      final response = await ApiService.put(
        '$_basePath$appointmentId',
        data: data,
      );

      if (response.statusCode == 200) {
        return AppointmentModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    try {
      final response = await ApiService.delete('$_basePath$appointmentId');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppointmentModel?> rescheduleAppointment({
    required int appointmentId,
    required DateTime newDate,
  }) async {
    try {
      debugPrint('🔍 AppointmentsRepository.rescheduleAppointment() called');
      debugPrint('   appointmentId: $appointmentId, newDate: $newDate');
      
      final response = await ApiService.put(
        '$_basePath$appointmentId/reschedule',
        data: {'new_date': newDate.toIso8601String()},
      );

      debugPrint('📦 rescheduleAppointment response status: ${response.statusCode}');
      debugPrint('📦 rescheduleAppointment response data: ${response.data}');

      if (response.statusCode == 200) {
        final appointment = AppointmentModel.fromJson(response.data);
        debugPrint('✅ rescheduleAppointment successful: ${appointment.id}');
        return appointment;
      }
      debugPrint('❌ rescheduleAppointment failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ rescheduleAppointment error: $e');
      rethrow;
    }
  }
}
