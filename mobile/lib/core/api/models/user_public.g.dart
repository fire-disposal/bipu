// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_public.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPublic _$UserPublicFromJson(Map<String, dynamic> json) => UserPublic(
  username: json['username'] as String,
  bipupuId: json['bipupu_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isActive: json['is_active'] as bool? ?? true,
  nickname: json['nickname'] as String?,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$UserPublicToJson(UserPublic instance) =>
    <String, dynamic>{
      'username': instance.username,
      'bipupu_id': instance.bipupuId,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
