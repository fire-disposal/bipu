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
    required this.senderBipupuId,
    required this.receiverBipupuId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.pattern,
    this.waveform,
  });
  
  factory MessageResponse.fromJson(Map<String, Object?> json) => _$MessageResponseFromJson(json);
  
  /// 消息ID
  final int id;

  /// 发送者的bipupu_id
  @JsonKey(name: 'sender_bipupu_id')
  final String senderBipupuId;

  /// 接收者的bipupu_id
  @JsonKey(name: 'receiver_bipupu_id')
  final String receiverBipupuId;

  /// 消息内容
  final String content;

  /// 消息类型
  @JsonKey(name: 'message_type')
  final MessageType messageType;

  /// 消息创建时间
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 扩展模式数据
  final dynamic pattern;

  /// 音频波形数据
  final List<int>? waveform;

  Map<String, Object?> toJson() => _$MessageResponseToJson(this);
}
