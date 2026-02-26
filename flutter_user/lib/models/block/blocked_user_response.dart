import 'package:json_annotation/json_annotation.dart';

part 'blocked_user_response.g.dart';

/// 被屏蔽用户响应模型
@JsonSerializable()
class BlockedUserResponse {
  /// 用户ID
  @JsonKey(name: 'bipupu_id')
  final String bipupuId;

  /// 用户名
  final String username;

  /// 昵称
  final String? nickname;

  /// 头像URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 屏蔽时间
  @JsonKey(name: 'blocked_at')
  final DateTime blockedAt;

  BlockedUserResponse({
    required this.bipupuId,
    required this.username,
    this.nickname,
    this.avatarUrl,
    required this.blockedAt,
  });

  factory BlockedUserResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedUserResponseToJson(this);
}
