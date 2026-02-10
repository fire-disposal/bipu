class MessageResponse {
  final int id;
  final String content;
  final String msgType; // USER_POSTCARD, SERVICE_REPLY, etc.
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
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      id: json['id'],
      content: json['content'] ?? '',
      msgType: json['msg_type'] ?? 'text',
      senderBipupuId: json['sender_bipupu_id'] ?? '',
      isRead: json['is_read'] ?? false,
      receiverBipupuId: json['receiver_bipupu_id'] ?? '',
      pattern: json['pattern'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
