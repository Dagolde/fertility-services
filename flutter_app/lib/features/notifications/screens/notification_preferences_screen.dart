import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final Map<String, Map<String, bool>> _preferences = {
    'PUSH': {},
    'EMAIL': {},
    'SMS': {},
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      await context.read<NotificationProvider>().loadPreferences();
      final prefs = context.read<NotificationProvider>().preferences;
      
      // Parse preferences into local state
      if (prefs.isNotEmpty) {
        for (var channel in ['PUSH', 'EMAIL', 'SMS']) {
          _preferences[channel] = {
            'APPOINTMENT_CONFIRMATION': prefs['${channel}_APPOINTMENT_CONFIRMATION'] ?? true,
            'APPOINTMENT_REMINDER': prefs['${channel}_APPOINTMENT_REMINDER'] ?? true,
            'PAYMENT_SUCCESS': prefs['${channel}_PAYMENT_SUCCESS'] ?? true,
            'PAYMENT_FAILED': prefs['${channel}_PAYMENT_FAILED'] ?? true,
            'GENERAL': prefs['${channel}_GENERAL'] ?? true,
          };
        }
      } else {
        // Default all to true
        for (var channel in ['PUSH', 'EMAIL', 'SMS']) {
          _preferences[channel] = {
            'APPOINTMENT_CONFIRMATION': true,
            'APPOINTMENT_REMINDER': true,
            'PAYMENT_SUCCESS': true,
            'PAYMENT_FAILED': true,
            'GENERAL': true,
          };
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      // Convert local state to API format
      final Map<String, dynamic> apiPrefs = {};
      for (var channel in _preferences.keys) {
        for (var type in _preferences[channel]!.keys) {
          apiPrefs['${channel}_$type'] = _preferences[channel]![type];
        }
      }

      final success = await context.read<NotificationProvider>().updatePreferences(apiPrefs);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save preferences'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Choose how you want to receive notifications for different types of events.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                _buildChannelSection('Push Notifications', 'PUSH', Icons.notifications),
                const Divider(),
                _buildChannelSection('Email Notifications', 'EMAIL', Icons.email),
                const Divider(),
                _buildChannelSection('SMS Notifications', 'SMS', Icons.sms),
              ],
            ),
    );
  }

  Widget _buildChannelSection(String title, String channel, IconData icon) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      initiallyExpanded: true,
      children: [
        _buildPreferenceSwitch(
          channel,
          'APPOINTMENT_CONFIRMATION',
          'Appointment Confirmations',
          'Get notified when appointments are confirmed',
        ),
        _buildPreferenceSwitch(
          channel,
          'APPOINTMENT_REMINDER',
          'Appointment Reminders',
          'Get reminded about upcoming appointments',
        ),
        _buildPreferenceSwitch(
          channel,
          'PAYMENT_SUCCESS',
          'Payment Success',
          'Get notified when payments are successful',
        ),
        _buildPreferenceSwitch(
          channel,
          'PAYMENT_FAILED',
          'Payment Failed',
          'Get notified when payments fail',
        ),
        _buildPreferenceSwitch(
          channel,
          'GENERAL',
          'General Notifications',
          'Get general updates and announcements',
        ),
      ],
    );
  }

  Widget _buildPreferenceSwitch(
    String channel,
    String type,
    String title,
    String subtitle,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: _preferences[channel]?[type] ?? true,
      onChanged: (value) {
        setState(() {
          _preferences[channel]![type] = value;
        });
      },
    );
  }
}
