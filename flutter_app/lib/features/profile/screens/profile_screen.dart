import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../core/repositories/medical_records_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_completion_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MedicalRecordsRepository _medicalRecordsRepo = MedicalRecordsRepository();
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoadingRecords = false;

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  Future<void> _loadMedicalRecords() async {
    setState(() {
      _isLoadingRecords = true;
    });

    try {
      final records = await _medicalRecordsRepo.getMedicalRecords();
      setState(() {
        _medicalRecords = records;
      });
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    } finally {
      setState(() {
        _isLoadingRecords = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: RefreshIndicator(
              onRefresh: () async {
                await authProvider.refreshUser();
                await _loadMedicalRecords();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 32),
                    if (_shouldShowWelcomeBanner(user)) _buildWelcomeBanner(user),
                    if (_shouldShowWelcomeBanner(user)) const SizedBox(height: 24),
                    ProfileCompletionWidget(
                      user: user,
                      onCompleteProfile: () => context.push('/profile/edit'),
                    ),
                    const SizedBox(height: 32),
                    _buildVerificationStatus(user),
                    const SizedBox(height: 32),
                    _buildPersonalInfo(user),
                    const SizedBox(height: 32),
                    if (_shouldShowMedicalRecords(user))
                      _buildMedicalRecordsSection(),
                    if (_shouldShowMedicalRecords(user))
                      const SizedBox(height: 32),
                    _buildProfileActions(),
                    const SizedBox(height: 32),
                    _buildAccountActions(authProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              user.profilePicture != null && user.profilePicture!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.profilePicture!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Profile image error: $error');
                          print('Profile image URL: ${user.profilePicture}');
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
              if (user.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user.userTypeLabel,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (user.gender != null) ...[
            const SizedBox(height: 4),
            Text(
              user.gender!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  user.isVerified 
                      ? Icons.verified 
                      : user.profileCompleted 
                          ? Icons.hourglass_empty
                          : Icons.pending,
                  color: user.isVerified 
                      ? Colors.green 
                      : user.profileCompleted 
                          ? Colors.blue
                          : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isVerified 
                            ? 'Verified' 
                            : user.profileCompleted 
                                ? 'Profile Complete - Pending Verification'
                                : 'Pending Verification',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: user.isVerified 
                                  ? Colors.green 
                                  : user.profileCompleted 
                                      ? Colors.blue
                                      : Colors.orange,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isVerified 
                            ? 'Your account has been verified by our admin team.'
                            : user.profileCompleted
                                ? 'Your profile is complete and pending admin verification. You will be notified once verified.'
                                : 'Please complete your profile and upload required documents for verification.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!user.isVerified && _shouldShowMedicalRecords(user)) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Upload Documents',
                onPressed: () => context.push('/profile/edit'),
                isOutlined: true,
                isFullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user.email),
            if (user.phone != null)
              _buildInfoRow(Icons.phone, 'Phone', user.phone!),
            if (user.dateOfBirth != null)
              _buildInfoRow(
                Icons.cake,
                'Date of Birth',
                '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}',
              ),
            if (user.address != null)
              _buildInfoRow(Icons.location_on, 'Address', user.address!),
            if (user.city != null && user.state != null)
              _buildInfoRow(
                Icons.location_city,
                'Location',
                '${user.city}, ${user.state}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical Records',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push('/profile/edit'),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingRecords)
              const Center(child: CircularProgressIndicator())
            else if (_medicalRecords.isEmpty)
              Text(
                'No medical records uploaded yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              )
            else
              Column(
                children: _medicalRecords.take(3).map((record) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getRecordIcon(_getRecordTypeValue(record.recordType)),
                      color: record.isVerified ? Colors.green : Colors.orange,
                    ),
                    title: Text(record.fileName),
                    subtitle: Text(record.description ?? 'No description'),
                    trailing: Icon(
                      record.isVerified ? Icons.verified : Icons.pending,
                      color: record.isVerified ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  );
                }).toList(),
              ),
            if (_medicalRecords.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                'And ${_medicalRecords.length - 3} more records...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          Icons.edit,
          'Edit Profile',
          'Update your personal information',
          () => context.push('/profile/edit'),
        ),
        _buildActionTile(
          Icons.security,
          'Security',
          'Change password and security settings',
          () => context.push('/profile/security'),
        ),
        _buildActionTile(
          Icons.notifications,
          'Notifications',
          'Manage notification preferences',
          () => context.push('/profile/notifications'),
        ),
        _buildActionTile(
          Icons.privacy_tip,
          'Privacy',
          'Privacy settings and data control',
          () => context.push('/profile/privacy'),
        ),
        _buildActionTile(
          Icons.payment,
          'Payments',
          'Payment methods and billing',
          () => context.push('/profile/payments'),
        ),
      ],
    );
  }

  Widget _buildAccountActions(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          Icons.help,
          'Support',
          'Get help and contact support',
          () => context.push('/support'),
        ),
        _buildActionTile(
          Icons.info,
          'About',
          'App information and version',
          () => context.push('/about'),
        ),
        _buildActionTile(
          Icons.logout,
          'Sign Out',
          'Sign out of your account',
          () => _showSignOutDialog(authProvider),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getRecordTypeValue(MedicalRecordType recordType) {
    switch (recordType) {
      case MedicalRecordType.license:
        return 'LICENSE';
      case MedicalRecordType.certification:
        return 'CERTIFICATION';
      case MedicalRecordType.diploma:
        return 'DIPLOMA';
      case MedicalRecordType.identification:
        return 'IDENTIFICATION';
      case MedicalRecordType.medicalHistory:
        return 'MEDICAL_HISTORY';
      case MedicalRecordType.labResults:
        return 'LAB_RESULTS';
      case MedicalRecordType.other:
        return 'OTHER';
    }
  }

  IconData _getRecordIcon(String recordType) {
    switch (recordType.toUpperCase()) {
      case 'LICENSE':
        return Icons.badge;
      case 'CERTIFICATION':
        return Icons.verified;
      case 'DIPLOMA':
        return Icons.school;
      case 'IDENTIFICATION':
        return Icons.person;
      case 'MEDICAL_HISTORY':
        return Icons.medical_information;
      case 'LAB_RESULTS':
        return Icons.science;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _shouldShowMedicalRecords(User user) {
    // Show medical records section for all user types except patient
    return user.userType != UserType.patient;
  }

  bool _shouldShowWelcomeBanner(User user) {
    // Show welcome banner for users with incomplete profiles (less than 60% complete)
    // or if profile is not marked as completed
    final completionPercentage = _calculateCompletionPercentage(user);
    return completionPercentage < 60 || !user.profileCompleted;
  }

  double _calculateCompletionPercentage(User user) {
    int completedFields = 0;
    int totalFields = 0;

    // Basic information (required)
    totalFields += 4; // firstName, lastName, email, userType
    completedFields += 4; // These are always present

    // Profile information (optional but important)
    totalFields += 1; // phone
    if (user.phone != null && user.phone!.isNotEmpty) completedFields += 1;

    totalFields += 1; // dateOfBirth
    if (user.dateOfBirth != null) completedFields += 1;

    totalFields += 1; // gender
    if (user.gender != null && user.gender!.isNotEmpty) completedFields += 1;

    totalFields += 1; // profilePicture
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) completedFields += 1;

    totalFields += 1; // bio
    if (user.bio != null && user.bio!.isNotEmpty) completedFields += 1;

    // Location information
    totalFields += 1; // address
    if (user.address != null && user.address!.isNotEmpty) completedFields += 1;

    totalFields += 1; // city
    if (user.city != null && user.city!.isNotEmpty) completedFields += 1;

    totalFields += 1; // state
    if (user.state != null && user.state!.isNotEmpty) completedFields += 1;

    totalFields += 1; // country
    if (user.country != null && user.country!.isNotEmpty) completedFields += 1;

    totalFields += 1; // postalCode
    if (user.postalCode != null && user.postalCode!.isNotEmpty) completedFields += 1;

    return (completedFields / totalFields) * 100;
  }

  Widget _buildWelcomeBanner(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConfig.mediumBorderRadius),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome to Fertility Services!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We\'re excited to have you on board! To get the most out of our services, please complete your profile and add your medical information.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Complete Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/medical-records'),
                  icon: const Icon(Icons.medical_information),
                  label: const Text('Add Medical Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
