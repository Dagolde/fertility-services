import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../../messages/providers/messages_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    
    await Future.wait([
      homeProvider.loadHomeData(),
      messagesProvider.loadUnreadCount(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<HomeProvider, MessagesProvider>(
          builder: (context, homeProvider, messagesProvider, _) {
            if (homeProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(messagesProvider.unreadCount),
                    _buildBanner(homeProvider.featuredServices),
                    _buildQuickActions(),
                    _buildServices(homeProvider.services),
                    _buildRecentActivity(homeProvider.recentActivity),
                    _buildFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        return Container(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: user?.profileImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user!.profileImageUrl!,
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.person),
                      )
                    : Icon(
                        Icons.person,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Text(
                      user?.fullName ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.push('/messages'),
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner(List<dynamic> featuredServices) {
    final bannerData = featuredServices.isNotEmpty 
        ? featuredServices.take(3).map((service) => {
            'title': service['name'] ?? 'Featured Service',
            'subtitle': service['description'] ?? 'Professional fertility services',
            'image': service['image_url'],
          }).toList()
        : [
            {
              'title': 'Sperm Donation Services',
              'subtitle': 'Help couples achieve their dreams',
              'image': null,
            },
            {
              'title': 'Egg Donation Program',
              'subtitle': 'Give the gift of life',
              'image': null,
            },
            {
              'title': 'Surrogacy Support',
              'subtitle': 'Complete surrogacy solutions',
              'image': null,
            },
          ];
    return Container(
      height: 200,
      margin: const EdgeInsets.all(AppConfig.defaultPadding),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: bannerData.length,
        itemBuilder: (context, index) {
          final banner = bannerData[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner['title']!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner['subtitle']!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.calendar_today,
                  title: 'Book Appointment',
                  onTap: () => context.push('/appointments/book'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.local_hospital,
                  title: 'Find Hospitals',
                  onTap: () => context.push('/hospitals'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.message,
                  title: 'Messages',
                  onTap: () => context.push('/messages'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.payment,
                  title: 'Payments',
                  onTap: () => context.push('/payments'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServices(List<dynamic> services) {
    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (services.isEmpty)
            _buildEmptyServicesState()
          else
            ...services.take(3).map((service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildServiceCard(
                title: service['name'] ?? 'Service',
                description: service['description'] ?? 'Professional fertility service',
                icon: _getServiceIcon(service['service_type']),
                color: _getServiceColor(service['service_type']),
                onTap: () => context.push('/services/${service['id']}'),
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<dynamic> recentActivity) {
    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => context.push('/activity'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentActivity.isEmpty)
            _buildEmptyActivityState()
          else
            ...recentActivity.map((activity) => _buildActivityItem(
              title: activity['title'] ?? 'Activity',
              subtitle: activity['subtitle'] ?? 'Recent activity',
              time: activity['time'] ?? 'Recently',
              icon: _getActivityIcon(activity['icon']),
              color: _getActivityColor(activity['color']),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate based on activity type
          // This could be enhanced to navigate to specific screens
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing $title'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyServicesState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No services available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Services will appear here once loaded',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book appointments, fund your wallet, or upload medical records to see activity here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Book Appointment',
            onPressed: () => context.push('/appointments'),
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'sperm_donation':
        return Icons.favorite;
      case 'egg_donation':
        return Icons.favorite_border;
      case 'surrogacy':
        return Icons.child_care;
      case 'consultation':
        return Icons.medical_services;
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getServiceColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'sperm_donation':
        return Colors.blue;
      case 'egg_donation':
        return Colors.pink;
      case 'surrogacy':
        return Colors.green;
      case 'consultation':
        return Colors.orange;
      default:
        return Colors.purple;
    }
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

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.all(AppConfig.defaultPadding),
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Column(
        children: [
          Text(
            'Need Help?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is available 24/7 to assist you with any questions or concerns.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Contact Support',
            onPressed: () => context.push('/support'),
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}
