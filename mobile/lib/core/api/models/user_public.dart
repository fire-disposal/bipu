// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_public.g.dart';

/// 用户公开信息（对外API响应）
@JsonSerializable()
class UserPublic {
  const UserPublic({
    required this.username,
    required this.bipupuId,
    required this.createdAt,
    this.isActive = true,
    this.nickname,
    this.avatarUrl,
  });
  
  factory UserPublic.fromJson(Map<String, Object?> json) => _$UserPublicFromJson(json);
  
  final String username;
  @JsonKey(name: 'bipupu_id')
  final String bipupuId;
  final String? nickname;

  /// 头像URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 是否活跃
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$UserPublicToJson(this);
}
