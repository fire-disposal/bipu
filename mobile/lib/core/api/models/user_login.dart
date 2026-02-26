// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_login.g.dart';

/// 用户登录请求
@JsonSerializable()
class UserLogin {
  const UserLogin({
    required this.username,
    required this.password,
  });
  
  factory UserLogin.fromJson(Map<String, Object?> json) => _$UserLoginFromJson(json);
  
  /// 用户名
  final String username;

  /// 密码
  final String password;

  Map<String, Object?> toJson() => _$UserLoginToJson(this);
}
