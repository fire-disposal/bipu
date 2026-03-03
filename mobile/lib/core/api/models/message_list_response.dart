// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'message_response.dart';

part 'message_list_response.g.dart';

/// 消息列表响应
@JsonSerializable()
class MessageListResponse {
  const MessageListResponse({
    required this.messages,
    required this.total,
    required this.page,
    required this.pageSize,
  });
  
  factory MessageListResponse.fromJson(Map<String, Object?> json) => _$MessageListResponseFromJson(json);
  
  /// 消息列表
  final List<MessageResponse> messages;

  /// 总消息数
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$MessageListResponseToJson(this);
}
