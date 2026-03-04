import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/appointment_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/appointments_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    
    // Load appointments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsProvider>().loadAppointments();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh appointments when app becomes visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppointmentsProvider>().loadAppointments(forceRefresh: true);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AppointmentsProvider>().loadAppointments(forceRefresh: true);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => context.push('/appointments/book'),
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: Consumer<AppointmentsProvider>(
        builder: (context, appointmentsProvider, child) {
          if (appointmentsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appointmentsProvider.errorMessage != null) {
            return _buildErrorState(appointmentsProvider.errorMessage!);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingTab(appointmentsProvider),
              _buildPastTab(appointmentsProvider),
              _buildCalendarTab(appointmentsProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/appointments/book'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Appointments',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: () {
                context.read<AppointmentsProvider>().loadAppointments(forceRefresh: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(AppointmentsProvider appointmentsProvider) {
    final upcomingAppointments = appointmentsProvider.upcomingAppointments;

    if (upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: 'No Upcoming Appointments',
        subtitle: 'Book your first appointment to get started',
        actionText: 'Book Appointment',
        onAction: () => context.push('/appointments/book'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => appointmentsProvider.loadAppointments(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        itemCount: upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = upcomingAppointments[index];
          return _buildAppointmentCard(appointment, appointmentsProvider);
        },
      ),
    );
  }

  Widget _buildPastTab(AppointmentsProvider appointmentsProvider) {
    final pastAppointments = appointmentsProvider.pastAppointments;

    if (pastAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Past Appointments',
        subtitle: 'Your appointment history will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => appointmentsProvider.loadAppointments(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        itemCount: pastAppointments.length,
        itemBuilder: (context, index) {
          final appointment = pastAppointments[index];
          return _buildAppointmentCard(appointment, appointmentsProvider);
        },
      ),
    );
  }

  Widget _buildCalendarTab(AppointmentsProvider appointmentsProvider) {
    return Column(
      children: [
        TableCalendar<AppointmentModel>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) {
            return appointmentsProvider.getAppointmentsForDay(day);
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildSelectedDayAppointments(appointmentsProvider),
        ),
      ],
    );
  }

  Widget _buildSelectedDayAppointments(AppointmentsProvider appointmentsProvider) {
    final selectedDayAppointments = appointmentsProvider.getAppointmentsForDay(_selectedDay);

    if (selectedDayAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments on ${DateFormat('MMM dd, yyyy').format(_selectedDay)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
      itemCount: selectedDayAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedDayAppointments[index];
        return _buildAppointmentCard(appointment, appointmentsProvider);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, AppointmentsProvider appointmentsProvider) {
    final isUpcoming = appointment.appointmentDate.isAfter(DateTime.now());
    final statusColor = _getStatusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment, appointmentsProvider),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.serviceName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.hospitalName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.appointmentDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (appointment.doctorName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appointment.doctorName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              if (isUpcoming && appointment.status != 'cancelled') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rescheduleAppointment(appointment),
                        child: const Text('Reschedule'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelAppointment(appointment, appointmentsProvider),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isUpcoming && appointment.status == 'completed') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _writeReview(appointment),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Write Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/hospitals/${appointment.hospitalId}/reviews',
                          extra: {'hospitalName': appointment.hospitalName},
                        ),
                        icon: const Icon(Icons.reviews, size: 18),
                        label: const Text('View Reviews'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: actionText,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment, AppointmentsProvider appointmentsProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(AppConfig.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Appointment Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Service', appointment.serviceName),
                  _buildDetailRow('Hospital', appointment.hospitalName),
                  if (appointment.doctorName.isNotEmpty)
                    _buildDetailRow('Doctor', appointment.doctorName),
                  _buildDetailRow(
                    'Date & Time',
                    DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.appointmentDate),
                  ),
                  _buildDetailRow('Status', appointment.status.toUpperCase()),
                  if (appointment.notes != null && appointment.notes!.isNotEmpty)
                    _buildDetailRow('Notes', appointment.notes!),
                  const SizedBox(height: 24),
                  if (appointment.appointmentDate.isAfter(DateTime.now()) && 
                      appointment.status != 'cancelled') ...[
                    CustomButton(
                      text: 'Reschedule Appointment',
                      onPressed: () {
                        Navigator.pop(context);
                        _rescheduleAppointment(appointment);
                      },
                      isOutlined: true,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Cancel Appointment',
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelAppointment(appointment, appointmentsProvider);
                      },
                      isOutlined: true,
                      backgroundColor: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _writeReview(AppointmentModel appointment) {
    context.push(
      '/reviews/submit',
      extra: {
        'hospitalId': appointment.hospitalId,
        'appointmentId': appointment.id,
        'hospitalName': appointment.hospitalName,
      },
    );
  }

  void _rescheduleAppointment(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RescheduleBottomSheet(
        appointment: appointment,
        onReschedule: (newDate) async {
          final provider = context.read<AppointmentsProvider>();
          final success = await provider.rescheduleAppointment(
            appointmentId: appointment.id,
            newDate: newDate,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success 
                    ? 'Appointment rescheduled successfully' 
                    : provider.errorMessage ?? 'Failed to reschedule appointment'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _cancelAppointment(AppointmentModel appointment, AppointmentsProvider appointmentsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await appointmentsProvider.cancelAppointment(appointment.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Appointment cancelled successfully' 
                        : appointmentsProvider.errorMessage ?? 'Failed to cancel appointment'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class _RescheduleBottomSheet extends StatefulWidget {
  final AppointmentModel appointment;
  final Function(DateTime) onReschedule;

  const _RescheduleBottomSheet({
    required this.appointment,
    required this.onReschedule,
  });

  @override
  State<_RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<_RescheduleBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.appointmentDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.appointmentDate);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppConfig.defaultPadding,
        right: AppConfig.defaultPadding,
        top: AppConfig.defaultPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reschedule Appointment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.appointment.serviceName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Current Date & Time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(widget.appointment.appointmentDate),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'New Date & Time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Confirm Reschedule',
            onPressed: () {
              final newDateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
              
              Navigator.pop(context);
              widget.onReschedule(newDateTime);
            },
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            isOutlined: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
