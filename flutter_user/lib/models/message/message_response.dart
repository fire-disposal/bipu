class MessageResponse {
  final int id;
  final String content;
  final Map<String, dynamic>? contentJson;
  final String msgType; // NORMAL, VOICE, SYSTEM (standardized)
  final String senderBipupuId;
  final String receiverBipupuId;
  final bool isRead;
  final Map<String, dynamic>? pattern;
  final DateTime createdAt;

  MessageResponse({
    required this.id,
    required this.content,
    required this.msgType,
    required this.senderBipupuId,
    required this.receiverBipupuId,
    this.isRead = false,
    this.pattern,
    this.contentJson,
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      id: json['id'],
      content: json['content'] is String
          ? (json['content'] as String)
          : (json['content']?['text']?.toString() ??
                json['content']?.toString() ??
                ''),
      contentJson: json['content'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['content'])
          : null,
      // Prefer new key `message_type`, fallback to legacy `msg_type`.
      msgType: MessageResponse._normalizeMsgType(
        json['message_type'] ?? json['msg_type'] ?? 'NORMAL',
      ),
      senderBipupuId: json['sender_bipupu_id'] ?? '',
      isRead: json['is_read'] ?? false,
      receiverBipupuId: json['receiver_bipupu_id'] ?? '',
      pattern: json['pattern'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static String _normalizeMsgType(dynamic raw) {
    if (raw == null) return 'NORMAL';
    final s = raw.toString().toUpperCase();
    switch (s) {
      case 'SYSTEM':
      case 'ALERT':
      case 'NOTIFICATION':
        return 'SYSTEM';
      case 'VOICE':
      case 'VOICE_TRANSCRIPT':
        return 'VOICE';
      case 'USER':
      case 'USER_POSTCARD':
      case 'COSMIC_BROADCAST':
      case 'SERVICE_REPLY':
      default:
        return 'NORMAL';
    }
  }
}
