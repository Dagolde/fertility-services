import 'package:flutter/foundation.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/api_service.dart';
import '../repositories/messages_repository.dart';

class MessagesProvider extends ChangeNotifier {
  final MessagesRepository _messagesRepository = MessagesRepository();
  
  List<Message> _messages = [];
  List<dynamic> _conversations = [];
  int _unreadCount = 0;
  
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  // Getters
  List<Message> get messages => _messages;
  List<dynamic> get conversations => _conversations;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> loadMessages({
    int? conversationId,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final messages = await _messagesRepository.getMyMessages(
        conversationId: conversationId,
      );
      _messages = messages;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Load messages error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversations({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    debugPrint('🔄 Loading conversations...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversations = await _messagesRepository.getConversations();
      debugPrint('📋 Loaded ${conversations.length} conversations');
      _conversations = conversations;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('❌ Load conversations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required int receiverId,
    required String content,
    String messageType = 'text',
    int? conversationId,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _messagesRepository.sendMessage(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        conversationId: conversationId,
      );

      if (message != null) {
        _messages.add(message);
        _isSending = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to send message';
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Send message error: $e');
    }

    _isSending = false;
    notifyListeners();
    return false;
  }

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void updateMessageStatus(int messageId, bool isRead) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(isRead: isRead);
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> markMessageAsRead(int messageId) async {
    try {
      final success = await _messagesRepository.markMessageAsRead(messageId);
      
      if (success) {
        // Update local message status
        final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(isRead: true);
          notifyListeners();
        }
        
        // Update unread count
        await loadUnreadCount();
      }
    } catch (e) {
      debugPrint('Mark message as read error: $e');
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      final success = await _messagesRepository.deleteMessage(messageId);
      
      if (success) {
        _messages.removeWhere((msg) => msg.id == messageId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Delete message error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _messagesRepository.getUnreadMessageCount();
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Load unread count error: $e');
    }
  }

  List<Message> getMessagesForConversation(int conversationId) {
    return _messages
        .where((msg) => msg.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
