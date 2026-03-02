import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final String baseUrl = AppConfig.apiBaseUrl;

  Future<List<Payment>> getUserPayments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/my-payments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payments: ${response.statusCode}');
    }
  }

  Future<Payment> getPaymentById(String token, int paymentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/$paymentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Payment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load payment: ${response.statusCode}');
    }
  }

  Future<PaystackInitializationResponse> initializePaystackPayment({
    required String token,
    required int appointmentId,
    String currency = 'NGN',
    String? callbackUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/paystack/initialize'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'appointment_id': appointmentId,
        'currency': currency,
        'callback_url': callbackUrl,
      }),
    );

    if (response.statusCode == 200) {
      return PaystackInitializationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to initialize payment: ${response.statusCode}');
    }
  }

  Future<PaymentVerificationResponse> verifyPaystackPayment({
    required String token,
    required String reference,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/paystack/verify/$reference'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return PaymentVerificationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to verify payment: ${response.statusCode}');
    }
  }

  Future<Payment> createPayment({
    required String token,
    required int appointmentId,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'appointment_id': appointmentId,
        'amount': amount,
        'payment_method': paymentMethod,
      }),
    );

    if (response.statusCode == 201) {
      return Payment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create payment: ${response.statusCode}');
    }
  }

  Future<void> processPayment({
    required String token,
    required int paymentId,
    String? transactionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/process'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'transaction_id': transactionId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to process payment: ${response.statusCode}');
    }
  }

  Future<void> refundPayment({
    required String token,
    required int paymentId,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/refund'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to process refund: ${response.statusCode}');
    }
  }
}
