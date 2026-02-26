// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedUserResponse _$BlockedUserResponseFromJson(Map<String, dynamic> json) =>
    BlockedUserResponse(
      bipupuId: json['bipupu_id'] as String,
      username: json['username'] as String,
      blockedAt: DateTime.parse(json['blocked_at'] as String),
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$BlockedUserResponseToJson(
  BlockedUserResponse instance,
) => <String, dynamic>{
  'bipupu_id': instance.bipupuId,
  'username': instance.username,
  'nickname': instance.nickname,
  'avatar_url': instance.avatarUrl,
  'blocked_at': instance.blockedAt.toIso8601String(),
};
