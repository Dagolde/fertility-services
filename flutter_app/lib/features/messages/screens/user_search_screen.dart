import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/users_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/loading_overlay.dart';

class UserSearchScreen extends StatefulWidget {
  final String? initialUserType;
  
  const UserSearchScreen({Key? key, this.initialUserType}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedUserType;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedUserType = widget.initialUserType ?? 'all';
    
    // Load initial users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 UserSearchScreen initializing with userType: $_selectedUserType');
      
      context.read<UsersProvider>().searchUsers(
        userType: _selectedUserType == 'all' ? null : _selectedUserType,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<UsersProvider>().searchUsers(
        query: query,
        userType: _selectedUserType == 'all' ? null : _selectedUserType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Consumer<UsersProvider>(
              builder: (context, usersProvider, _) {
                return LoadingOverlay(
                  isLoading: usersProvider.isLoading,
                  child: usersProvider.searchResults.isEmpty
                      ? _buildEmptyState()
                      : _buildUsersList(usersProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All Users'),
            const SizedBox(width: 8),
            _buildFilterChip('doctor', 'Doctors'),
            const SizedBox(width: 8),
            _buildFilterChip('nurse', 'Nurses'),
            const SizedBox(width: 8),
            _buildFilterChip('admin', 'Admin'),
            const SizedBox(width: 8),
            _buildFilterChip('user', 'Patients'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedUserType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedUserType = value;
        });
        _onSearchChanged(_searchController.text);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUsersList(UsersProvider usersProvider) {
    return ListView.builder(
      itemCount: usersProvider.searchResults.length,
      itemBuilder: (context, index) {
        final user = usersProvider.searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(User user) {
    final userType = user.userType.name.toLowerCase();
    final userName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConfig.defaultPadding,
        vertical: AppConfig.smallPadding,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: _getAvatarColor(userType),
          child: Icon(
            _getAvatarIcon(userType),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          userName.isNotEmpty ? userName : 'Unknown User',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getUserTypeDisplay(userType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (user.email != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _startConversation(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
            ),
          ),
          child: const Text('Message'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'doctor':
      case 'physician':
        return Colors.blue;
      case 'nurse':
        return Colors.green;
      case 'support':
      case 'admin':
        return Colors.orange;
      case 'coordinator':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAvatarIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'doctor':
      case 'physician':
        return Icons.medical_services;
      case 'nurse':
        return Icons.local_hospital;
      case 'support':
      case 'admin':
        return Icons.support_agent;
      case 'coordinator':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  String _getUserTypeDisplay(String? type) {
    switch (type?.toLowerCase()) {
      case 'doctor':
      case 'physician':
        return 'Medical Doctor';
      case 'nurse':
        return 'Nurse';
      case 'support':
      case 'admin':
        return 'Support Team';
      case 'coordinator':
        return 'Coordinator';
      default:
        return 'Patient';
    }
  }

  void _startConversation(User user) {
    final userName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    context.push('/messages/${user.id}?userName=$userName');
  }
}
