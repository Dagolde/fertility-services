import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';

class ReviewsListingScreen extends StatefulWidget {
  final int hospitalId;
  final String hospitalName;

  const ReviewsListingScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<ReviewsListingScreen> createState() => _ReviewsListingScreenState();
}

class _ReviewsListingScreenState extends State<ReviewsListingScreen> {
  List<dynamic> _reviews = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  int? _selectedRatingFilter;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  
  double _averageRating = 0.0;
  Map<String, int> _ratingDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (!loadMore) {
        _currentPage = 1;
        _reviews = [];
      }
    });

    try {
      final queryParams = {
        'hospital_id': widget.hospitalId.toString(),
        'page': _currentPage.toString(),
        'limit': '20',
      };

      if (_selectedRatingFilter != null) {
        queryParams['rating'] = _selectedRatingFilter.toString();
      }

      final response = await ApiService.get(
        '/reviews',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final reviews = data['reviews'] as List;
        final pagination = data['pagination'];
        
        setState(() {
          if (loadMore) {
            _reviews.addAll(reviews);
          } else {
            _reviews = reviews;
          }
          _currentPage = pagination['page'];
          _totalPages = pagination['pages'];
          _hasMorePages = _currentPage < _totalPages;
          _averageRating = (data['average_rating'] ?? 0.0).toDouble();
          _ratingDistribution = Map<String, int>.from(
            data['rating_distribution']?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {}
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_hasMorePages && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      await _loadReviews(loadMore: true);
    }
  }

  Future<void> _flagReview(int reviewId) async {
    try {
      final response = await ApiService.post(
        '/reviews/$reviewId/flag',
        data: {'reason': 'User reported'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review flagged for moderation'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadReviews(); // Reload to reflect changes
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to flag review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFlagDialog(int reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Review'),
        content: const Text('Are you sure you want to flag this review as inappropriate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _flagReview(reviewId);
            },
            child: const Text('Flag', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _applyRatingFilter(int? rating) {
    setState(() {
      _selectedRatingFilter = rating;
    });
    _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.hospitalName} Reviews'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Rating summary
          _buildRatingSummary(),
          
          // Filter chips
          _buildFilterChips(),
          
          const Divider(height: 1),
          
          // Reviews list
          Expanded(
            child: _buildReviewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                ],
              ),
              Text(
                '${_reviews.length} reviews',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildRatingBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBars() {
    final total = _ratingDistribution.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      children: [5, 4, 3, 2, 1].map((rating) {
        final count = _ratingDistribution[rating.toString()] ?? 0;
        final percentage = total > 0 ? count / total : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text('$rating', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              const SizedBox(width: 8),
              Text('$count', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedRatingFilter == null,
            onSelected: (selected) => _applyRatingFilter(null),
          ),
          const SizedBox(width: 8),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$rating'),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                ),
                selected: _selectedRatingFilter == rating,
                onSelected: (selected) => _applyRatingFilter(rating),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading && _reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this hospital',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading &&
            _hasMorePages &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreReviews();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length + (_hasMorePages ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == _reviews.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return _buildReviewCard(_reviews[index]);
        },
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final rating = review['rating'] as int;
    final comment = review['comment'] as String?;
    final createdAt = DateTime.parse(review['created_at']);
    final hospitalResponse = review['hospital_response'] as String?;
    final hospitalResponseDate = review['hospital_response_date'] != null
        ? DateTime.parse(review['hospital_response_date'])
        : null;
    final reviewId = review['id'] as int;
    final isHidden = review['is_hidden'] as bool? ?? false;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rating and flag button
            Row(
              children: [
                // User avatar placeholder
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anonymous User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isHidden)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 20),
                    onPressed: () => _showFlagDialog(reviewId),
                    tooltip: 'Flag review',
                  ),
              ],
            ),
            
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            
            // Hospital response
            if (hospitalResponse != null && hospitalResponse.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Hospital Response',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                        if (hospitalResponseDate != null) ...[
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, yyyy').format(hospitalResponseDate),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hospitalResponse,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            
            if (isHidden) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'This review has been flagged and is under moderation',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
