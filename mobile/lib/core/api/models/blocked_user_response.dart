// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'blocked_user_response.g.dart';

/// 被拉黑用户信息
@JsonSerializable()
class BlockedUserResponse {
  const BlockedUserResponse({
    required this.bipupuId,
    required this.username,
    required this.blockedAt,
    this.nickname,
    this.avatarUrl,
  });
  
  factory BlockedUserResponse.fromJson(Map<String, Object?> json) => _$BlockedUserResponseFromJson(json);
  
  @JsonKey(name: 'bipupu_id')
  final String bipupuId;
  final String username;
  final String? nickname;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'blocked_at')
  final DateTime blockedAt;

  Map<String, Object?> toJson() => _$BlockedUserResponseToJson(this);
}
