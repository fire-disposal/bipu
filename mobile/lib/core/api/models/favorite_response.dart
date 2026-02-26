// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'favorite_response.g.dart';

/// 收藏响应
@JsonSerializable()
class FavoriteResponse {
  const FavoriteResponse({
    required this.id,
    required this.messageId,
    required this.createdAt,
    required this.messageContent,
    required this.messageSender,
    required this.messageCreatedAt,
    this.note,
  });
  
  factory FavoriteResponse.fromJson(Map<String, Object?> json) => _$FavoriteResponseFromJson(json);
  
  final int id;
  @JsonKey(name: 'message_id')
  final int messageId;

  /// 备注
  final String? note;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 消息内容
  @JsonKey(name: 'message_content')
  final String messageContent;

  /// 发送者ID
  @JsonKey(name: 'message_sender')
  final String messageSender;

  /// 消息创建时间
  @JsonKey(name: 'message_created_at')
  final DateTime messageCreatedAt;

  Map<String, Object?> toJson() => _$FavoriteResponseToJson(this);
}
