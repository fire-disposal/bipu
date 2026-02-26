// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_subscription_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSubscriptionList _$UserSubscriptionListFromJson(
  Map<String, dynamic> json,
) => UserSubscriptionList(
  subscriptions: (json['subscriptions'] as List<dynamic>)
      .map((e) => UserSubscriptionResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num?)?.toInt() ?? 1,
  pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
);

Map<String, dynamic> _$UserSubscriptionListToJson(
  UserSubscriptionList instance,
) => <String, dynamic>{
  'subscriptions': instance.subscriptions,
  'total': instance.total,
  'page': instance.page,
  'page_size': instance.pageSize,
};
