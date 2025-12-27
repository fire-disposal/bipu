enum MessageType { system, device, user, alert, notification }

enum MessageStatus { unread, read, archived }

class Message {
  final int id;
  final String title;
  final String content;
  final MessageType messageType;
  final int priority;
  final Map<String, dynamic>? pattern;
  final int senderId;
  final int receiverId;
  final MessageStatus status;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.messageType,
    this.priority = 0,
    this.pattern,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['message_type'],
        orElse: () => MessageType.user,
      ),
      priority: json['priority'] as int? ?? 0,
      pattern: json['pattern'] as Map<String, dynamic>?,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.unread,
      ),
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'message_type': messageType.toString().split('.').last,
      'priority': priority,
      'pattern': pattern,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status.toString().split('.').last,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
