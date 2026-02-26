// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_password_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPasswordUpdate _$UserPasswordUpdateFromJson(Map<String, dynamic> json) =>
    UserPasswordUpdate(
      oldPassword: json['old_password'] as String,
      newPassword: json['new_password'] as String,
    );

Map<String, dynamic> _$UserPasswordUpdateToJson(UserPasswordUpdate instance) =>
    <String, dynamic>{
      'old_password': instance.oldPassword,
      'new_password': instance.newPassword,
    };
