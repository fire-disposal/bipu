// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedUserResponse _$BlockedUserResponseFromJson(Map<String, dynamic> json) =>
    BlockedUserResponse(
      id: (json['id'] as num).toInt(),
      bipupuId: json['bipupu_id'] as String,
      username: json['username'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      blockedAt: DateTime.parse(json['blocked_at'] as String),
    );

Map<String, dynamic> _$BlockedUserResponseToJson(
  BlockedUserResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'bipupu_id': instance.bipupuId,
  'username': instance.username,
  'nickname': instance.nickname,
  'avatar_url': instance.avatarUrl,
  'blocked_at': instance.blockedAt.toIso8601String(),
};

BlockUserRequest _$BlockUserRequestFromJson(Map<String, dynamic> json) =>
    BlockUserRequest(
      blockedUserBipupuId: json['blocked_user_bipupu_id'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$BlockUserRequestToJson(BlockUserRequest instance) =>
    <String, dynamic>{
      'blocked_user_bipupu_id': instance.blockedUserBipupuId,
      'reason': instance.reason,
    };

BlockListResponse _$BlockListResponseFromJson(Map<String, dynamic> json) =>
    BlockListResponse(
      blockedUsers: (json['blockedUsers'] as List<dynamic>)
          .map((e) => BlockedUserResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
    );

Map<String, dynamic> _$BlockListResponseToJson(BlockListResponse instance) =>
    <String, dynamic>{
      'blockedUsers': instance.blockedUsers,
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
    };
