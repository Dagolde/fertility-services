import 'package:flutter/foundation.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/api_service.dart';

class MessagesRepository {
  static const String _basePath = '/messages';

  Future<List<Message>> getMyMessages({
    int? conversationId,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      String endpoint = _basePath;
      if (conversationId != null) {
        endpoint = '$_basePath/conversation/$conversationId';
      }

      final response = await ApiService.get(
        endpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = response.data;
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getConversations({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 Fetching conversations from: $_basePath/conversations');
      final response = await ApiService.get(
        '$_basePath/conversations',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      debugPrint('📡 Conversations API response status: ${response.statusCode}');
      debugPrint('📡 Conversations API response data: ${response.data}');

      if (response.statusCode == 200) {
        final conversations = response.data;
        debugPrint('✅ Successfully fetched ${conversations.length} conversations');
        return conversations;
      }
      debugPrint('❌ Failed to fetch conversations: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching conversations: $e');
      rethrow;
    }
  }

  Future<Message?> sendMessage({
    required int receiverId,
    required String content,
    String messageType = 'text',
    int? conversationId,
  }) async {
    try {
      final response = await ApiService.post(
        _basePath,
        data: {
          'receiver_id': receiverId,
          'content': content,
          'message_type': messageType,
          if (conversationId != null) 'conversation_id': conversationId,
        },
      );

      if (response.statusCode == 200) {
        return Message.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Message?> getMessageById(int messageId) async {
    try {
      final response = await ApiService.get('$_basePath/$messageId');

      if (response.statusCode == 200) {
        return Message.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> markMessageAsRead(int messageId) async {
    try {
      final response = await ApiService.put(
        '$_basePath/$messageId/read',
        data: {'is_read': true},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await ApiService.delete('$_basePath/$messageId');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadMessageCount() async {
    try {
      final response = await ApiService.get('$_basePath/unread-count');

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      rethrow;
    }
  }
}
