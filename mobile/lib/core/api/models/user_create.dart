// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_create.g.dart';

/// 创建用户请求
@JsonSerializable()
class UserCreate {
  const UserCreate({
    required this.username,
    required this.password,
    this.nickname,
  });
  
  factory UserCreate.fromJson(Map<String, Object?> json) => _$UserCreateFromJson(json);
  
  /// 用户名
  final String username;

  /// 密码
  final String password;

  /// 昵称
  final String? nickname;

  Map<String, Object?> toJson() => _$UserCreateToJson(this);
}
