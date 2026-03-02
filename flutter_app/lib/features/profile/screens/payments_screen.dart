import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/repositories/payment_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;
      
      if (token != null) {
        final payments = await PaymentRepository().getUserPayments(token);
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Please login to view your payments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payments: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _loadPayments,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConfig.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPaymentHistorySection(),
                      const SizedBox(height: 24),
                      _buildPaymentSettingsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_payments.isEmpty)
              _buildEmptyState()
            else
              ..._payments.map((payment) => _buildPaymentItem(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.credit_card_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Payments Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: payment.statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.statusIcon,
            color: payment.statusColor,
            size: 20,
          ),
        ),
        title: Text(
          'Payment #${payment.id}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${payment.currency} ${payment.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Method: ${payment.paymentMethod}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Date: ${payment.createdAt.toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: payment.statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment.statusDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  Widget _buildPaymentSettingsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.email,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Email Receipts'),
              subtitle: const Text('Send receipts to your email'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email receipt settings updated')),
                  );
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.security,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Payment Security'),
              subtitle: const Text('Manage payment security settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showPaymentSecurity,
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Payment ID', payment.id.toString()),
              _buildDetailRow('Amount', '${payment.currency} ${payment.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', payment.statusDisplay),
              _buildDetailRow('Method', payment.paymentMethod),
              _buildDetailRow('Date', payment.createdAt.toString().substring(0, 19)),
              if (payment.transactionId != null)
                _buildDetailRow('Transaction ID', payment.transactionId!),
              if (payment.paymentDate != null)
                _buildDetailRow('Payment Date', payment.paymentDate!.toString().substring(0, 19)),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showPaymentSecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Security'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityItem('SSL Encryption', true),
            _buildSecurityItem('PCI Compliance', true),
            _buildSecurityItem('Fraud Protection', true),
            _buildSecurityItem('Two-Factor Auth', false),
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

  Widget _buildSecurityItem(String title, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.warning,
            color: isEnabled ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}
