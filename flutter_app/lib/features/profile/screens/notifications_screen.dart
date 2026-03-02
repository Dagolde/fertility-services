import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Push Notifications
  bool _pushNotifications = true;
  bool _appointmentReminders = true;
  bool _messageNotifications = true;
  bool _matchNotifications = true;
  bool _promotionalNotifications = false;
  
  // Email Notifications
  bool _emailNotifications = true;
  bool _weeklyDigest = true;
  bool _appointmentEmails = true;
  bool _securityEmails = true;
  bool _marketingEmails = false;
  
  // In-App Notifications
  bool _inAppNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Notification Timing
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _quietHoursEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPushNotificationsSection(),
            const SizedBox(height: 24),
            _buildEmailNotificationsSection(),
            const SizedBox(height: 24),
            _buildInAppNotificationsSection(),
            const SizedBox(height: 24),
            _buildQuietHoursSection(),
            const SizedBox(height: 24),
            _buildNotificationHistorySection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPushNotificationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Push Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Enable Push Notifications',
              'Receive notifications on your device',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            if (_pushNotifications) ...[
              const Divider(),
              _buildSwitchTile(
                'Appointment Reminders',
                'Get reminded about upcoming appointments',
                _appointmentReminders,
                (value) => setState(() => _appointmentReminders = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'New Messages',
                'Notification when you receive new messages',
                _messageNotifications,
                (value) => setState(() => _messageNotifications = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'New Matches',
                'Get notified about potential matches',
                _matchNotifications,
                (value) => setState(() => _matchNotifications = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'Promotional Offers',
                'Receive notifications about special offers',
                _promotionalNotifications,
                (value) => setState(() => _promotionalNotifications = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailNotificationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.email,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Enable Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            if (_emailNotifications) ...[
              const Divider(),
              _buildSwitchTile(
                'Weekly Digest',
                'Get a weekly summary of your activity',
                _weeklyDigest,
                (value) => setState(() => _weeklyDigest = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'Appointment Confirmations',
                'Email confirmations for appointments',
                _appointmentEmails,
                (value) => setState(() => _appointmentEmails = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'Security Alerts',
                'Important security-related emails',
                _securityEmails,
                (value) => setState(() => _securityEmails = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'Marketing Emails',
                'Promotional and marketing emails',
                _marketingEmails,
                (value) => setState(() => _marketingEmails = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInAppNotificationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'In-App Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'In-App Notifications',
              'Show notifications while using the app',
              _inAppNotifications,
              (value) => setState(() => _inAppNotifications = value),
            ),
            if (_inAppNotifications) ...[
              const Divider(),
              _buildSwitchTile(
                'Sound',
                'Play sound for notifications',
                _soundEnabled,
                (value) => setState(() => _soundEnabled = value),
              ),
              const Divider(),
              _buildSwitchTile(
                'Vibration',
                'Vibrate for notifications',
                _vibrationEnabled,
                (value) => setState(() => _vibrationEnabled = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quiet Hours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Enable Quiet Hours',
              'Pause notifications during specified hours',
              _quietHoursEnabled,
              (value) => setState(() => _quietHoursEnabled = value),
            ),
            if (_quietHoursEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(_quietHoursStart),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(_quietHoursEnd),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event, color: Colors.blue),
              ),
              title: const Text('Appointment Reminder'),
              subtitle: const Text('Your appointment is tomorrow at 2:00 PM'),
              trailing: const Text('2h ago'),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.message, color: Colors.green),
              ),
              title: const Text('New Message'),
              subtitle: const Text('You have a new message from Dr. Smith'),
              trailing: const Text('1d ago'),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, color: Colors.orange),
              ),
              title: const Text('New Match'),
              subtitle: const Text('You have a new potential match'),
              trailing: const Text('3d ago'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'View All Notifications',
              onPressed: _viewAllNotifications,
              isOutlined: true,
              isFullWidth: true,
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

  Widget _buildSaveButton() {
    return CustomButton(
      text: 'Save Notification Settings',
      onPressed: _saveSettings,
      isFullWidth: true,
    );
  }

  void _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _quietHoursStart = formattedTime;
        } else {
          _quietHoursEnd = formattedTime;
        }
      });
    }
  }

  void _saveSettings() {
    // TODO: Implement save notification settings API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings saved successfully')),
    );
  }

  void _viewAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Notifications'),
        content: const Text('Notification history feature coming soon.'),
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
