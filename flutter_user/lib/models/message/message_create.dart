import 'package:json_annotation/json_annotation.dart';

part 'message_create.g.dart';

/// 创建消息请求模型
@JsonSerializable()
class MessageCreate {
  /// 接收者ID
  @JsonKey(name: 'receiver_id')
  final String receiverId;

  /// 消息内容
  final String content;

  /// 消息类型
  @JsonKey(name: 'message_type', defaultValue: 'NORMAL')
  final String messageType;

  /// 扩展模式数据
  final Map<String, dynamic>? pattern;

  /// 音频波形数据
  final List<int>? waveform;

  MessageCreate({
    required this.receiverId,
    required this.content,
    this.messageType = 'NORMAL',
    this.pattern,
    this.waveform,
  });

  factory MessageCreate.fromJson(Map<String, dynamic> json) =>
      _$MessageCreateFromJson(json);

  Map<String, dynamic> toJson() => _$MessageCreateToJson(this);
}
