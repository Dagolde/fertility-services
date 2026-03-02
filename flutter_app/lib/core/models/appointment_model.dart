class AppointmentModel {
  final int id;
  final String hospitalName;
  final String serviceName;
  final DateTime appointmentDate;
  final String status;
  final String doctorName;
  final String? notes;
  final int? userId;
  final int? hospitalId;
  final int? serviceId;

  AppointmentModel({
    required this.id,
    required this.hospitalName,
    required this.serviceName,
    required this.appointmentDate,
    required this.status,
    required this.doctorName,
    this.notes,
    this.userId,
    this.hospitalId,
    this.serviceId,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Handle nested hospital and service objects from backend
    String hospitalName = '';
    String serviceName = '';
    String doctorName = '';
    
    if (json['hospital'] != null) {
      hospitalName = json['hospital']['name'] ?? '';
    } else {
      hospitalName = json['hospital_name'] ?? '';
    }
    
    if (json['service'] != null) {
      serviceName = json['service']['name'] ?? '';
    } else {
      serviceName = json['service_name'] ?? '';
    }
    
    // For now, use a default doctor name since backend doesn't provide this
    doctorName = json['doctor_name'] ?? 'Dr. ${hospitalName.split(' ').first}';
    
    return AppointmentModel(
      id: json['id'],
      hospitalName: hospitalName,
      serviceName: serviceName,
      appointmentDate: DateTime.parse(json['appointment_date']),
      status: json['status'] ?? 'pending',
      doctorName: doctorName,
      notes: json['notes'],
      userId: json['user_id'],
      hospitalId: json['hospital_id'],
      serviceId: json['service_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospital_name': hospitalName,
      'service_name': serviceName,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': status,
      'doctor_name': doctorName,
      'notes': notes,
      'user_id': userId,
      'hospital_id': hospitalId,
      'service_id': serviceId,
    };
  }

  AppointmentModel copyWith({
    int? id,
    String? hospitalName,
    String? serviceName,
    DateTime? appointmentDate,
    String? status,
    String? doctorName,
    String? notes,
    int? userId,
    int? hospitalId,
    int? serviceId,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      serviceName: serviceName ?? this.serviceName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      status: status ?? this.status,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      hospitalId: hospitalId ?? this.hospitalId,
      serviceId: serviceId ?? this.serviceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppointmentModel(id: $id, hospitalName: $hospitalName, serviceName: $serviceName, appointmentDate: $appointmentDate, status: $status, doctorName: $doctorName)';
  }
}
