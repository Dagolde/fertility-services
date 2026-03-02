import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'message_model.g.dart';

@JsonSerializable()
class Message {
  final int id;
  @JsonKey(name: 'sender_id')
  final int senderId;
  @JsonKey(name: 'receiver_id')
  final int receiverId;
  @JsonKey(name: 'conversation_id')
  final int? conversationId;
  final String content;
  @JsonKey(name: 'message_type')
  final MessageType? messageType;
  @JsonKey(name: 'attachment_url')
  final String? attachmentUrl;
  @JsonKey(name: 'attachment_type')
  final String? attachmentType;
  @JsonKey(name: 'attachment_name')
  final String? attachmentName;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'is_edited')
  final bool? isEdited;
  @JsonKey(name: 'edited_at')
  final DateTime? editedAt;
  @JsonKey(name: 'reply_to_id')
  final int? replyToId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Related objects
  final User? sender;
  final User? receiver;
  final Message? replyTo;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.conversationId,
    required this.content,
    this.messageType,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    required this.isRead,
    this.readAt,
    this.isEdited,
    this.editedAt,
    this.replyToId,
    required this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
    this.replyTo,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  String get messageTypeLabel {
    switch (messageType) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'File';
      case MessageType.audio:
        return 'Audio';
      case MessageType.video:
        return 'Video';
      case MessageType.location:
        return 'Location';
      case MessageType.system:
        return 'System';
      case null:
        return 'Text';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String get formattedTime {
    final hour = createdAt.hour;
    final minute = createdAt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(createdAt).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[createdAt.weekday - 1];
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${createdAt.day} ${months[createdAt.month - 1]}';
    }
  }

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  bool get isImage => messageType == MessageType.image;
  bool get isFile => messageType == MessageType.file;
  bool get isAudio => messageType == MessageType.audio;
  bool get isVideo => messageType == MessageType.video;
  bool get isLocation => messageType == MessageType.location;
  bool get isSystem => messageType == MessageType.system;

  bool get hasReply => replyToId != null;

  String get displayContent {
    switch (messageType) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 ${attachmentName ?? 'File'}';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.location:
        return '📍 Location';
      case MessageType.system:
        return content;
      case null:
        return content;
    }
  }

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    int? conversationId,
    String? content,
    MessageType? messageType,
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    bool? isRead,
    DateTime? readAt,
    bool? isEdited,
    DateTime? editedAt,
    int? replyToId,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? sender,
    User? receiver,
    Message? replyTo,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentName: attachmentName ?? this.attachmentName,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}

@JsonEnum()
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('file')
  file,
  @JsonValue('audio')
  audio,
  @JsonValue('video')
  video,
  @JsonValue('location')
  location,
  @JsonValue('system')
  system,
}

