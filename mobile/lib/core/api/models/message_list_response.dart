// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_response.dart';

part 'message_list_response.g.dart';

/// 消息列表响应（支持增量同步）
@JsonSerializable()
class MessageListResponse {
  const MessageListResponse({
    required this.messages,
    required this.total,
    required this.page,
    required this.pageSize,
  });
  
  factory MessageListResponse.fromJson(Map<String, Object?> json) => _$MessageListResponseFromJson(json);
  
  final List<MessageResponse> messages;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$MessageListResponseToJson(this);
}
