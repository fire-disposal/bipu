import '../common/enums.dart';

class MessageCreateRequest {
  final String title;
  final String content;
  final MessageType messageType;
  final int priority;
  final Map<String, dynamic>? pattern;
  final int? receiverId;

  MessageCreateRequest({
    required this.title,
    required this.content,
    required this.messageType,
    this.priority = 0,
    this.pattern,
    this.receiverId,
  });

  factory MessageCreateRequest.fromJson(Map<String, dynamic> json) {
    return MessageCreateRequest(
      title: json['title'] as String,
      content: json['content'] as String,
      messageType: _parseMessageType(json['message_type'] as String),
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
    'message_type': _messageTypeToString(messageType),
    'priority': priority,
    'pattern': pattern,
    'receiver_id': receiverId,
  };
}

MessageType _parseMessageType(String value) {
  final v = value.toUpperCase();
  switch (v) {
    case 'SYSTEM':
      return MessageType.system;
    case 'VOICE':
      return MessageType.voice;
    case 'NORMAL':
    default:
      return MessageType.normal;
  }
}

String _messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.system:
      return 'SYSTEM';
    case MessageType.voice:
      return 'VOICE';
    case MessageType.normal:
      return 'NORMAL';
  }
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
