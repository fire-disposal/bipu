// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_settings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSettingsResponse _$SubscriptionSettingsResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionSettingsResponse(
  serviceName: json['service_name'] as String,
  subscribedAt: DateTime.parse(json['subscribed_at'] as String),
  isEnabled: json['is_enabled'] as bool? ?? true,
  pushTimeSource: json['push_time_source'] == null
      ? PushTimeSource.none
      : PushTimeSource.fromJson(json['push_time_source'] as String),
  pushTime: json['push_time'] as String?,
  serviceDescription: json['service_description'] as String?,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SubscriptionSettingsResponseToJson(
  SubscriptionSettingsResponse instance,
) => <String, dynamic>{
  'push_time': instance.pushTime,
  'is_enabled': instance.isEnabled,
  'service_name': instance.serviceName,
  'service_description': instance.serviceDescription,
  'subscribed_at': instance.subscribedAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'push_time_source': _$PushTimeSourceEnumMap[instance.pushTimeSource]!,
};

const _$PushTimeSourceEnumMap = {
  PushTimeSource.subscription: 'subscription',
  PushTimeSource.serviceDefault: 'service_default',
  PushTimeSource.none: 'none',
  PushTimeSource.$unknown: r'$unknown',
};
