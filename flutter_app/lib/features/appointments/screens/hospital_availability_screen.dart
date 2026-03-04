import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/models/service_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/app_config.dart';

class HospitalAvailabilityScreen extends StatefulWidget {
  final Hospital hospital;
  final Service? selectedService;

  const HospitalAvailabilityScreen({
    super.key,
    required this.hospital,
    this.selectedService,
  });

  @override
  State<HospitalAvailabilityScreen> createState() => _HospitalAvailabilityScreenState();
}

class _HospitalAvailabilityScreenState extends State<HospitalAvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Service? _selectedService;
  List<Service> _services = [];
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
  bool _isLoadingServices = false;
  bool _isLoadingSlots = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.selectedService;
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(
        '/services',
        queryParameters: {
          'hospital_id': widget.hospital.id,
          'is_active': true,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> servicesData = response.data;
        setState(() {
          _services = servicesData.map((data) => Service.fromJson(data)).toList();
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load services: ${e.toString()}';
        _isLoadingServices = false;
      });
    }
  }

  Future<void> _loadAvailability(DateTime date) async {
    if (_selectedService == null) return;

    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
      _availableSlots = [];
      _selectedSlot = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await ApiService.get(
        '/hospitals/${widget.hospital.id}/availability',
        queryParameters: {
          'date': dateStr,
          'service_id': _selectedService!.id,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> slotsData = data['slots'] ?? [];
        
        setState(() {
          _availableSlots = slotsData
              .map((slot) => TimeSlot.fromJson(slot))
              .where((slot) => slot.available)
              .toList();
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load availability: ${e.toString()}';
        _isLoadingSlots = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadAvailability(selectedDay);
    }
  }

  void _onServiceSelected(Service? service) {
    setState(() {
      _selectedService = service;
      _selectedDay = null;
      _availableSlots = [];
      _selectedSlot = null;
    });
  }

  void _onSlotSelected(TimeSlot slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  void _confirmBooking() {
    if (_selectedDay == null || _selectedSlot == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to confirmation screen using GoRouter
    context.push(
      '/appointments/confirmation',
      extra: {
        'hospital': widget.hospital,
        'service': _selectedService,
        'appointmentDate': _selectedDay,
        'timeSlot': _selectedSlot!.time,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hospital.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildServiceSelection(),
                    const SizedBox(height: 24),
                    if (_selectedService != null) ...[
                      _buildServiceDetails(),
                      const SizedBox(height: 24),
                      _buildCalendar(),
                      const SizedBox(height: 24),
                      if (_selectedDay != null) _buildTimeSlots(),
                    ],
                    if (_errorMessage != null) _buildErrorMessage(),
                  ],
                ),
              ),
            ),
            if (_selectedSlot != null) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Appointment',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a service, date, and time slot for your appointment',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
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
        const SizedBox(height: 12),
        if (_isLoadingServices)
          const Center(child: CircularProgressIndicator())
        else if (_services.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No services available for this hospital',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<Service>(
            value: _selectedService,
            decoration: InputDecoration(
              labelText: 'Choose Service',
              prefixIcon: const Icon(Icons.medical_services),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _services.map((service) {
              return DropdownMenuItem<Service>(
                value: service,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      service.formattedPrice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: _onServiceSelected,
          ),
      ],
    );
  }

  Widget _buildServiceDetails() {
    if (_selectedService == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedService!.serviceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(
          color: _selectedService!.serviceColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _selectedService!.serviceIcon,
                color: _selectedService!.serviceColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedService!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _selectedService!.serviceTypeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedService!.description != null) ...[
            const SizedBox(height: 12),
            Text(
              _selectedService!.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.attach_money,
                _selectedService!.formattedPrice,
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.access_time,
                _selectedService!.formattedDuration,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).primaryColor,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).primaryColor,
              ),
            ),
            enabledDayPredicate: (day) {
              // Disable past dates
              return day.isAfter(DateTime.now().subtract(const Duration(days: 1)));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Time Slots',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_selectedDay != null)
              Text(
                DateFormat('MMM dd, yyyy').format(_selectedDay!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSlots)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No available slots for this date',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select another date',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedSlot == slot;

              return InkWell(
                onTap: () => _onSlotSelected(slot),
                borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      slot.time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
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

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedSlot!.time} on ${DateFormat('MMM dd').format(_selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Continue to Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSlot {
  final String time;
  final bool available;
  final int durationMinutes;

  TimeSlot({
    required this.time,
    required this.available,
    required this.durationMinutes,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] as String,
      available: json['available'] as bool? ?? true,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.time == time;
  }

  @override
  int get hashCode => time.hashCode;
}
