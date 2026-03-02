import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();
  String _selectedCategory = 'General';

  final List<String> _categories = [
    'General',
    'Account Issues',
    'Payment Problems',
    'Technical Support',
    'Appointments',
    'Privacy & Security',
    'Bug Report',
    'Feature Request',
  ];

  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I book an appointment?',
      answer: 'To book an appointment, go to the Hospitals tab, select a hospital, choose a service, and pick your preferred date and time.',
    ),
    FAQItem(
      question: 'Can I cancel or reschedule my appointment?',
      answer: 'Yes, you can cancel or reschedule appointments up to 24 hours before the scheduled time through the Appointments tab.',
    ),
    FAQItem(
      question: 'How do I update my profile information?',
      answer: 'Go to the Profile tab and tap the edit icon in the top right corner to update your personal information.',
    ),
    FAQItem(
      question: 'Is my personal information secure?',
      answer: 'Yes, we use industry-standard encryption and security measures to protect your personal and medical information.',
    ),
    FAQItem(
      question: 'How do I add a payment method?',
      answer: 'Go to Profile > Payment Methods and tap "Add Payment Method" to securely add your card or payment information.',
    ),
    FAQItem(
      question: 'What if I forget my password?',
      answer: 'On the login screen, tap "Forgot Password" and follow the instructions to reset your password via email.',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildFAQSection(),
            const SizedBox(height: 24),
            _buildContactSupportSection(),
            const SizedBox(height: 24),
            _buildResourcesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Live Chat',
                    Icons.chat,
                    Colors.blue,
                    _startLiveChat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Call Support',
                    Icons.phone,
                    Colors.green,
                    _callSupport,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Email Us',
                    Icons.email,
                    Colors.orange,
                    _emailSupport,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Video Call',
                    Icons.video_call,
                    Colors.purple,
                    _scheduleVideoCall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._faqs.map((faq) => _buildFAQItem(faq)),
            const SizedBox(height: 16),
            CustomButton(
              text: 'View All FAQs',
              onPressed: _viewAllFAQs,
              isOutlined: true,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq.answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupportSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              name: 'subject',
              controller: _subjectController,
              labelText: 'Subject',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              name: 'message',
              controller: _messageController,
              labelText: 'Message',
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Send Message',
              onPressed: _sendSupportMessage,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.book,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('User Guide'),
              subtitle: const Text('Complete guide to using the app'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _openUserGuide,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.video_library,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Video Tutorials'),
              subtitle: const Text('Step-by-step video guides'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _openVideoTutorials,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.forum,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Community Forum'),
              subtitle: const Text('Connect with other users'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _openCommunityForum,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.bug_report,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Report a Bug'),
              subtitle: const Text('Help us improve the app'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _reportBug,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.star,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Rate the App'),
              subtitle: const Text('Share your feedback'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _rateApp,
            ),
          ],
        ),
      ),
    );
  }

  void _startLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text('Live chat feature coming soon. For immediate assistance, please call our support line.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _callSupport() async {
    const phoneNumber = 'tel:+1-800-FERTILITY';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  void _emailSupport() async {
    const email = 'mailto:support@fertilityservices.com?subject=Support Request';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email client')),
      );
    }
  }

  void _scheduleVideoCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Video Call'),
        content: const Text('Video call support is available Monday-Friday, 9 AM - 5 PM EST. Would you like to schedule a call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call scheduling feature coming soon')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _viewAllFAQs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complete FAQ section coming soon')),
    );
  }

  void _sendSupportMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // TODO: Implement send support message API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support message sent successfully')),
    );
    
    _subjectController.clear();
    _messageController.clear();
    setState(() => _selectedCategory = 'General');
  }

  void _openUserGuide() async {
    const url = 'https://fertilityservices.com/user-guide';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User guide feature coming soon')),
      );
    }
  }

  void _openVideoTutorials() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video tutorials feature coming soon')),
    );
  }

  void _openCommunityForum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Community forum feature coming soon')),
    );
  }

  void _reportBug() {
    setState(() {
      _selectedCategory = 'Bug Report';
      _subjectController.text = 'Bug Report: ';
    });
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Our App'),
        content: const Text('We\'d love to hear your feedback! Please rate us on the app store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App store rating feature coming soon')),
              );
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
