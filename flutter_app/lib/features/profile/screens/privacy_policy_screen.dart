import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2023',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Introduction',
              'Fertility Services ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              'We collect information you provide directly to us, including:\n\n'
              '• Personal Information: Name, email address, phone number, date of birth\n'
              '• Medical Information: Health records, fertility history, medical preferences\n'
              '• Profile Information: Photos, bio, preferences, location\n'
              '• Communication Data: Messages, appointment details, support requests\n'
              '• Payment Information: Credit card details, billing address (processed securely)\n'
              '• Usage Data: App usage patterns, device information, IP address',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide and maintain our services\n'
              '• Match you with appropriate healthcare providers and donors\n'
              '• Process appointments and payments\n'
              '• Send you important notifications and updates\n'
              '• Improve our services and user experience\n'
              '• Comply with legal obligations\n'
              '• Protect against fraud and abuse',
            ),
            _buildSection(
              context,
              '4. Information Sharing',
              'We may share your information in the following circumstances:\n\n'
              '• With Healthcare Providers: When you book appointments or consultations\n'
              '• With Matched Users: Limited profile information for matching purposes\n'
              '• With Service Providers: Third-party vendors who assist our operations\n'
              '• For Legal Compliance: When required by law or to protect rights\n'
              '• Business Transfers: In case of merger, acquisition, or sale\n\n'
              'We never sell your personal information to third parties for marketing purposes.',
            ),
            _buildSection(
              context,
              '5. Data Security',
              'We implement appropriate security measures to protect your information:\n\n'
              '• End-to-end encryption for sensitive communications\n'
              '• Secure data storage with industry-standard encryption\n'
              '• Regular security audits and vulnerability assessments\n'
              '• Access controls and employee training\n'
              '• HIPAA-compliant handling of medical information\n'
              '• SOC 2 Type II certified infrastructure',
            ),
            _buildSection(
              context,
              '6. Your Privacy Rights',
              'You have the right to:\n\n'
              '• Access your personal information\n'
              '• Correct inaccurate information\n'
              '• Delete your account and data\n'
              '• Restrict processing of your information\n'
              '• Data portability (receive a copy of your data)\n'
              '• Opt-out of marketing communications\n'
              '• Withdraw consent where applicable',
            ),
            _buildSection(
              context,
              '7. Cookies and Tracking',
              'We use cookies and similar technologies to:\n\n'
              '• Remember your preferences and settings\n'
              '• Analyze app usage and performance\n'
              '• Provide personalized content\n'
              '• Ensure security and prevent fraud\n\n'
              'You can control cookie settings through your device preferences.',
            ),
            _buildSection(
              context,
              '8. Third-Party Services',
              'Our app may integrate with third-party services:\n\n'
              '• Payment processors (Stripe, PayPal)\n'
              '• Analytics services (Google Analytics)\n'
              '• Cloud storage providers (AWS, Google Cloud)\n'
              '• Communication services (Twilio, SendGrid)\n\n'
              'These services have their own privacy policies governing their use of your information.',
            ),
            _buildSection(
              context,
              '9. International Data Transfers',
              'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information in accordance with applicable data protection laws.',
            ),
            _buildSection(
              context,
              '10. Children\'s Privacy',
              'Our services are not intended for individuals under 18 years of age. We do not knowingly collect personal information from children under 18. If we become aware that we have collected such information, we will take steps to delete it.',
            ),
            _buildSection(
              context,
              '11. Data Retention',
              'We retain your information for as long as necessary to:\n\n'
              '• Provide our services\n'
              '• Comply with legal obligations\n'
              '• Resolve disputes\n'
              '• Enforce our agreements\n\n'
              'Medical records may be retained for longer periods as required by healthcare regulations.',
            ),
            _buildSection(
              context,
              '12. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy in the app and sending you a notification. Your continued use of our services after such changes constitutes acceptance of the updated policy.',
            ),
            _buildSection(
              context,
              '13. Contact Us',
              'If you have questions about this Privacy Policy or our privacy practices, please contact us:\n\n'
              'Email: privacy@fertilityservices.com\n'
              'Phone: +1 (800) FERTILITY\n'
              'Address: 123 Healthcare Blvd, Medical City, MC 12345\n\n'
              'Data Protection Officer: dpo@fertilityservices.com',
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Privacy Matters',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are committed to protecting your privacy and handling your personal information with care. If you have any concerns or questions about how we handle your data, please don\'t hesitate to contact us.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[700],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
