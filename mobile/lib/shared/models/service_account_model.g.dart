// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccountResponse _$ServiceAccountResponseFromJson(
  Map<String, dynamic> json,
) => ServiceAccountResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  avatarVersion: (json['avatar_version'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? true,
  defaultPushTime: json['default_push_time'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ServiceAccountResponseToJson(
  ServiceAccountResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'avatar_url': instance.avatarUrl,
  'avatar_version': instance.avatarVersion,
  'is_active': instance.isActive,
  'default_push_time': instance.defaultPushTime,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

SubscriptionSettingsBase _$SubscriptionSettingsBaseFromJson(
  Map<String, dynamic> json,
) => SubscriptionSettingsBase(
  pushTime: json['push_time'] as String?,
  isEnabled: json['is_enabled'] as bool? ?? true,
);

Map<String, dynamic> _$SubscriptionSettingsBaseToJson(
  SubscriptionSettingsBase instance,
) => <String, dynamic>{
  'push_time': instance.pushTime,
  'is_enabled': instance.isEnabled,
};

SubscriptionSettingsUpdate _$SubscriptionSettingsUpdateFromJson(
  Map<String, dynamic> json,
) => SubscriptionSettingsUpdate(
  pushTime: json['push_time'] as String?,
  isEnabled: json['is_enabled'] as bool?,
);

Map<String, dynamic> _$SubscriptionSettingsUpdateToJson(
  SubscriptionSettingsUpdate instance,
) => <String, dynamic>{
  'push_time': instance.pushTime,
  'is_enabled': instance.isEnabled,
};

SubscriptionSettingsResponse _$SubscriptionSettingsResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionSettingsResponse(
  serviceName: json['service_name'] as String,
  serviceDescription: json['service_description'] as String?,
  pushTime: json['push_time'] as String?,
  isEnabled: json['is_enabled'] as bool? ?? true,
  subscribedAt: DateTime.parse(json['subscribed_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  pushTimeSource: json['push_time_source'] as String?,
);

Map<String, dynamic> _$SubscriptionSettingsResponseToJson(
  SubscriptionSettingsResponse instance,
) => <String, dynamic>{
  'service_name': instance.serviceName,
  'service_description': instance.serviceDescription,
  'push_time': instance.pushTime,
  'is_enabled': instance.isEnabled,
  'subscribed_at': instance.subscribedAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'push_time_source': instance.pushTimeSource,
};

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

UserSubscriptionList _$UserSubscriptionListFromJson(
  Map<String, dynamic> json,
) => UserSubscriptionList(
  subscriptions: (json['subscriptions'] as List<dynamic>)
      .map((e) => UserSubscriptionResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$UserSubscriptionListToJson(
  UserSubscriptionList instance,
) => <String, dynamic>{
  'subscriptions': instance.subscriptions,
  'total': instance.total,
};

ServiceAccountList _$ServiceAccountListFromJson(Map<String, dynamic> json) =>
    ServiceAccountList(
      items: (json['items'] as List<dynamic>)
          .map(
            (e) => ServiceAccountResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceAccountListToJson(ServiceAccountList instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};

ServiceAccountModel _$ServiceAccountModelFromJson(Map<String, dynamic> json) =>
    ServiceAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      pushTime: json['pushTime'] as String?,
      pushTimeSource:
          $enumDecodeNullable(
            _$PushTimeSourceEnumMap,
            json['pushTimeSource'],
          ) ??
          PushTimeSource.none,
      subscribedAt: json['subscribedAt'] == null
          ? null
          : DateTime.parse(json['subscribedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ServiceAccountModelToJson(
  ServiceAccountModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'displayName': instance.displayName,
  'description': instance.description,
  'avatarUrl': instance.avatarUrl,
  'isSubscribed': instance.isSubscribed,
  'isEnabled': instance.isEnabled,
  'pushTime': instance.pushTime,
  'pushTimeSource': _$PushTimeSourceEnumMap[instance.pushTimeSource]!,
  'subscribedAt': instance.subscribedAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$PushTimeSourceEnumMap = {
  PushTimeSource.subscription: 'subscription',
  PushTimeSource.serviceDefault: 'service_default',
  PushTimeSource.none: 'none',
};
