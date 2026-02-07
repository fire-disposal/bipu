import '../common/enums.dart';

enum MessageStatus { unread, read, archived }

class MessageResponse {
  final String title;
  final String content;
  final MessageType messageType;
  final int priority;
  final Map<String, dynamic>? pattern;
  final int senderId;
  final int receiverId;
  final int id;
  final MessageStatus status;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  MessageResponse({
    required this.title,
    required this.content,
    required this.messageType,
    this.priority = 0,
    this.pattern,
    required this.senderId,
    required this.receiverId,
    required this.id,
    required this.status,
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      title: json['title'] as String,
      content: json['content'] as String,
      messageType: _parseMessageType(json['messageType'] as String?),
      priority: json['priority'] ?? 0,
      pattern: (json['pattern'] as Map<String, dynamic>?)
          ?.cast<String, dynamic>(),
      senderId: json['senderId'] is int
          ? json['senderId'] as int
          : int.parse(json['senderId'].toString()),
      receiverId: json['receiverId'] is int
          ? json['receiverId'] as int
          : int.parse(json['receiverId'].toString()),
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      status: _parseMessageStatus(json['status'] as String?),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'messageType': messageType.name,
    'priority': priority,
    'pattern': pattern,
    'senderId': senderId,
    'receiverId': receiverId,
    'id': id,
    'status': status.name,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };
}

MessageType _parseMessageType(String? value) {
  if (value == null) return MessageType.user;
  try {
    return MessageType.values.firstWhere((e) => e.name == value);
  } catch (_) {
    return MessageType.user;
  }
}

MessageStatus _parseMessageStatus(String? value) {
  if (value == null) return MessageStatus.unread;
  try {
    return MessageStatus.values.firstWhere((e) => e.name == value);
  } catch (_) {
    return MessageStatus.unread;
  }
}
