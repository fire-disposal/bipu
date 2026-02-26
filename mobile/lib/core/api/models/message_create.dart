// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_type.dart';

part 'message_create.g.dart';

/// 创建消息请求
@JsonSerializable()
class MessageCreate {
  const MessageCreate({
    required this.receiverId,
    required this.content,
    this.pattern,
    this.waveform,
    this.messageType = MessageType.normal,
  });
  
  factory MessageCreate.fromJson(Map<String, Object?> json) => _$MessageCreateFromJson(json);
  
  /// 接收者ID
  @JsonKey(name: 'receiver_id')
  final String receiverId;

  /// 消息内容
  final String content;

  /// 消息类型
  @JsonKey(name: 'message_type')
  final MessageType messageType;

  /// 扩展模式数据
  final dynamic pattern;

  /// 音频波形数据
  final List<int>? waveform;

  Map<String, Object?> toJson() => _$MessageCreateToJson(this);
}
