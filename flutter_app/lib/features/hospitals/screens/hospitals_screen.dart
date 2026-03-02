import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/hospital_model.dart';
import '../../../shared/widgets/simple_text_field.dart';
import '../providers/hospitals_provider.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'IVF Centers', 'Fertility Clinics', 'Sperm Banks', 'Surrogacy Centers'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalsProvider>().loadHospitals();
    });
  }

  List<Hospital> get _filteredHospitals {
    final hospitalsProvider = context.watch<HospitalsProvider>();
    final hospitals = hospitalsProvider.hospitals;
    
    var filtered = hospitals.where((hospital) {
      final matchesSearch = hospital.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()) ||
          (hospital.description?.toLowerCase() ?? '')
              .contains(_searchController.text.toLowerCase());
      
      // For now, we'll use 'All' filter since we don't have hospital types in the model
      // In a real implementation, you'd add a type field to the Hospital model
      final matchesFilter = _selectedFilter == 'All';
      
      return matchesSearch && matchesFilter;
    }).toList();

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Hospitals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/hospitals/map'),
          ),
        ],
      ),
      body: Consumer<HospitalsProvider>(
        builder: (context, hospitalsProvider, child) {
          if (hospitalsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hospitalsProvider.errorMessage != null) {
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
                    'Error loading hospitals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.red[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hospitalsProvider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => hospitalsProvider.loadHospitals(forceRefresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: _filteredHospitals.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => hospitalsProvider.loadHospitals(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppConfig.defaultPadding),
                          itemCount: _filteredHospitals.length,
                          itemBuilder: (context, index) {
                            final hospital = _filteredHospitals[index];
                            return _buildHospitalCard(hospital);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        children: [
          SimpleTextField(
            controller: _searchController,
            labelText: 'Search hospitals or services',
            prefixIcon: Icons.search,
            onChanged: (value) {
              setState(() {});
              // Debounce search to avoid too many API calls
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  context.read<HospitalsProvider>().searchHospitals(value ?? '');
                }
              });
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/hospitals/${hospital.id}'),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hospital.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hospital.isActive ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                              ),
                              child: Text(
                                hospital.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hospital.isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                          ),
                          child: Text(
                            hospital.statusText,
                            style: TextStyle(
                              color: hospital.isVerified ? Colors.green[700] : Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hospital.fullAddress,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (hospital.operatingHours != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hospital.operatingHours!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hospital.displayRating,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${hospital.totalReviews} reviews)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Spacer(),
                  if (hospital.phone != null)
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
              if (hospital.description != null && hospital.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  hospital.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (hospital.phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(hospital.phone!),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                      ),
                    ),
                  if (hospital.phone != null) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDirections(hospital.fullAddress),
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/appointments/book?hospitalId=${hospital.id}'),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Book'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hospitals found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedFilter = 'All';
                });
                context.read<HospitalsProvider>().loadHospitals(forceRefresh: true);
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) {
    // In a real app, you would use url_launcher to make phone calls
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {},
        ),
      ),
    );
  }

  void _openDirections(String address) {
    // In a real app, you would use url_launcher to open maps
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to $address...'),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {},
        ),
      ),
    );
  }
}
