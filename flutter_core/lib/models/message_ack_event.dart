class MessageAckEvent {
  final int id;
  final int messageId;
  final String event;
  final DateTime timestamp;

  MessageAckEvent({
    required this.id,
    required this.messageId,
    required this.event,
    required this.timestamp,
  });

  factory MessageAckEvent.fromJson(Map<String, dynamic> json) {
    return MessageAckEvent(
      id: json['id'] as int,
      messageId: json['message_id'] as int,
      event: json['event'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'event': event,
      'timestamp': timestamp.toIso8601String(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'event': event,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}
