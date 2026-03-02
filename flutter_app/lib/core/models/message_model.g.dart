// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: (json['id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
      receiverId: (json['receiver_id'] as num).toInt(),
      conversationId: (json['conversation_id'] as num?)?.toInt(),
      content: json['content'] as String,
      messageType:
          $enumDecodeNullable(_$MessageTypeEnumMap, json['message_type']),
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      attachmentName: json['attachment_name'] as String?,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      isEdited: json['is_edited'] as bool?,
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.parse(json['edited_at'] as String),
      replyToId: (json['reply_to_id'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      sender: json['sender'] == null
          ? null
          : User.fromJson(json['sender'] as Map<String, dynamic>),
      receiver: json['receiver'] == null
          ? null
          : User.fromJson(json['receiver'] as Map<String, dynamic>),
      replyTo: json['replyTo'] == null
          ? null
          : Message.fromJson(json['replyTo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'receiver_id': instance.receiverId,
      'conversation_id': instance.conversationId,
      'content': instance.content,
      'message_type': _$MessageTypeEnumMap[instance.messageType],
      'attachment_url': instance.attachmentUrl,
      'attachment_type': instance.attachmentType,
      'attachment_name': instance.attachmentName,
      'is_read': instance.isRead,
      'read_at': instance.readAt?.toIso8601String(),
      'is_edited': instance.isEdited,
      'edited_at': instance.editedAt?.toIso8601String(),
      'reply_to_id': instance.replyToId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'sender': instance.sender,
      'receiver': instance.receiver,
      'replyTo': instance.replyTo,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.file: 'file',
  MessageType.audio: 'audio',
  MessageType.video: 'video',
  MessageType.location: 'location',
  MessageType.system: 'system',
};

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: (json['id'] as num).toInt(),
      participant1Id: (json['participant_1_id'] as num).toInt(),
      participant2Id: (json['participant_2_id'] as num).toInt(),
      lastMessageId: (json['last_message_id'] as num?)?.toInt(),
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      unreadCount1: (json['unread_count_1'] as num).toInt(),
      unreadCount2: (json['unread_count_2'] as num).toInt(),
      isArchived1: json['is_archived_1'] as bool,
      isArchived2: json['is_archived_2'] as bool,
      isMuted1: json['is_muted_1'] as bool,
      isMuted2: json['is_muted_2'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      participant1: json['participant1'] == null
          ? null
          : User.fromJson(json['participant1'] as Map<String, dynamic>),
      participant2: json['participant2'] == null
          ? null
          : User.fromJson(json['participant2'] as Map<String, dynamic>),
      lastMessage: json['lastMessage'] == null
          ? null
          : Message.fromJson(json['lastMessage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participant_1_id': instance.participant1Id,
      'participant_2_id': instance.participant2Id,
      'last_message_id': instance.lastMessageId,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'unread_count_1': instance.unreadCount1,
      'unread_count_2': instance.unreadCount2,
      'is_archived_1': instance.isArchived1,
      'is_archived_2': instance.isArchived2,
      'is_muted_1': instance.isMuted1,
      'is_muted_2': instance.isMuted2,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'participant1': instance.participant1,
      'participant2': instance.participant2,
      'lastMessage': instance.lastMessage,
    };

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    SendMessageRequest(
      receiverId: (json['receiver_id'] as num).toInt(),
      content: json['content'] as String,
      messageType: $enumDecode(_$MessageTypeEnumMap, json['message_type']),
      replyToId: (json['reply_to_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'receiver_id': instance.receiverId,
      'content': instance.content,
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'reply_to_id': instance.replyToId,
    };

EditMessageRequest _$EditMessageRequestFromJson(Map<String, dynamic> json) =>
    EditMessageRequest(
      content: json['content'] as String,
    );

Map<String, dynamic> _$EditMessageRequestToJson(EditMessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

MessageSearchRequest _$MessageSearchRequestFromJson(
        Map<String, dynamic> json) =>
    MessageSearchRequest(
      query: json['query'] as String?,
      conversationId: (json['conversation_id'] as num?)?.toInt(),
      messageType:
          $enumDecodeNullable(_$MessageTypeEnumMap, json['message_type']),
      dateFrom: json['date_from'] == null
          ? null
          : DateTime.parse(json['date_from'] as String),
      dateTo: json['date_to'] == null
          ? null
          : DateTime.parse(json['date_to'] as String),
      unreadOnly: json['unread_only'] as bool?,
      sortBy: json['sort_by'] as String?,
      sortOrder: json['sort_order'] as String?,
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['page_size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageSearchRequestToJson(
        MessageSearchRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'conversation_id': instance.conversationId,
      'message_type': _$MessageTypeEnumMap[instance.messageType],
      'date_from': instance.dateFrom?.toIso8601String(),
      'date_to': instance.dateTo?.toIso8601String(),
      'unread_only': instance.unreadOnly,
      'sort_by': instance.sortBy,
      'sort_order': instance.sortOrder,
      'page': instance.page,
      'page_size': instance.pageSize,
    };

ConversationSettings _$ConversationSettingsFromJson(
        Map<String, dynamic> json) =>
    ConversationSettings(
      conversationId: (json['conversation_id'] as num).toInt(),
      isArchived: json['is_archived'] as bool?,
      isMuted: json['is_muted'] as bool?,
    );

Map<String, dynamic> _$ConversationSettingsToJson(
        ConversationSettings instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'is_archived': instance.isArchived,
      'is_muted': instance.isMuted,
    };

MessageStats _$MessageStatsFromJson(Map<String, dynamic> json) => MessageStats(
      totalConversations: (json['total_conversations'] as num).toInt(),
      totalMessages: (json['total_messages'] as num).toInt(),
      unreadMessages: (json['unread_messages'] as num).toInt(),
      archivedConversations: (json['archived_conversations'] as num).toInt(),
      messagesSentToday: (json['messages_sent_today'] as num).toInt(),
      messagesReceivedToday: (json['messages_received_today'] as num).toInt(),
    );

Map<String, dynamic> _$MessageStatsToJson(MessageStats instance) =>
    <String, dynamic>{
      'total_conversations': instance.totalConversations,
      'total_messages': instance.totalMessages,
      'unread_messages': instance.unreadMessages,
      'archived_conversations': instance.archivedConversations,
      'messages_sent_today': instance.messagesSentToday,
      'messages_received_today': instance.messagesReceivedToday,
    };

TypingIndicator _$TypingIndicatorFromJson(Map<String, dynamic> json) =>
    TypingIndicator(
      conversationId: (json['conversation_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      isTyping: json['is_typing'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$TypingIndicatorToJson(TypingIndicator instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'is_typing': instance.isTyping,
      'timestamp': instance.timestamp.toIso8601String(),
    };

MessageDeliveryStatus _$MessageDeliveryStatusFromJson(
        Map<String, dynamic> json) =>
    MessageDeliveryStatus(
      messageId: (json['message_id'] as num).toInt(),
      status: $enumDecode(_$MessageDeliveryStateEnumMap, json['status']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MessageDeliveryStatusToJson(
        MessageDeliveryStatus instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'status': _$MessageDeliveryStateEnumMap[instance.status]!,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$MessageDeliveryStateEnumMap = {
  MessageDeliveryState.sent: 'sent',
  MessageDeliveryState.delivered: 'delivered',
  MessageDeliveryState.read: 'read',
  MessageDeliveryState.failed: 'failed',
};
