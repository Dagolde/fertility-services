import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2024',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using the Fertility Services application ("Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            _buildSection(
              context,
              '2. Description of Service',
              'Fertility Services is a platform that connects individuals and couples seeking fertility services with healthcare providers, donors, and surrogates. Our service includes:\n\n'
              '• Matching with verified fertility clinics\n'
              '• Connection with screened egg and sperm donors\n'
              '• Surrogate matching services\n'
              '• Appointment scheduling and management\n'
              '• Secure messaging and communication tools\n'
              '• Medical record management',
            ),
            _buildSection(
              context,
              '3. User Accounts',
              'To access certain features of the Service, you must register for an account. You agree to:\n\n'
              '• Provide accurate, current, and complete information\n'
              '• Maintain the security of your password\n'
              '• Accept responsibility for all activities under your account\n'
              '• Notify us immediately of any unauthorized use',
            ),
            _buildSection(
              context,
              '4. Medical Disclaimer',
              'The Service is not intended to provide medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have read on this Service.',
            ),
            _buildSection(
              context,
              '5. Privacy and Data Protection',
              'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our Service. By using our Service, you agree to the collection and use of information in accordance with our Privacy Policy.',
            ),
            _buildSection(
              context,
              '6. User Conduct',
              'You agree not to use the Service to:\n\n'
              '• Violate any applicable laws or regulations\n'
              '• Impersonate any person or entity\n'
              '• Upload or transmit harmful content\n'
              '• Interfere with the Service\'s operation\n'
              '• Collect user information without consent\n'
              '• Use the Service for commercial purposes without authorization',
            ),
            _buildSection(
              context,
              '7. Content and Intellectual Property',
              'The Service and its original content, features, and functionality are owned by Fertility Services and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.',
            ),
            _buildSection(
              context,
              '8. Verification and Screening',
              'While we strive to verify and screen all healthcare providers, donors, and surrogates on our platform, we cannot guarantee the accuracy of all information provided. Users are responsible for conducting their own due diligence.',
            ),
            _buildSection(
              context,
              '9. Payment Terms',
              'Certain features of the Service may require payment. You agree to pay all fees associated with your use of paid features. All payments are non-refundable unless otherwise specified.',
            ),
            _buildSection(
              context,
              '10. Limitation of Liability',
              'In no event shall Fertility Services be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
            ),
            _buildSection(
              context,
              '11. Termination',
              'We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever, including without limitation if you breach the Terms.',
            ),
            _buildSection(
              context,
              '12. Changes to Terms',
              'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.',
            ),
            _buildSection(
              context,
              '13. Governing Law',
              'These Terms shall be interpreted and governed by the laws of the jurisdiction in which Fertility Services operates, without regard to its conflict of law provisions.',
            ),
            _buildSection(
              context,
              '14. Contact Information',
              'If you have any questions about these Terms of Service, please contact us at:\n\n'
              'Email: legal@fertilityservices.com\n'
              'Phone: +1 (800) FERTILITY\n'
              'Address: 123 Healthcare Blvd, Medical City, MC 12345',
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agreement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By using our Service, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
