// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_response.dart';

part 'message_poll_response.g.dart';

/// 轮询消息响应.
///
/// 包含自上次轮询后收到的新消息.
@JsonSerializable()
class MessagePollResponse {
  const MessagePollResponse({
    required this.messages,
    this.hasMore = false,
  });
  
  factory MessagePollResponse.fromJson(Map<String, Object?> json) => _$MessagePollResponseFromJson(json);
  
  /// 新消息列表
  final List<MessageResponse> messages;

  /// 是否有更多消息未返回（超过限制）
  @JsonKey(name: 'has_more')
  final bool hasMore;

  Map<String, Object?> toJson() => _$MessagePollResponseToJson(this);
}
