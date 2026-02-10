import '../message/message_response.dart';

class Favorite {
  final int id;
  final int messageId;
  final int userId;
  final String? note;
  final DateTime createdAt;
  final MessageResponse? message;

  Favorite({
    required this.id,
    required this.messageId,
    required this.userId,
    this.note,
    required this.createdAt,
    this.message,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      messageId: json['message_id'],
      userId: json['user_id'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'] != null
          ? MessageResponse.fromJson(json['message'])
          : null,
    );
  }
}
