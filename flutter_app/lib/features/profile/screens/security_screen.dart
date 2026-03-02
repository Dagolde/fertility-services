import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _twoFactorEnabled = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordSection(),
              const SizedBox(height: 32),
              _buildTwoFactorSection(),
              const SizedBox(height: 32),
              _buildLoginActivitySection(),
              const SizedBox(height: 32),
              _buildAccountSecuritySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              name: 'current_password',
              controller: _currentPasswordController,
              labelText: 'Current Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              name: 'new_password',
              controller: _newPasswordController,
              labelText: 'New Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              name: 'confirm_password',
              controller: _confirmPasswordController,
              labelText: 'Confirm New Password',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Update Password',
              onPressed: _changePassword,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Two-Factor Authentication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an extra layer of security to your account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _twoFactorEnabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          color: _twoFactorEnabled ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _twoFactorEnabled,
                  onChanged: _toggleTwoFactor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginActivitySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Login Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Current Session',
              'Windows • Chrome',
              'Active now',
              true,
            ),
            const Divider(),
            _buildActivityItem(
              'Mobile App',
              'Android • Fertility App',
              '2 hours ago',
              false,
            ),
            const Divider(),
            _buildActivityItem(
              'Previous Session',
              'Windows • Chrome',
              'Yesterday at 3:45 PM',
              false,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'View All Activity',
              onPressed: _viewAllActivity,
              isOutlined: true,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSecuritySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Security',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.verified_user,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Account Verification'),
              subtitle: const Text('Email verified'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.security,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Security Checkup'),
              subtitle: const Text('Review your security settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _runSecurityCheckup,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String device,
    String time,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.computer : Icons.devices,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  device,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // TODO: Implement change password API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTwoFactor(bool value) {
    setState(() => _twoFactorEnabled = value);
    
    if (value) {
      _showTwoFactorSetupDialog();
    } else {
      _showTwoFactorDisableDialog();
    }
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account. You\'ll need to enter a code from your authenticator app when signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _twoFactorEnabled = false);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled'),
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Two-Factor Authentication'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? This will make your account less secure.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _twoFactorEnabled = true);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication disabled'),
                ),
              );
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _viewAllActivity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login activity feature coming soon')),
    );
  }

  void _runSecurityCheckup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Checkup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckupItem('Password strength', true),
            _buildCheckupItem('Two-factor authentication', _twoFactorEnabled),
            _buildCheckupItem('Email verification', true),
            _buildCheckupItem('Recent login activity', true),
          ],
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

  Widget _buildCheckupItem(String title, bool isSecure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSecure ? Icons.check_circle : Icons.warning,
            color: isSecure ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
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
                  content: Text('Account deletion feature coming soon'),
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
}
