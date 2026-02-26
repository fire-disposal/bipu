// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_account_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccountList _$ServiceAccountListFromJson(Map<String, dynamic> json) =>
    ServiceAccountList(
      items: (json['items'] as List<dynamic>)
          .map(
            (e) => ServiceAccountResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$ServiceAccountListToJson(ServiceAccountList instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
    };
