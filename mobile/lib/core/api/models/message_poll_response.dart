// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_response.dart';

part 'message_poll_response.g.dart';

/// 轮询消息响应（长轮询）
@JsonSerializable()
class MessagePollResponse {
  const MessagePollResponse({
    required this.messages,
    this.hasMore = false,
  });
  
  factory MessagePollResponse.fromJson(Map<String, Object?> json) => _$MessagePollResponseFromJson(json);
  
  final List<MessageResponse> messages;

  /// 是否有更多消息
  @JsonKey(name: 'has_more')
  final bool hasMore;

  Map<String, Object?> toJson() => _$MessagePollResponseToJson(this);
}
