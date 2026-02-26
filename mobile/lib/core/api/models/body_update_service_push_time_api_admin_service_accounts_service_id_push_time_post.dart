// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'body_update_service_push_time_api_admin_service_accounts_service_id_push_time_post.g.dart';

@JsonSerializable()
class BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost {
  const BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost({
    required this.pushTime,
    this.description,
  });
  
  factory BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost.fromJson(Map<String, Object?> json) => _$BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePostFromJson(json);
  
  @JsonKey(name: 'push_time')
  final String pushTime;
  final String? description;

  Map<String, Object?> toJson() => _$BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePostToJson(this);
}
