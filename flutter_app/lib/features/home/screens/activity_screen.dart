import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/home_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HomeProvider>().loadHomeData(forceRefresh: true);
            },
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return LoadingOverlay(
            isLoading: homeProvider.isLoading,
            child: Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: _buildActivityList(homeProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('appointment', 'Appointments'),
                const SizedBox(width: 8),
                _buildFilterChip('wallet', 'Wallet'),
                const SizedBox(width: 8),
                _buildFilterChip('medical_record', 'Medical Records'),
                const SizedBox(width: 8),
                _buildFilterChip('message', 'Messages'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildActivityList(HomeProvider homeProvider) {
    final activities = _getFilteredActivities(homeProvider.recentActivity);

    if (activities.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => homeProvider.loadHomeData(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  List<dynamic> _getFilteredActivities(List<dynamic> activities) {
    var filtered = activities;

    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((activity) => activity['type'] == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((activity) {
        final title = activity['title']?.toString().toLowerCase() ?? '';
        final subtitle = activity['subtitle']?.toString().toLowerCase() ?? '';
        return title.contains(searchTerm) || subtitle.contains(searchTerm);
      }).toList();
    }

    return filtered;
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _handleActivityTap(activity),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getActivityColor(activity['color']).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActivityIcon(activity['icon']),
                  color: _getActivityColor(activity['color']),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] ?? 'Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['subtitle'] ?? 'No description',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity['time'] ?? 'Recently',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                        const Spacer(),
                        _buildActivityStatus(activity),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStatus(Map<String, dynamic> activity) {
    String statusText = '';
    Color statusColor = Colors.grey;

    switch (activity['type']) {
      case 'appointment':
        final appointment = activity['data'] as dynamic;
        if (appointment != null) {
          switch (appointment.status?.toLowerCase()) {
            case 'confirmed':
              statusText = 'Confirmed';
              statusColor = Colors.green;
              break;
            case 'pending':
              statusText = 'Pending';
              statusColor = Colors.orange;
              break;
            case 'completed':
              statusText = 'Completed';
              statusColor = Colors.blue;
              break;
            case 'cancelled':
              statusText = 'Cancelled';
              statusColor = Colors.red;
              break;
          }
        }
        break;
      case 'wallet':
        final transaction = activity['data'] as Map<String, dynamic>?;
        if (transaction != null) {
          switch (transaction['status']?.toLowerCase()) {
            case 'completed':
              statusText = 'Completed';
              statusColor = Colors.green;
              break;
            case 'pending':
              statusText = 'Pending';
              statusColor = Colors.orange;
              break;
            case 'failed':
              statusText = 'Failed';
              statusColor = Colors.red;
              break;
          }
        }
        break;
    }

    if (statusText.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleActivityTap(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'appointment':
        // Navigate to appointment details
        final appointmentData = activity['data'];
        if (appointmentData != null) {
          // Navigate to appointments screen which will show the appointment
          context.push('/appointments');
        }
        break;
      case 'wallet':
        // Navigate to wallet
        context.push('/wallet');
        break;
      case 'medical_record':
        // Navigate to medical records
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to medical records')),
        );
        break;
      case 'message':
        // Navigate to messages
        context.push('/messages');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${activity['title']}')),
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No activities found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'all'
                ? 'Start using the app to see your activity history'
                : 'No ${_selectedFilter.replaceAll('_', ' ')} activities found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Book Appointment',
            onPressed: () => context.push('/appointments'),
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'calendar_today':
        return Icons.calendar_today;
      case 'check_circle':
        return Icons.check_circle;
      case 'message':
        return Icons.message;
      case 'payment':
        return Icons.payment;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'money_off':
        return Icons.money_off;
      case 'money':
        return Icons.money;
      case 'medical_services':
        return Icons.medical_services;
      case 'credit_card':
        return Icons.credit_card;
      case 'hospital':
        return Icons.local_hospital;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
