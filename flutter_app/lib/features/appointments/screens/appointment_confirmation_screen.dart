import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/models/service_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/app_config.dart';

class AppointmentConfirmationScreen extends StatefulWidget {
  final Hospital hospital;
  final Service service;
  final DateTime appointmentDate;
  final String timeSlot;

  const AppointmentConfirmationScreen({
    super.key,
    required this.hospital,
    required this.service,
    required this.appointmentDate,
    required this.timeSlot,
  });

  @override
  State<AppointmentConfirmationScreen> createState() => _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState extends State<AppointmentConfirmationScreen> {
  PaymentGateway? _selectedPaymentGateway;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<PaymentGatewayOption> _paymentGateways = [
    PaymentGatewayOption(
      gateway: PaymentGateway.paystack,
      name: 'Paystack',
      description: 'Pay with card, bank transfer, or USSD',
      icon: Icons.credit_card,
      color: Colors.blue,
      supportedCountries: ['Nigeria', 'Ghana', 'South Africa', 'Kenya'],
    ),
    PaymentGatewayOption(
      gateway: PaymentGateway.stripe,
      name: 'Stripe',
      description: 'International card payments',
      icon: Icons.payment,
      color: Colors.purple,
      supportedCountries: ['Global'],
    ),
    PaymentGatewayOption(
      gateway: PaymentGateway.flutterwave,
      name: 'Flutterwave',
      description: 'Pay with card, mobile money, or bank',
      icon: Icons.account_balance_wallet,
      color: Colors.orange,
      supportedCountries: ['Nigeria', 'Ghana', 'Kenya', 'Uganda', 'Tanzania'],
    ),
    PaymentGatewayOption(
      gateway: PaymentGateway.mpesa,
      name: 'M-Pesa',
      description: 'Mobile money payment',
      icon: Icons.phone_android,
      color: Colors.green,
      supportedCountries: ['Kenya', 'Tanzania', 'Mozambique'],
    ),
  ];

  Future<void> _confirmAppointment() async {
    if (_selectedPaymentGateway == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, reserve the appointment slot
      final reserveResponse = await ApiService.post(
        '/appointments/reserve',
        data: {
          'hospital_id': widget.hospital.id,
          'service_id': widget.service.id,
          'appointment_date': '${DateFormat('yyyy-MM-dd').format(widget.appointmentDate)}T${widget.timeSlot}:00Z',
        },
      );

      if (reserveResponse.statusCode == 201) {
        final reservationId = reserveResponse.data['reservation_id'];

        // Then, confirm the appointment with payment
        final confirmResponse = await ApiService.post(
          '/appointments/confirm',
          data: {
            'reservation_id': reservationId,
            'payment_method': _selectedPaymentGateway!.name.toLowerCase(),
          },
        );

        if (confirmResponse.statusCode == 200) {
          final paymentUrl = confirmResponse.data['payment']['payment_url'];
          final appointmentData = confirmResponse.data['appointment'];

          setState(() {
            _isLoading = false;
          });

          // Navigate to payment screen
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/payment',
              arguments: {
                'payment_url': paymentUrl,
                'appointment': appointmentData,
              },
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to confirm appointment: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Appointment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildAppointmentDetails(),
                    const SizedBox(height: 24),
                    _buildPaymentGatewaySelection(),
                    const SizedBox(height: 24),
                    _buildTermsAndConditions(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Appointment',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review the details below and select your payment method',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConfig.borderRadius),
                topRight: Radius.circular(AppConfig.borderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Appointment Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.local_hospital,
                  'Hospital',
                  widget.hospital.name,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.medical_services,
                  'Service',
                  widget.service.name,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.calendar_month,
                  'Date',
                  DateFormat('EEEE, MMMM dd, yyyy').format(widget.appointmentDate),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.access_time,
                  'Time',
                  widget.timeSlot,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.timer,
                  'Duration',
                  widget.service.formattedDuration,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.location_on,
                  'Location',
                  '${widget.hospital.city}, ${widget.hospital.state}',
                ),
                const Divider(height: 24),
                _buildPriceRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
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
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments,
                color: Colors.green[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
              ),
            ],
          ),
          Text(
            widget.service.formattedPrice,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentGatewaySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _paymentGateways.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final gateway = _paymentGateways[index];
            final isSelected = _selectedPaymentGateway == gateway.gateway;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedPaymentGateway = gateway.gateway;
                  _errorMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? gateway.color.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? gateway.color
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: gateway.color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: gateway.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                      ),
                      child: Icon(
                        gateway.icon,
                        color: gateway.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gateway.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? gateway.color : Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gateway.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available in: ${gateway.supportedCountries.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: gateway.color,
                        size: 28,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey[400],
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms and Conditions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'By confirming this appointment, you agree to the following:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          _buildTermItem('Cancellations made 24+ hours in advance receive a full refund'),
          _buildTermItem('Cancellations made less than 24 hours in advance receive a 50% refund'),
          _buildTermItem('No-shows are not eligible for refunds'),
          _buildTermItem('You will receive appointment reminders 24 hours and 1 hour before'),
          _buildTermItem('Your payment information is securely processed'),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() {
                _acceptedTerms = !_acceptedTerms;
                _errorMessage = null;
              });
            },
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _acceptedTerms
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _acceptedTerms
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: _acceptedTerms
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I have read and accept the terms and conditions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              elevation: 2,
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm & Pay ${widget.service.formattedPrice}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum PaymentGateway {
  paystack,
  stripe,
  flutterwave,
  mpesa,
}

class PaymentGatewayOption {
  final PaymentGateway gateway;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> supportedCountries;

  PaymentGatewayOption({
    required this.gateway,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.supportedCountries,
  });
}
