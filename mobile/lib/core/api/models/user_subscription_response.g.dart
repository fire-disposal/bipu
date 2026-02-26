// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_subscription_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSubscriptionResponse _$UserSubscriptionResponseFromJson(
  Map<String, dynamic> json,
) => UserSubscriptionResponse(
  service: ServiceAccountResponse.fromJson(
    json['service'] as Map<String, dynamic>,
  ),
  settings: SubscriptionSettingsResponse.fromJson(
    json['settings'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$UserSubscriptionResponseToJson(
  UserSubscriptionResponse instance,
) => <String, dynamic>{
  'service': instance.service,
  'settings': instance.settings,
};
