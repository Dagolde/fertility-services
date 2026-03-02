import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../../core/config/app_config.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/simple_text_field.dart';
import '../providers/messages_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? userName;
  
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  
  WebSocketChannel? _channel;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  User? _currentUser;
  User? _otherUser;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.sink.close();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // Get current user
      final authProvider = context.read<AuthProvider>();
      _currentUser = authProvider.currentUser;
      
      if (_currentUser == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Parse conversation ID to get other user ID
      _otherUserId = int.tryParse(widget.conversationId);
      if (_otherUserId == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid conversation ID';
            _isLoading = false;
          });
        }
        return;
      }

      // Load existing messages
      await _loadMessages();
      
      // Get other user details
      await _loadOtherUserDetails();
      
      // Connect to WebSocket
      await _connectWebSocket();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize chat: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      debugPrint('📨 Loading messages for conversation with user: $_otherUserId');
      final messagesProvider = context.read<MessagesProvider>();
      await messagesProvider.loadMessages(conversationId: _otherUserId);
      
      debugPrint('📨 Loaded ${messagesProvider.messages.length} messages');
      
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messagesProvider.messages);
        });
      }
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _loadOtherUserDetails() async {
    try {
      final response = await ApiService.get('/users/$_otherUserId');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _otherUser = User.fromJson(response.data);
        });
      }
    } catch (e) {
      print('Error loading user details: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final token = await StorageService.getSecureString('auth_token');
      if (token == null) {
        throw Exception('No authentication token');
      }

      // Connect to WebSocket
      final wsUrl = '${AppConfig.baseUrl.replaceAll('http://', 'ws://')}/messages/ws/${_currentUser!.id}?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Listen for messages
      _channel!.stream.listen(
        (data) {
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
          }
          _reconnectWebSocket();
        },
        onDone: () {
          print('WebSocket connection closed');
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
          }
          _reconnectWebSocket();
        },
      );

      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isConnected) {
        _connectWebSocket();
      }
    });
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = json.decode(data.toString());
      final type = message['type'];

      switch (type) {
        case 'connection_established':
          print('WebSocket connected');
          if (mounted) {
            setState(() {
              _isConnected = true;
            });
          }
          break;

        case 'new_message':
          final messageData = message['message'];
          final newMessage = Message.fromJson(messageData);
          
          if (mounted) {
            setState(() {
              _messages.add(newMessage);
            });
          }
          
          // Scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          break;

        case 'typing_start':
          if (message['user_id'] == _otherUserId && mounted) {
            setState(() {
              _isTyping = true;
            });
          }
          break;

        case 'typing_stop':
          if (message['user_id'] == _otherUserId && mounted) {
            setState(() {
              _isTyping = false;
            });
          }
          break;

        case 'read_receipt':
          final messageId = message['message_id'];
          if (mounted) {
            setState(() {
              final index = _messages.indexWhere((msg) => msg.id == messageId);
              if (index != -1) {
                _messages[index] = _messages[index].copyWith(isRead: true);
              }
            });
          }
          break;

        case 'pong':
          // Handle ping/pong for connection health
          break;
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _otherUserId == null) return;

    // Create a temporary message for immediate display
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      senderId: _currentUser!.id,
      receiverId: _otherUserId!,
      conversationId: _otherUserId, // Use receiver ID as conversation ID for now
      content: content,
      messageType: MessageType.text,
      isRead: false,
      isEdited: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add message to local list immediately
    if (mounted) {
      setState(() {
        _messages.add(tempMessage);
      });
    }

    // Clear input
    _messageController.clear();

    // Stop typing indicator
    _stopTyping();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      debugPrint('📤 Sending message to user: $_otherUserId, content: $content');
      // Send via HTTP API (more reliable than WebSocket for sending)
      final messagesProvider = context.read<MessagesProvider>();
      final success = await messagesProvider.sendMessage(
        receiverId: _otherUserId!,
        content: content,
      );
      
      debugPrint('📤 Message send result: $success');
      
      // Reload messages to get the real message with proper ID
      await _loadMessages();
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTyping() {
    if (!_isTyping) {
      setState(() {
        _isTyping = true;
      });
      
      // Send typing indicator
      if (_isConnected && _channel != null && _otherUserId != null) {
        _channel!.sink.add(json.encode({
          'type': 'typing_start',
          'receiver_id': _otherUserId,
        }));
      }
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      setState(() {
        _isTyping = false;
      });
      
      // Send typing stop indicator
      if (_isConnected && _channel != null && _otherUserId != null) {
        _channel!.sink.add(json.encode({
          'type': 'typing_stop',
          'receiver_id': _otherUserId,
        }));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Text(
                _otherUser?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.fullName ?? widget.userName ?? 'Unknown User',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    Expanded(
                      child: _buildMessagesList(),
                    ),
                    if (_isTyping) _buildTypingIndicator(),
                    _buildMessageInput(),
                  ],
                ),
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
            'Error Loading Chat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Retry',
            onPressed: _initializeChat,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUser?.id;
        
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                _otherUser?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead ? Colors.blue[200] : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              _otherUser?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[600]?.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SimpleTextField(
              controller: _messageController,
              hintText: 'Type a message...',
                             onChanged: (value) {
                 if (value?.isNotEmpty == true) {
                   _startTyping();
                 } else {
                   _stopTyping();
                 }
               },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement clear chat
              },
            ),
          ],
        ),
      ),
    );
  }
}
