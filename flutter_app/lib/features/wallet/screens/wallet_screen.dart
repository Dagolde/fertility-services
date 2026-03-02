import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/wallet_provider.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedGateway = 'paystack';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().refreshWallet();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return LoadingOverlay(
            isLoading: walletProvider.isLoading,
            child: RefreshIndicator(
              onRefresh: () => walletProvider.refreshWallet(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _buildBalanceCard(walletProvider),
                    const SizedBox(height: 24),
                    
                    // Fund Wallet Section
                    _buildFundWalletSection(walletProvider),
                    const SizedBox(height: 24),
                    
                    // Transactions Section
                    _buildTransactionsSection(walletProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(WalletProvider walletProvider) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₦${walletProvider.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fertility Services Wallet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundWalletSection(WalletProvider walletProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fund Wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              name: 'amount',
              controller: _amountController,
              labelText: 'Amount (₦)',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              name: 'description',
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              prefixIcon: const Icon(Icons.description),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedGateway,
              decoration: const InputDecoration(
                labelText: 'Payment Gateway',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'paystack',
                  child: Text('Paystack'),
                ),
                DropdownMenuItem(
                  value: 'stripe',
                  child: Text('Stripe'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGateway = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Fund Wallet',
                onPressed: () => _fundWallet(walletProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(WalletProvider walletProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => walletProvider.getWalletTransactions(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (walletProvider.transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: walletProvider.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = walletProvider.transactions[index];
                  return _buildTransactionItem(transaction);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isCredit = transaction['transaction_type'] == 'fund';
    final amount = transaction['amount'].toDouble();
    final status = transaction['status'];
    final createdAt = DateTime.parse(transaction['created_at']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? Colors.green : Colors.red,
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction['description'] ?? 'Transaction',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₦${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fundWallet(WalletProvider walletProvider) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await walletProvider.fundWallet(
      amount: amount,
      paymentGateway: _selectedGateway,
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : 'Wallet funding',
    );

    if (result != null) {
      // Show payment URL
      final paymentUrl = result['payment_url'];
      if (paymentUrl != null) {
        _showPaymentDialog(paymentUrl, result['reference']);
      }
      
      // Clear form
      _amountController.clear();
      _descriptionController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(walletProvider.error ?? 'Failed to fund wallet'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentDialog(String paymentUrl, String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payment,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'You will be redirected to Paystack to complete your payment securely.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Payment Reference:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reference,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After completing payment, please return to the app to verify your transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _launchPaymentUrl(paymentUrl);
            },
            icon: const Icon(Icons.payment),
            label: const Text('Proceed to Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      print('Attempting to launch URL: $url');
      
      // Ensure the URL is properly formatted
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      
      final uri = Uri.parse(formattedUrl);
      print('Parsed URI: $uri');
      
      // Try to launch URL directly without checking canLaunchUrl first
      // This bypasses the issue where canLaunchUrl returns false for valid URLs
      bool launched = false;
      
      // First try external application
      try {
        print('Trying external application mode...');
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        launched = true;
        print('URL launched successfully in external application mode');
      } catch (e) {
        print('Failed to launch in external application mode: $e');
      }
      
      // If external application failed, try in-app browser
      if (!launched) {
        try {
          print('Trying in-app browser mode...');
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
          launched = true;
          print('URL launched successfully in in-app browser mode');
        } catch (e) {
          print('Failed to launch in in-app browser mode: $e');
        }
      }
      
      // If both failed, try default mode
      if (!launched) {
        try {
          print('Trying default mode...');
          await launchUrl(uri);
          launched = true;
          print('URL launched successfully in default mode');
        } catch (e) {
          print('Failed to launch in default mode: $e');
        }
      }
      
      // If all modes failed, try with platform-specific approach
      if (!launched) {
        try {
          print('Trying platform-specific approach...');
          // For Android, try to launch with explicit intent
          if (Platform.isAndroid) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
            launched = true;
            print('URL launched successfully with external non-browser mode');
          }
        } catch (e) {
          print('Failed platform-specific approach: $e');
        }
      }
      
      if (!launched) {
        // If all launch attempts fail, offer to copy URL to clipboard
        _showCopyUrlDialog(formattedUrl);
      }
      
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening payment page: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showCopyUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Open Payment Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'The payment link could not be opened automatically. You can copy the link and open it manually in your browser.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment link copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }
}
