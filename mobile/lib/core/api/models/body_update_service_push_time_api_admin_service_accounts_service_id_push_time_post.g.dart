// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_update_service_push_time_api_admin_service_accounts_service_id_push_time_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost
_$BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePostFromJson(
  Map<String, dynamic> json,
) => BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost(
  pushTime: json['push_time'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic>
_$BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePostToJson(
  BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost
  instance,
) => <String, dynamic>{
  'push_time': instance.pushTime,
  'description': instance.description,
};
