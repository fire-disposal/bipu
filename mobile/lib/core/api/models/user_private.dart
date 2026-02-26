// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'gender.dart';

part 'user_private.g.dart';

/// 用户私有信息（对用户自己可见）
@JsonSerializable()
class UserPrivate {
  const UserPrivate({
    required this.username,
    required this.bipupuId,
    required this.createdAt,
    this.isActive = true,
    this.nickname,
    this.avatarUrl,
    this.birthday,
    this.zodiac,
    this.age,
    this.bazi,
    this.gender,
    this.mbti,
    this.birthTime,
    this.birthplace,
    this.lastActive,
    this.updatedAt,
  });
  
  factory UserPrivate.fromJson(Map<String, Object?> json) => _$UserPrivateFromJson(json);
  
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

  /// 公历生日
  final DateTime? birthday;

  /// 西方星座
  final String? zodiac;

  /// 年龄
  final int? age;

  /// 生辰八字
  final String? bazi;

  /// 性别
  final Gender? gender;

  /// MBTI类型
  final String? mbti;

  /// 出生时间
  @JsonKey(name: 'birth_time')
  final String? birthTime;

  /// 出生地
  final String? birthplace;
  @JsonKey(name: 'last_active')
  final DateTime? lastActive;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$UserPrivateToJson(this);
}
