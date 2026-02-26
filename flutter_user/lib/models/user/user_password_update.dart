part of '../models.dart';

/// 用户密码更新请求模型
@JsonSerializable()
class UserPasswordUpdate {
  /// 旧密码
  @JsonKey(name: 'old_password')
  final String oldPassword;

  /// 新密码
  @JsonKey(name: 'new_password')
  final String newPassword;

  UserPasswordUpdate({required this.oldPassword, required this.newPassword});

  factory UserPasswordUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserPasswordUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$UserPasswordUpdateToJson(this);
}
