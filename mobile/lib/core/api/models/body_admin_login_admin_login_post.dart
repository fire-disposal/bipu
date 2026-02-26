// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'body_admin_login_admin_login_post.g.dart';

@JsonSerializable()
class BodyAdminLoginAdminLoginPost {
  const BodyAdminLoginAdminLoginPost({
    required this.username,
    required this.password,
  });
  
  factory BodyAdminLoginAdminLoginPost.fromJson(Map<String, Object?> json) => _$BodyAdminLoginAdminLoginPostFromJson(json);
  
  final String username;
  final String password;

  Map<String, Object?> toJson() => _$BodyAdminLoginAdminLoginPostToJson(this);
}
