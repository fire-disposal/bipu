/// 消息数据模型
/// 定义消息相关的数据结构
library;

/// 消息模型
class Message {
  final String id;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final MessageDirection direction;
  final String? senderId;
  final String? receiverId;
  final String? deviceId;
  final DateTime? scheduledTime;
  final DateTime? sentTime;
  final DateTime? receivedTime;
  final DateTime? readTime;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.pending,
    required this.direction,
    this.senderId,
    this.receiverId,
    this.deviceId,
    this.scheduledTime,
    this.sentTime,
    this.receivedTime,
    this.readTime,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 创建
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      direction: MessageDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => MessageDirection.outgoing,
      ),
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      deviceId: json['device_id'] as String?,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      sentTime: json['sent_time'] != null
          ? DateTime.parse(json['sent_time'] as String)
          : null,
      receivedTime: json['received_time'] != null
          ? DateTime.parse(json['received_time'] as String)
          : null,
      readTime: json['read_time'] != null
          ? DateTime.parse(json['read_time'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'status': status.name,
      'direction': direction.name,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'device_id': deviceId,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'sent_time': sentTime?.toIso8601String(),
      'received_time': receivedTime?.toIso8601String(),
      'read_time': readTime?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 复制对象
  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageStatus? status,
    MessageDirection? direction,
    String? senderId,
    String? receiverId,
    String? deviceId,
    DateTime? scheduledTime,
    DateTime? sentTime,
    DateTime? receivedTime,
    DateTime? readTime,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      deviceId: deviceId ?? this.deviceId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      sentTime: sentTime ?? this.sentTime,
      receivedTime: receivedTime ?? this.receivedTime,
      readTime: readTime ?? this.readTime,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, type: $type, status: $status, direction: $direction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 消息类型枚举
enum MessageType {
  text, // 文本消息
  voice, // 语音消息
  image, // 图片消息
  video, // 视频消息
  file, // 文件消息
  location, // 位置消息
  command, // 命令消息
  status, // 状态消息
  system, // 系统消息
}

/// 消息状态枚举
enum MessageStatus {
  pending, // 待发送
  sending, // 发送中
  sent, // 已发送
  delivered, // 已送达
  read, // 已读
  failed, // 发送失败
  cancelled, // 已取消
}

/// 消息方向枚举
enum MessageDirection {
  outgoing, // 发出
  incoming, // 接收
}

/// 消息会话模型
class MessageConversation {
  final String id;
  final String? title;
  final String? participantId;
  final String? participantName;
  final String? participantAvatar;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? lastActivityTime;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MessageConversation({
    required this.id,
    this.title,
    this.participantId,
    this.participantName,
    this.participantAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastActivityTime,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 创建
  factory MessageConversation.fromJson(Map<String, dynamic> json) {
    return MessageConversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      participantId: json['participant_id'] as String?,
      participantName: json['participant_name'] as String?,
      participantAvatar: json['participant_avatar'] as String?,
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastActivityTime: json['last_activity_time'] != null
          ? DateTime.parse(json['last_activity_time'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_avatar': participantAvatar,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'last_activity_time': lastActivityTime?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 复制对象
  MessageConversation copyWith({
    String? id,
    String? title,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastActivityTime,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 消息模板模型
class MessageTemplate {
  final String id;
  final String name;
  final String content;
  final MessageType type;
  final Map<String, dynamic>? variables;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MessageTemplate({
    required this.id,
    required this.name,
    required this.content,
    this.type = MessageType.text,
    this.variables,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 创建
  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      variables: json['variables'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'type': type.name,
      'variables': variables,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 渲染模板
  String render(Map<String, dynamic> variables) {
    String result = content;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }
}

/// 消息统计模型
class MessageStats {
  final String userId;
  final int totalSent;
  final int totalReceived;
  final int totalUnread;
  final int totalConversations;
  final Map<MessageType, int> typeStats;
  final DateTime lastCalculated;

  MessageStats({
    required this.userId,
    required this.totalSent,
    required this.totalReceived,
    required this.totalUnread,
    required this.totalConversations,
    required this.typeStats,
    required this.lastCalculated,
  });

  /// 从 JSON 创建
  factory MessageStats.fromJson(Map<String, dynamic> json) {
    return MessageStats(
      userId: json['user_id'] as String,
      totalSent: json['total_sent'] as int,
      totalReceived: json['total_received'] as int,
      totalUnread: json['total_unread'] as int,
      totalConversations: json['total_conversations'] as int,
      typeStats: (json['type_stats'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          MessageType.values.firstWhere((e) => e.name == k),
          v as int,
        ),
      ),
      lastCalculated: DateTime.parse(json['last_calculated'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_sent': totalSent,
      'total_received': totalReceived,
      'total_unread': totalUnread,
      'total_conversations': totalConversations,
      'type_stats': typeStats.map((k, v) => MapEntry(k.name, v)),
      'last_calculated': lastCalculated.toIso8601String(),
    };
  }
}
