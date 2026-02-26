// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type.dart';

part 'message_response.g.dart';

/// 消息响应
@JsonSerializable()
class MessageResponse {
  const MessageResponse({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.pattern,
    this.waveform,
  });
  
  factory MessageResponse.fromJson(Map<String, Object?> json) => _$MessageResponseFromJson(json);
  
  final int id;

  /// 发送者ID
  @JsonKey(name: 'sender_id')
  final String senderId;

  /// 接收者ID
  @JsonKey(name: 'receiver_id')
  final String receiverId;
  final String content;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final dynamic pattern;
  final List<int>? waveform;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$MessageResponseToJson(this);
}
