import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_button.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileVisibility = true;
  bool _showOnlineStatus = true;
  bool _allowMessages = true;
  bool _shareLocation = false;
  bool _dataCollection = true;
  bool _personalizedAds = false;
  bool _analyticsTracking = true;
  String _profileVisibilityLevel = 'Public';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePrivacySection(),
            const SizedBox(height: 24),
            _buildCommunicationSection(),
            const SizedBox(height: 24),
            _buildDataPrivacySection(),
            const SizedBox(height: 24),
            _buildLocationSection(),
            const SizedBox(height: 24),
            _buildDataControlSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePrivacySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Privacy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Profile Visibility',
              'Allow others to find and view your profile',
              _profileVisibility,
              (value) => setState(() => _profileVisibility = value),
            ),
            if (_profileVisibility) ...[
              const SizedBox(height: 16),
              Text(
                'Who can see your profile?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildRadioTile('Everyone', 'Public'),
              _buildRadioTile('Registered users only', 'Registered'),
              _buildRadioTile('Matched users only', 'Matched'),
            ],
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Show Online Status',
              'Let others see when you\'re online',
              _showOnlineStatus,
              (value) => setState(() => _showOnlineStatus = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Allow Messages',
              'Let other users send you messages',
              _allowMessages,
              (value) => setState(() => _allowMessages = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.block,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Blocked Users'),
              subtitle: const Text('Manage blocked users'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showBlockedUsers,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.report,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Report History'),
              subtitle: const Text('View your reports'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showReportHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPrivacySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data & Privacy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Data Collection',
              'Allow us to collect usage data to improve the app',
              _dataCollection,
              (value) => setState(() => _dataCollection = value),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Personalized Ads',
              'Show ads based on your interests',
              _personalizedAds,
              (value) => setState(() => _personalizedAds = value),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Analytics Tracking',
              'Help us understand how you use the app',
              _analyticsTracking,
              (value) => setState(() => _analyticsTracking = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Share Location',
              'Allow the app to access your location for better matches',
              _shareLocation,
              (value) => setState(() => _shareLocation = value),
            ),
            if (_shareLocation) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location data is used to show nearby hospitals and services',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataControlSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Control',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.download,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Download My Data'),
              subtitle: const Text('Get a copy of your data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _downloadData,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              title: const Text('Delete My Data'),
              subtitle: const Text('Permanently remove your data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showDeleteDataDialog,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.policy,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('Read our privacy policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showPrivacyPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _profileVisibilityLevel,
      onChanged: (String? value) {
        setState(() => _profileVisibilityLevel = value!);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: 'Save Privacy Settings',
      onPressed: _saveSettings,
      isFullWidth: true,
    );
  }

  void _saveSettings() {
    // TODO: Implement save privacy settings API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings saved successfully')),
    );
  }

  void _showBlockedUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Users'),
        content: const Text('You haven\'t blocked any users yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report History'),
        content: const Text('You haven\'t submitted any reports yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Data'),
        content: const Text(
          'We\'ll prepare your data and send you a download link via email. This may take up to 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data download request submitted'),
                ),
              );
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Data'),
        content: const Text(
          'Are you sure you want to permanently delete all your data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data deletion feature coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'Last updated: ${DateTime.now().year}\n\n'
            '1. Information We Collect\n'
            'We collect information you provide directly to us, such as when you create an account, update your profile, or contact us.\n\n'
            '2. How We Use Your Information\n'
            'We use the information we collect to provide, maintain, and improve our services.\n\n'
            '3. Information Sharing\n'
            'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent.\n\n'
            '4. Data Security\n'
            'We implement appropriate security measures to protect your personal information.\n\n'
            '5. Your Rights\n'
            'You have the right to access, update, or delete your personal information.\n\n'
            'For more information, please contact our support team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
