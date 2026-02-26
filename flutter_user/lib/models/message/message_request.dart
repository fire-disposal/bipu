class MessageCreateRequest {
  final String title;
  final String content;
  final String messageType; // 'NORMAL' | 'VOICE' | 'SYSTEM'
  final int priority;
  final Map<String, dynamic>? pattern;
  final int? receiverId;

  MessageCreateRequest({
    required this.title,
    required this.content,
    this.messageType = 'NORMAL',
    this.priority = 0,
    this.pattern,
    this.receiverId,
  });

  factory MessageCreateRequest.fromJson(Map<String, dynamic> json) {
    final rawType = (json['message_type'] ?? json['msg_type'] ?? 'NORMAL')
        .toString();
    final type = rawType.toUpperCase();
    return MessageCreateRequest(
      title: json['title'] as String,
      content: json['content'] as String,
      messageType: type,
      priority: json['priority'] ?? 0,
      pattern: (json['pattern'] as Map<String, dynamic>?)
          ?.cast<String, dynamic>(),
      receiverId: json['receiver_id'] != null
          ? (json['receiver_id'] is int
                ? json['receiver_id'] as int
                : int.parse(json['receiver_id'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'message_type': messageType,
    'priority': priority,
    'pattern': pattern,
    'receiver_id': receiverId,
  };
}

class MessageAckEventCreate {
  final int messageId;
  final String event;
  final DateTime? timestamp;

  MessageAckEventCreate({
    required this.messageId,
    required this.event,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'event': event,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };
}
