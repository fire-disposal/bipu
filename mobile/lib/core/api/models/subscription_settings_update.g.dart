// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSettingsUpdate _$SubscriptionSettingsUpdateFromJson(
  Map<String, dynamic> json,
) => SubscriptionSettingsUpdate(
  isEnabled: json['is_enabled'] as bool? ?? true,
  pushTime: json['push_time'] as String?,
);

Map<String, dynamic> _$SubscriptionSettingsUpdateToJson(
  SubscriptionSettingsUpdate instance,
) => <String, dynamic>{
  'push_time': instance.pushTime,
  'is_enabled': instance.isEnabled,
};
