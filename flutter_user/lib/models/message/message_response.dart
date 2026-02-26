import 'dart:convert';

class MessageResponse {
  final int id;
  final String content;
  final String messageType;
  final String senderId;
  final String receiverId;
  final Map<String, dynamic>? pattern;
  final List<int>? waveform;
  final DateTime createdAt;

  MessageResponse({
    required this.id,
    required this.content,
    required this.messageType,
    required this.senderId,
    required this.receiverId,
    this.pattern,
    this.waveform,
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    // 解析波形数据
    List<int>? parseWaveform(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) {
          if (e is int) return e;
          if (e is String) return int.tryParse(e) ?? 0;
          if (e is double) return e.toInt();
          return 0;
        }).toList();
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) {
              if (e is int) return e;
              if (e is String) return int.tryParse(e) ?? 0;
              if (e is double) return e.toInt();
              return 0;
            }).toList();
          }
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    // 解析日期
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return MessageResponse(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      content: json['content'] is String
          ? (json['content'] as String)
          : json['content']?.toString() ?? '',
      messageType: _normalizeMessageType(
        json['message_type'] ?? json['msg_type'] ?? 'NORMAL',
      ),
      senderId: json['sender_id'] ?? json['sender_bipupu_id'] ?? '',
      receiverId: json['receiver_id'] ?? json['receiver_bipupu_id'] ?? '',
      pattern: json['pattern'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['pattern'])
          : null,
      waveform: parseWaveform(json['waveform']),
      createdAt: parseDateTime(json['created_at']),
    );
  }

  static String _normalizeMessageType(dynamic raw) {
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'message_type': messageType,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'pattern': pattern,
    'waveform': waveform,
    'created_at': createdAt.toIso8601String(),
  };
}
