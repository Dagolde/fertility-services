import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/service_model.dart';
import '../../../core/repositories/services_repository.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/custom_button.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  
  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final ServicesRepository _servicesRepository = ServicesRepository();
  
  Service? _service;
  Map<String, dynamic>? _hospital;
  List<Service> _relatedServices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  Future<void> _loadServiceDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final serviceId = int.tryParse(widget.serviceId);
      if (serviceId == null) {
        throw Exception('Invalid service ID');
      }

      final serviceData = await _servicesRepository.getServiceById(serviceId);
      if (serviceData != null) {
        final service = Service.fromJson(serviceData);
        setState(() {
          _service = service;
        });
        
        // Load hospital information if available
        if (service.hospitalId != null) {
          _loadHospitalInfo(service.hospitalId!);
        }
        
        // Load related services
        _loadRelatedServices(service);
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Service not found');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load service details: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadHospitalInfo(int hospitalId) async {
    try {
      // Load hospital info from API
      final response = await ApiService.get('/hospitals/$hospitalId');
      if (response.statusCode == 200) {
        setState(() {
          _hospital = response.data;
        });
      }
    } catch (e) {
      // Silently fail - hospital info is optional
      debugPrint('Failed to load hospital info: $e');
    }
  }
  
  Future<void> _loadRelatedServices(Service currentService) async {
    try {
      final servicesData = await _servicesRepository.getServices(
        category: currentService.category,
        limit: 5,
      );
      
      final services = servicesData
          .map((data) => Service.fromJson(data))
          .where((s) => s.id != currentService.id)
          .take(4)
          .toList();
      
      setState(() {
        _relatedServices = services;
      });
    } catch (e) {
      // Silently fail - related services are optional
      debugPrint('Failed to load related services: $e');
    }
  }

  void _bookAppointment() {
    if (_service != null) {
      context.push('/appointments/book', extra: {
        'serviceId': _service!.id,
        'serviceName': _service!.name,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_service?.name ?? 'Service Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _service != null
                  ? _buildServiceDetails()
                  : _buildErrorState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Service',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: _loadServiceDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    final service = _service!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  service.serviceColor.withOpacity(0.1),
                  service.serviceColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: service.serviceColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    service.serviceIcon,
                    size: 48,
                    color: service.serviceColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: service.serviceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.serviceTypeLabel,
                    style: TextStyle(
                      color: service.serviceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service Information
          Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price and Duration
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.attach_money,
                        title: 'Price',
                        value: service.formattedPrice,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.schedule,
                        title: 'Duration',
                        value: service.formattedDuration,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                if (service.description != null && service.description!.isNotEmpty) ...[
                  Text(
                    'About This Service',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      service.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'About This Service',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      'No detailed description available for this service. Please contact us for more information.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Hospital Information
                if (_hospital != null) ...[
                  Text(
                    'Hospital Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_hospital, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hospital!['name'] ?? 'Hospital',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_hospital!['address'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _hospital!['address'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_hospital!['phone'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _hospital!['phone'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Related Services
                if (_relatedServices.isNotEmpty) ...[
                  Text(
                    'Related Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _relatedServices.length,
                      itemBuilder: (context, index) {
                        final relatedService = _relatedServices[index];
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                context.push('/services/${relatedService.id}');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 100,
                                    color: relatedService.serviceColor.withOpacity(0.1),
                                    child: Center(
                                      child: Icon(
                                        relatedService.serviceIcon,
                                        size: 40,
                                        color: relatedService.serviceColor,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          relatedService.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          relatedService.formattedPrice,
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Book Appointment Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Book Appointment',
                    onPressed: _bookAppointment,
                    backgroundColor: service.serviceColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Contact Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contact our support team for any questions about this service or to schedule a consultation.',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
