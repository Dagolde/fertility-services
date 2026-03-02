import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _error;

  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get wallet balance
  Future<void> getWalletBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/wallet/balance');
      
      if (response.statusCode == 200) {
        final data = response.data is String ? json.decode(response.data) : response.data;
        _balance = data['balance'].toDouble();
        _error = null;
      } else {
        _error = 'Failed to load wallet balance';
      }
    } catch (e) {
      _error = 'Error loading wallet balance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get wallet transactions
  Future<void> getWalletTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/wallet/transactions');
      
      if (response.statusCode == 200) {
        final data = response.data is String ? json.decode(response.data) : response.data;
        _transactions = List<Map<String, dynamic>>.from(data);
        _error = null;
      } else {
        _error = 'Failed to load transactions';
      }
    } catch (e) {
      _error = 'Error loading transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fund wallet
  Future<Map<String, dynamic>?> fundWallet({
    required double amount,
    required String paymentGateway,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/wallet/fund',
        data: {
          'amount': amount,
          'currency': 'NGN',
          'payment_gateway': paymentGateway,
          'description': description,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data is String ? json.decode(response.data) : response.data;
        _error = null;
        return data;
      } else {
        final errorData = response.data is String ? json.decode(response.data) : response.data;
        _error = errorData['detail'] ?? 'Failed to fund wallet';
        return null;
      }
    } catch (e) {
      _error = 'Error funding wallet: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify payment
  Future<Map<String, dynamic>?> verifyPayment(String reference) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/wallet/verify-payment/$reference');
      
      if (response.statusCode == 200) {
        final data = response.data is String ? json.decode(response.data) : response.data;
        if (data['status'] == 'completed') {
          // Update balance after successful payment
          await getWalletBalance();
        }
        _error = null;
        return data;
      } else {
        final errorData = response.data is String ? json.decode(response.data) : response.data;
        _error = errorData['detail'] ?? 'Failed to verify payment';
        return null;
      }
    } catch (e) {
      _error = 'Error verifying payment: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pay from wallet
  Future<Map<String, dynamic>?> payFromWallet({
    required double amount,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/wallet/pay-from-wallet',
        data: {
          'amount': amount,
          'description': description,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data is String ? json.decode(response.data) : response.data;
        // Update balance after payment
        await getWalletBalance();
        _error = null;
        return data;
      } else {
        final errorData = response.data is String ? json.decode(response.data) : response.data;
        _error = errorData['detail'] ?? 'Failed to make payment';
        return null;
      }
    } catch (e) {
      _error = 'Error making payment: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh wallet data
  Future<void> refreshWallet() async {
    await Future.wait([
      getWalletBalance(),
      getWalletTransactions(),
    ]);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
