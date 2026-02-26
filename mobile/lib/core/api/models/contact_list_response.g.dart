// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactListResponse _$ContactListResponseFromJson(Map<String, dynamic> json) =>
    ContactListResponse(
      contacts: (json['contacts'] as List<dynamic>)
          .map((e) => ContactResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$ContactListResponseToJson(
  ContactListResponse instance,
) => <String, dynamic>{
  'contacts': instance.contacts,
  'total': instance.total,
  'page': instance.page,
  'page_size': instance.pageSize,
};
