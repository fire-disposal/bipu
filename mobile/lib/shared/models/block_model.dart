import 'package:json_annotation/json_annotation.dart';

part 'block_model.g.dart';

/// 黑名单用户模型
@JsonSerializable()
class BlockedUserResponse {
  /// 被拉黑用户ID
  final int id;

  /// 被拉黑用户Bipupu ID
  @JsonKey(name: 'blocked_user_bipupu_id')
  final String blockedUserBipupuId;

  /// 被拉黑用户名
  final String username;

  /// 被拉黑用户昵称
  final String? nickname;

  /// 被拉黑用户头像URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 拉黑原因
  final String? reason;

  /// 创建时间（拉黑时间）
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  BlockedUserResponse({
    required this.id,
    required this.blockedUserBipupuId,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.reason,
    required this.createdAt,
  });

  factory BlockedUserResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BlockedUserResponseToJson(this);

  /// 获取显示名称（优先使用昵称，然后是用户名）
  String get displayName {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    return username;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedUserResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          blockedUserBipupuId == other.blockedUserBipupuId &&
          username == other.username &&
          nickname == other.nickname &&
          avatarUrl == other.avatarUrl &&
          reason == other.reason &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      blockedUserBipupuId.hashCode ^
      username.hashCode ^
      nickname.hashCode ^
      avatarUrl.hashCode ^
      reason.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'BlockedUserResponse(id: $id, blockedUserBipupuId: $blockedUserBipupuId, username: $username, nickname: $nickname, avatarUrl: $avatarUrl, reason: $reason, createdAt: $createdAt)';
  }
}

/// 拉黑用户请求
@JsonSerializable()
class BlockUserRequest {
  /// 要拉黑的用户Bipupu ID
  @JsonKey(name: 'blocked_user_bipupu_id')
  final String blockedUserBipupuId;

  /// 拉黑原因（可选）
  final String? reason;

  BlockUserRequest({required this.blockedUserBipupuId, this.reason});

  factory BlockUserRequest.fromJson(Map<String, dynamic> json) =>
      _$BlockUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BlockUserRequestToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockUserRequest &&
          runtimeType == other.runtimeType &&
          blockedUserBipupuId == other.blockedUserBipupuId &&
          reason == other.reason;

  @override
  int get hashCode => blockedUserBipupuId.hashCode ^ reason.hashCode;

  @override
  String toString() =>
      'BlockUserRequest(blockedUserBipupuId: $blockedUserBipupuId, reason: $reason)';
}

/// 黑名单列表响应
@JsonSerializable()
class BlockListResponse {
  /// 黑名单列表
  final List<BlockedUserResponse> blockedUsers;

  /// 总数量
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  BlockListResponse({
    required this.blockedUsers,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory BlockListResponse.fromJson(Map<String, dynamic> json) =>
      _$BlockListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BlockListResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockListResponse &&
          runtimeType == other.runtimeType &&
          blockedUsers == other.blockedUsers &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      blockedUsers.hashCode ^
      total.hashCode ^
      page.hashCode ^
      pageSize.hashCode;

  @override
  String toString() {
    return 'BlockListResponse(blockedUsers: $blockedUsers, total: $total, page: $page, pageSize: $pageSize)';
  }
}
