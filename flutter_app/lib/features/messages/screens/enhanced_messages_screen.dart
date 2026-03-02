import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/messages_provider.dart';
import '../../auth/providers/auth_provider.dart';

class EnhancedMessagesScreen extends StatefulWidget {
  const EnhancedMessagesScreen({super.key});

  @override
  State<EnhancedMessagesScreen> createState() => _EnhancedMessagesScreenState();
}

class _EnhancedMessagesScreenState extends State<EnhancedMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().loadConversations();
    });
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
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
      body: Consumer<MessagesProvider>(
        builder: (context, messagesProvider, _) {
          return LoadingOverlay(
            isLoading: messagesProvider.isLoading,
            child: Column(
              children: [
                _buildQuickActions(),
                _buildSearchBar(),
                _buildFilterChips(),
                Expanded(
                  child: messagesProvider.conversations.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationsList(messagesProvider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.medical_services,
              title: 'Medical Team',
              subtitle: 'Contact specialists',
              color: Colors.blue,
              onTap: () => _filterByType('medical'),
            ),
          ),
          const SizedBox(width: AppConfig.smallPadding),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.support_agent,
              title: 'Support',
              subtitle: 'Get help',
              color: Colors.green,
              onTap: () => _filterByType('support'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConfig.smallPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
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
            _buildFilterChip('all', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('unread', 'Unread'),
            const SizedBox(width: 8),
            _buildFilterChip('medical', 'Medical'),
            const SizedBox(width: 8),
            _buildFilterChip('support', 'Support'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildConversationsList(MessagesProvider messagesProvider) {
    final filteredConversations = _filterConversations(messagesProvider.conversations);
    
    return RefreshIndicator(
      onRefresh: () => messagesProvider.loadConversations(forceRefresh: true),
      child: ListView.builder(
        itemCount: filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = filteredConversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  List<dynamic> _filterConversations(List<dynamic> conversations) {
    var filtered = conversations;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conversation) {
        final name = conversation['name']?.toString().toLowerCase() ?? '';
        final message = conversation['lastMessage']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((conversation) {
        return conversation['type'] == _selectedFilter;
      }).toList();
    }

    return filtered;
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final unreadCount = conversation['unreadCount'] ?? 0;
    final isOnline = conversation['isOnline'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConfig.defaultPadding,
        vertical: AppConfig.smallPadding,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: _getAvatarColor(conversation['type']),
              child: Icon(
                _getAvatarIcon(conversation['type']),
                color: Colors.white,
                size: 24,
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation['name'] ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(AppConfig.smallBorderRadius),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${conversation['role'] ?? ''} • ${conversation['hospital'] ?? ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              conversation['lastMessage'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              conversation['timestamp'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleConversationAction(value, conversation),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read),
                  SizedBox(width: 8),
                  Text('Mark as Read'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive),
                  SizedBox(width: 8),
                  Text('Archive'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
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
            Icons.message_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your medical team or support',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNewMessageDialog(),
            icon: const Icon(Icons.message),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String? type) {
    switch (type) {
      case 'doctor':
        return Colors.blue;
      case 'nurse':
        return Colors.green;
      case 'support':
        return Colors.orange;
      case 'coordinator':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAvatarIcon(String? type) {
    switch (type) {
      case 'doctor':
        return Icons.medical_services;
      case 'nurse':
        return Icons.local_hospital;
      case 'support':
        return Icons.support_agent;
      case 'coordinator':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  void _filterByType(String type) {
    setState(() {
      _selectedFilter = type;
    });
  }

  void _openConversation(Map<String, dynamic> conversation) {
    context.push('/messages/${conversation['id']}?userName=${conversation['name']}');
  }

  void _handleConversationAction(String action, Map<String, dynamic> conversation) {
    switch (action) {
      case 'mark_read':
        // TODO: Mark conversation as read
        break;
      case 'archive':
        // TODO: Archive conversation
        break;
      case 'delete':
        // TODO: Delete conversation
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Messages'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Unread Only'),
              value: 'unread',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Medical Team'),
              value: 'medical',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Support'),
              value: 'support',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark All as Read'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mark all as read
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive All'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive all
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Message Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to message settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Contact Medical Team'),
              subtitle: const Text('Speak with doctors and nurses'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to medical team selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help and assistance'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to support chat
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
