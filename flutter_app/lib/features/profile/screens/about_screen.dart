import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_button.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppInfoSection(),
            const SizedBox(height: 24),
            _buildCompanyInfoSection(),
            const SizedBox(height: 24),
            _buildFeaturesSection(),
            const SizedBox(height: 24),
            _buildLegalSection(),
            const SizedBox(height: 24),
            _buildContactSection(),
            const SizedBox(height: 24),
            _buildSocialSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fertility Services',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connecting hearts, building families',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version $_appVersion ($_buildNumber)',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Our Mission',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fertility Services is dedicated to helping individuals and couples on their journey to parenthood. We connect patients with trusted fertility clinics, egg donors, sperm donors, and surrogates in a safe and supportive environment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Our platform provides:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...[
              '• Secure matching with verified donors and surrogates',
              '• Easy appointment booking with fertility clinics',
              '• Comprehensive medical record management',
              '• 24/7 support throughout your journey',
              '• Privacy-focused communication tools',
            ].map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.local_hospital,
              'Hospital Network',
              'Access to verified fertility clinics nationwide',
            ),
            _buildFeatureItem(
              Icons.people,
              'Donor Matching',
              'Connect with screened egg and sperm donors',
            ),
            _buildFeatureItem(
              Icons.pregnant_woman,
              'Surrogacy Services',
              'Find and connect with qualified surrogates',
            ),
            _buildFeatureItem(
              Icons.calendar_today,
              'Appointment Management',
              'Easy scheduling and appointment tracking',
            ),
            _buildFeatureItem(
              Icons.security,
              'Privacy & Security',
              'End-to-end encryption and data protection',
            ),
            _buildFeatureItem(
              Icons.support_agent,
              '24/7 Support',
              'Round-the-clock assistance and guidance',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legal & Compliance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.policy,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Terms of Service'),
              subtitle: const Text('Read our terms and conditions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _openTermsOfService,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.privacy_tip,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('How we protect your data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _openPrivacyPolicy,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.verified,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Licenses & Certifications'),
              subtitle: const Text('Our compliance certifications'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showLicenses,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.gavel,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Open Source Licenses'),
              subtitle: const Text('Third-party software licenses'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showOpenSourceLicenses,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              'Email',
              'support@fertilityservices.com',
              () => _launchEmail('support@fertilityservices.com'),
            ),
            _buildContactItem(
              Icons.phone,
              'Phone',
              '+1 (800) FERTILITY',
              () => _launchPhone('+18003378454'),
            ),
            _buildContactItem(
              Icons.location_on,
              'Address',
              '123 Healthcare Blvd, Medical City, MC 12345',
              () => _launchMaps('123 Healthcare Blvd, Medical City, MC 12345'),
            ),
            _buildContactItem(
              Icons.language,
              'Website',
              'www.fertilityservices.com',
              () => _launchWebsite('https://www.fertilityservices.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
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
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.launch,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow Us',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  'Facebook',
                  Icons.facebook,
                  Colors.blue[700]!,
                  () => _launchSocial('https://facebook.com/fertilityservices'),
                ),
                _buildSocialButton(
                  'Twitter',
                  Icons.alternate_email,
                  Colors.blue[400]!,
                  () => _launchSocial('https://twitter.com/fertilityservices'),
                ),
                _buildSocialButton(
                  'Instagram',
                  Icons.camera_alt,
                  Colors.purple[400]!,
                  () => _launchSocial('https://instagram.com/fertilityservices'),
                ),
                _buildSocialButton(
                  'LinkedIn',
                  Icons.business,
                  Colors.blue[800]!,
                  () => _launchSocial('https://linkedin.com/company/fertilityservices'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '© 2023 Fertility Services. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTermsOfService() {
    Navigator.pushNamed(context, '/legal/terms');
  }

  void _openPrivacyPolicy() {
    Navigator.pushNamed(context, '/legal/privacy');
  }

  void _showLicenses() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Licenses & Certifications'),
        content: const SingleChildScrollView(
          child: Text(
            'Fertility Services is compliant with:\n\n'
            '• HIPAA (Health Insurance Portability and Accountability Act)\n'
            '• FDA regulations for medical devices\n'
            '• State medical licensing requirements\n'
            '• SOC 2 Type II certification\n'
            '• ISO 27001 information security standards\n\n'
            'All partner clinics are verified and licensed healthcare providers.',
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

  void _showOpenSourceLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Fertility Services',
      applicationVersion: _appVersion,
      applicationLegalese: '© 2023 Fertility Services',
    );
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchMaps(String address) async {
    final uri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchSocial(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
