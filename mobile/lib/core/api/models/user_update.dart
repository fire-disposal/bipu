// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'gender.dart';

part 'user_update.g.dart';

/// 更新用户信息请求
@JsonSerializable()
class UserUpdate {
  const UserUpdate({
    this.nickname,
    this.birthday,
    this.zodiac,
    this.age,
    this.bazi,
    this.gender,
    this.mbti,
    this.birthTime,
    this.birthplace,
  });
  
  factory UserUpdate.fromJson(Map<String, Object?> json) => _$UserUpdateFromJson(json);
  
  /// 昵称
  final String? nickname;

  /// 公历生日，格式 YYYY-MM-DD
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

  /// 出生时间，格式: HH:MM
  @JsonKey(name: 'birth_time')
  final String? birthTime;

  /// 出生地
  final String? birthplace;

  Map<String, Object?> toJson() => _$UserUpdateToJson(this);
}
