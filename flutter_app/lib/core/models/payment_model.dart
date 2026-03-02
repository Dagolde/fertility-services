import 'package:flutter/material.dart';

class Payment {
  final int id;
  final int userId;
  final int? appointmentId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? gatewayReference;
  final String? gatewayTransactionId;
  final String? authorizationCode;
  final DateTime? paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? gatewayResponse;

  Payment({
    required this.id,
    required this.userId,
    this.appointmentId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.gatewayReference,
    this.gatewayTransactionId,
    this.authorizationCode,
    this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
    this.gatewayResponse,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['user_id'],
      appointmentId: json['appointment_id'],
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'NGN',
      paymentMethod: json['payment_method'] ?? 'card',
      status: json['status'] ?? 'pending',
      transactionId: json['transaction_id'],
      gatewayReference: json['gateway_reference'],
      gatewayTransactionId: json['gateway_transaction_id'],
      authorizationCode: json['authorization_code'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      gatewayResponse: json['gateway_response'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'appointment_id': appointmentId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'status': status,
      'transaction_id': transactionId,
      'gateway_reference': gatewayReference,
      'gateway_transaction_id': gatewayTransactionId,
      'authorization_code': authorizationCode,
      'payment_date': paymentDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'gateway_response': gatewayResponse,
    };
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.replay;
      default:
        return Icons.help_outline;
    }
  }
}

class PaystackInitializationResponse {
  final int paymentId;
  final String reference;
  final String authorizationUrl;
  final String accessCode;
  final double amount;
  final String currency;

  PaystackInitializationResponse({
    required this.paymentId,
    required this.reference,
    required this.authorizationUrl,
    required this.accessCode,
    required this.amount,
    required this.currency,
  });

  factory PaystackInitializationResponse.fromJson(Map<String, dynamic> json) {
    return PaystackInitializationResponse(
      paymentId: json['payment_id'],
      reference: json['reference'],
      authorizationUrl: json['authorization_url'],
      accessCode: json['access_code'],
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'NGN',
    );
  }
}

class PaymentVerificationResponse {
  final String status;
  final String message;
  final int paymentId;
  final String? transactionId;
  final double? amount;
  final String? currency;

  PaymentVerificationResponse({
    required this.status,
    required this.message,
    required this.paymentId,
    this.transactionId,
    this.amount,
    this.currency,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      status: json['status'] ?? 'failed',
      message: json['message'] ?? 'Payment verification failed',
      paymentId: json['payment_id'],
      transactionId: json['transaction_id'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
    );
  }
}
