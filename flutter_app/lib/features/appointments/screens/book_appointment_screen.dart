import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/simple_text_field.dart';
import '../providers/appointments_provider.dart';
import '../../hospitals/providers/hospitals_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? hospitalId;
  
  const BookAppointmentScreen({
    super.key,
    this.hospitalId,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String? _selectedHospital;
  String? _selectedDoctor;
  String? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _appointmentType = 'Consultation';
  bool _isUrgent = false;
  bool _isLoading = false;

  List<Hospital> _hospitals = [];
  List<User> _doctors = [];
  List<dynamic> _services = [];

  final List<String> _appointmentTypes = [
    'Consultation',
    'Treatment',
    'Follow-up',
    'Emergency',
  ];

  final List<String> _timeSlots = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadHospitals();
      await _loadServices();
      
      if (widget.hospitalId != null) {
        // Only set the selected hospital if the ID exists in our hospitals list
        final hospitalExists = _hospitals.any((hospital) => hospital.id.toString() == widget.hospitalId);
        if (hospitalExists) {
          _selectedHospital = widget.hospitalId;
          await _loadDoctorsForHospital(int.parse(widget.hospitalId!));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHospitals() async {
    try {
      final response = await ApiService.get('/hospitals/search');
      if (response.statusCode == 200) {
        final List<dynamic> hospitalsData = response.data;
        setState(() {
          _hospitals = hospitalsData.map((data) => Hospital.fromJson(data)).toList();
        });
      }
    } catch (e) {
      print('Error loading hospitals: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      final response = await ApiService.get('/services');
      if (response.statusCode == 200) {
        setState(() {
          _services = response.data;
        });
      }
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadDoctorsForHospital(int hospitalId) async {
    try {
      final response = await ApiService.get('/hospitals/$hospitalId/doctors');
      if (response.statusCode == 200) {
        final List<dynamic> doctorsData = response.data;
        setState(() {
          _doctors = doctorsData.map((data) => User.fromJson(data)).toList();
          _selectedDoctor = null; // Reset doctor selection when hospital changes
        });
      }
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _doctors = [];
        _selectedDoctor = null;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConfig.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildHospitalSelection(),
                      const SizedBox(height: 16),
                      _buildDoctorSelection(),
                      const SizedBox(height: 16),
                      _buildServiceSelection(),
                      const SizedBox(height: 24),
                      _buildAppointmentTypeSelection(),
                      const SizedBox(height: 24),
                      _buildDateSelection(),
                      const SizedBox(height: 16),
                      _buildTimeSlotSelection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                      const SizedBox(height: 16),
                      _buildUrgentToggle(),
                      const SizedBox(height: 32),
                      _buildBookingButton(),
                      const SizedBox(height: 20), // Extra bottom padding
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Your Appointment',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred hospital, doctor, and time slot for your appointment.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildHospitalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Hospital',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedHospital,
          decoration: const InputDecoration(
            labelText: 'Choose Hospital',
            prefixIcon: Icon(Icons.local_hospital),
            border: OutlineInputBorder(),
          ),
          items: _hospitals.map((hospital) {
            return DropdownMenuItem<String>(
              value: hospital.id.toString(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hospital.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (hospital.address != null)
                    Text(
                      hospital.address!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedHospital = value;
              _selectedDoctor = null; // Reset doctor selection
              _doctors = []; // Clear doctors list
            });
            
            if (value != null) {
              await _loadDoctorsForHospital(int.parse(value));
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a hospital';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDoctorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Doctor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDoctor,
          decoration: const InputDecoration(
            labelText: 'Choose Doctor',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          items: _doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor.id.toString(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doctor.fullName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    doctor.userTypeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _selectedHospital != null
              ? (value) {
                  setState(() {
                    _selectedDoctor = value;
                  });
                }
              : null,
          validator: (value) {
            if (value == null) {
              return 'Please select a doctor';
            }
            return null;
          },
        ),
        if (_selectedHospital != null && _doctors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No doctors available for this hospital',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[600],
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Service',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedService,
          decoration: const InputDecoration(
            labelText: 'Choose Service',
            prefixIcon: Icon(Icons.medical_services),
            border: OutlineInputBorder(),
          ),
          items: _services.map<DropdownMenuItem<String>>((service) {
            final serviceName = service['name'] ?? service.toString();
            return DropdownMenuItem<String>(
              value: serviceName,
              child: Text(serviceName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedService = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a service';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _appointmentTypes.map((type) {
            final isSelected = _appointmentType == type;
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _appointmentType = type;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Choose Date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
                        ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = _timeSlots[index];
            final isSelected = _selectedTimeSlot == timeSlot;
            final isAvailable = _isTimeSlotAvailable(timeSlot);
            
            return InkWell(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedTimeSlot = timeSlot;
                      });
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : isAvailable
                          ? Colors.grey[100]
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    timeSlot,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isAvailable
                              ? Colors.black87
                              : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
          SimpleTextField(
            controller: _notesController,
            labelText: 'Any specific concerns or requirements?',
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
      ],
    );
  }

  Widget _buildUrgentToggle() {
    return Row(
      children: [
        Switch(
          value: _isUrgent,
          onChanged: (value) {
            setState(() {
              _isUrgent = value;
            });
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urgent Appointment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Mark as urgent if you need immediate attention',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton() {
    return CustomButton(
      text: 'Book Appointment',
      onPressed: _canBookAppointment() ? _bookAppointment : null,
    );
  }

  bool _canBookAppointment() {
    return _selectedHospital != null &&
        _selectedDoctor != null &&
        _selectedService != null &&
        _selectedDate != null &&
        _selectedTimeSlot != null;
  }

  bool _isTimeSlotAvailable(String timeSlot) {
    // In a real app, this would check against actual availability
    // For demo purposes, make some slots unavailable
    final unavailableSlots = ['10:30 AM', '2:30 PM', '4:30 PM'];
    return !unavailableSlots.contains(timeSlot);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
    }
  }

  void _bookAppointment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hospital = _hospitals.firstWhere((h) => h.id.toString() == _selectedHospital);
    final doctor = _doctors.firstWhere((d) => d.id.toString() == _selectedDoctor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hospital: ${hospital.name}'),
              const SizedBox(height: 4),
              Text('Doctor: ${doctor.fullName}'),
              const SizedBox(height: 4),
              Text('Service: $_selectedService'),
              const SizedBox(height: 4),
              Text('Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
              const SizedBox(height: 4),
              Text('Time: $_selectedTimeSlot'),
              const SizedBox(height: 4),
              Text('Type: $_appointmentType'),
              if (_isUrgent) ...[
                const SizedBox(height: 4),
                const Text('Priority: Urgent', style: TextStyle(color: Colors.red)),
              ],
              if (_notesController.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Notes: ${_notesController.text}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmBooking();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (_selectedHospital == null || _selectedService == null || _selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      // Parse time slot
      final timeSlot = _selectedTimeSlot!;
      int hour = 0;
      int minute = 0;
      final timeParts = timeSlot.split(' ');
      final timeString = timeParts[0];
      final period = timeParts[1];
      final hourMinute = timeString.split(':');
      hour = int.parse(hourMinute[0]);
      minute = int.parse(hourMinute[1]);
      if (period == 'PM' && hour != 12) hour += 12;
      else if (period == 'AM' && hour == 12) hour = 0;
      final appointmentDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour, minute,
      );
      int? serviceId;
      for (final service in _services) {
        if (service['name'] == _selectedService) {
          serviceId = service['id'];
          break;
        }
      }
      if (serviceId == null) throw Exception('Service not found');
      // 1. Fetch available gateways
      final token = await StorageService.getSecureString('auth_token');
      if (token == null) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated.'), backgroundColor: Colors.red),
        );
        return;
      }
      final gatewaysResp = await ApiService.post(
        '/booking/initiate-booking?service_id=$serviceId&appointment_date=${Uri.encodeComponent(appointmentDateTime.toIso8601String())}',
        data: {},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final gateways = List<Map<String, dynamic>>.from(gatewaysResp.data['available_gateways']);
      // 2. Show gateway selection dialog
      String? selectedGateway = await showDialog<String>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Select Payment Method'),
            children: gateways.map((g) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, g['gateway']),
              child: Text(g['display_name']),
            )).toList(),
          );
        },
      );
      if (selectedGateway == null) {
        setState(() { _isLoading = false; });
        return;
      }
      // 3. Initiate payment/booking
      final paymentResp = await ApiService.post(
        '/booking/initiate-booking?service_id=$serviceId&appointment_date=${Uri.encodeComponent(appointmentDateTime.toIso8601String())}&payment_method=$selectedGateway',
        data: {},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (selectedGateway == 'wallet') {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked and paid from wallet!'), backgroundColor: Colors.green),
        );
        // Refresh appointments before navigating
        await context.read<AppointmentsProvider>().loadAppointments(forceRefresh: true);
        context.go('/appointments');
        return;
      } else {
        // Enhanced payment URL launching
        final paymentUrl = paymentResp.data['payment_url'];
        final reference = paymentResp.data['reference'];
        
        // Show payment dialog
        _showPaymentDialog(paymentUrl, reference);
        
        // After payment, verify (could be improved with deep link or polling)
        final verifyResp = await ApiService.post(
          '/booking/verify-payment',
          data: {'reference': reference},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        setState(() { _isLoading = false; });
        if (verifyResp.data['appointment_id'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment verified, appointment booked!'), backgroundColor: Colors.green),
          );
          // Refresh appointments before navigating
          await context.read<AppointmentsProvider>().loadAppointments(forceRefresh: true);
          context.go('/appointments');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment verification failed.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      
      // Handle authentication errors specifically
      if (e.toString().contains('401') || e.toString().contains('Could not validate credentials')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        // Navigate to login screen
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentDialog(String paymentUrl, String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payment,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'You will be redirected to Paystack to complete your payment securely.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Payment Reference:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reference,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After completing payment, please return to the app to verify your transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchPaymentUrl(paymentUrl, reference);
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPaymentUrl(String paymentUrl, String reference) async {
    try {
      // Try multiple launch modes for better compatibility
      final Uri uri = Uri.parse(paymentUrl);
      
      // Try different launch modes
      final List<LaunchMode> launchModes = [
        LaunchMode.externalApplication,
        LaunchMode.inAppWebView,
        LaunchMode.platformDefault,
        if (Platform.isAndroid) LaunchMode.externalNonBrowserApplication,
      ];

      bool launched = false;
      for (final mode in launchModes) {
        try {
          if (await launchUrl(uri, mode: mode)) {
            launched = true;
            break;
          }
        } catch (e) {
          print('Failed to launch with mode $mode: $e');
          continue;
        }
      }

      if (!launched) {
        // If all launch attempts fail, show copy URL dialog
        _showCopyUrlDialog(paymentUrl, reference);
      }
    } catch (e) {
      print('Error launching URL: $e');
      _showCopyUrlDialog(paymentUrl, reference);
    }
  }

  void _showCopyUrlDialog(String paymentUrl, String reference) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to open payment link automatically. Please copy the link below and open it in your browser:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                paymentUrl,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paymentUrl));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment URL copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }
}