@JsonSerializable()
class Conversation {
  final int id;
  @JsonKey(name: 'participant_1_id')
  final int participant1Id;
  @JsonKey(name: 'participant_2_id')
  final int participant2Id;
  @JsonKey(name: 'last_message_id')
  final int? lastMessageId;
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;
  @JsonKey(name: 'unread_count_1')
  final int unreadCount1;
  @JsonKey(name: 'unread_count_2')
  final int unreadCount2;
  @JsonKey(name: 'is_archived_1')
  final bool isArchived1;
  @JsonKey(name: 'is_archived_2')
  final bool isArchived2;
  @JsonKey(name: 'is_muted_1')
  final bool isMuted1;
  @JsonKey(name: 'is_muted_2')
  final bool isMuted2;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Related objects
  final User? participant1;
  final User? participant2;
  final Message? lastMessage;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessageId,
    this.lastMessageAt,
    required this.unreadCount1,
    required this.unreadCount2,
    required this.isArchived1,
    required this.isArchived2,
    required this.isMuted1,
    required this.isMuted2,
    required this.createdAt,
    required this.updatedAt,
    this.participant1,
    this.participant2,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  User? getOtherParticipant(int currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2;
    } else if (participant2Id == currentUserId) {
      return participant1;
    }
    return null;
  }

  int getUnreadCount(int currentUserId) {
    if (participant1Id == currentUserId) {
      return unreadCount1;
    } else if (participant2Id == currentUserId) {
      return unreadCount2;
    }
    return 0;
  }

  bool isArchived(int currentUserId) {
    if (participant1Id == currentUserId) {
      return isArchived1;
    } else if (participant2Id == currentUserId) {
      return isArchived2;
    }
    return false;
  }

  bool isMuted(int currentUserId) {
    if (participant1Id == currentUserId) {
      return isMuted1;
    } else if (participant2Id == currentUserId) {
      return isMuted2;
    }
    return false;
  }

  String get lastMessageTime {
    if (lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  bool get hasUnreadMessages => unreadCount1 > 0 || unreadCount2 > 0;
}

@JsonSerializable()
class SendMessageRequest {
  @JsonKey(name: 'receiver_id')
  final int receiverId;
  final String content;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  @JsonKey(name: 'reply_to_id')
  final int? replyToId;

  SendMessageRequest({
    required this.receiverId,
    required this.content,
    required this.messageType,
    this.replyToId,
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) => _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

@JsonSerializable()
class EditMessageRequest {
  final String content;

  EditMessageRequest({
    required this.content,
  });

  factory EditMessageRequest.fromJson(Map<String, dynamic> json) => _$EditMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$EditMessageRequestToJson(this);
}

@JsonSerializable()
class MessageSearchRequest {
  final String? query;
  @JsonKey(name: 'conversation_id')
  final int? conversationId;
  @JsonKey(name: 'message_type')
  final MessageType? messageType;
  @JsonKey(name: 'date_from')
  final DateTime? dateFrom;
  @JsonKey(name: 'date_to')
  final DateTime? dateTo;
  @JsonKey(name: 'unread_only')
  final bool? unreadOnly;
  @JsonKey(name: 'sort_by')
  final String? sortBy;
  @JsonKey(name: 'sort_order')
  final String? sortOrder;
  final int? page;
  @JsonKey(name: 'page_size')
  final int? pageSize;

  MessageSearchRequest({
    this.query,
    this.conversationId,
    this.messageType,
    this.dateFrom,
    this.dateTo,
    this.unreadOnly,
    this.sortBy,
    this.sortOrder,
    this.page,
    this.pageSize,
  });

  factory MessageSearchRequest.fromJson(Map<String, dynamic> json) => _$MessageSearchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MessageSearchRequestToJson(this);
}

@JsonSerializable()
class ConversationSettings {
  @JsonKey(name: 'conversation_id')
  final int conversationId;
  @JsonKey(name: 'is_archived')
  final bool? isArchived;
  @JsonKey(name: 'is_muted')
  final bool? isMuted;

  ConversationSettings({
    required this.conversationId,
    this.isArchived,
    this.isMuted,
  });

  factory ConversationSettings.fromJson(Map<String, dynamic> json) => _$ConversationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationSettingsToJson(this);
}

@JsonSerializable()
class MessageStats {
  @JsonKey(name: 'total_conversations')
  final int totalConversations;
  @JsonKey(name: 'total_messages')
  final int totalMessages;
  @JsonKey(name: 'unread_messages')
  final int unreadMessages;
  @JsonKey(name: 'archived_conversations')
  final int archivedConversations;
  @JsonKey(name: 'messages_sent_today')
  final int messagesSentToday;
  @JsonKey(name: 'messages_received_today')
  final int messagesReceivedToday;

  MessageStats({
    required this.totalConversations,
    required this.totalMessages,
    required this.unreadMessages,
    required this.archivedConversations,
    required this.messagesSentToday,
    required this.messagesReceivedToday,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) => _$MessageStatsFromJson(json);
  Map<String, dynamic> toJson() => _$MessageStatsToJson(this);

  bool get hasUnreadMessages => unreadMessages > 0;
  int get totalMessagesToday => messagesSentToday + messagesReceivedToday;
}

@JsonSerializable()
class TypingIndicator {
  @JsonKey(name: 'conversation_id')
  final int conversationId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'is_typing')
  final bool isTyping;
  final DateTime timestamp;

  TypingIndicator({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) => _$TypingIndicatorFromJson(json);
  Map<String, dynamic> toJson() => _$TypingIndicatorToJson(this);
}

@JsonSerializable()
class MessageDeliveryStatus {
  @JsonKey(name: 'message_id')
  final int messageId;
  final MessageDeliveryState status;
  final DateTime timestamp;

  MessageDeliveryStatus({
    required this.messageId,
    required this.status,
    required this.timestamp,
  });

  factory MessageDeliveryStatus.fromJson(Map<String, dynamic> json) => _$MessageDeliveryStatusFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDeliveryStatusToJson(this);
}

@JsonEnum()
enum MessageDeliveryState {
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
  @JsonValue('failed')
  failed,
}
