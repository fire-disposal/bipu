// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCreate _$UserCreateFromJson(Map<String, dynamic> json) => UserCreate(
  username: json['username'] as String,
  password: json['password'] as String,
  nickname: json['nickname'] as String?,
);

Map<String, dynamic> _$UserCreateToJson(UserCreate instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'nickname': instance.nickname,
    };
