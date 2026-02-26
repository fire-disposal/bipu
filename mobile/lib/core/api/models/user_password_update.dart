// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_password_update.g.dart';

/// 更新密码请求
@JsonSerializable()
class UserPasswordUpdate {
  const UserPasswordUpdate({
    required this.oldPassword,
    required this.newPassword,
  });
  
  factory UserPasswordUpdate.fromJson(Map<String, Object?> json) => _$UserPasswordUpdateFromJson(json);
  
  /// 原密码
  @JsonKey(name: 'old_password')
  final String oldPassword;

  /// 新密码
  @JsonKey(name: 'new_password')
  final String newPassword;

  Map<String, Object?> toJson() => _$UserPasswordUpdateToJson(this);
}
