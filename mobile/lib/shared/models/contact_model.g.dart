// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactResponse _$ContactResponseFromJson(Map<String, dynamic> json) =>
    ContactResponse(
      id: (json['id'] as num).toInt(),
      contactBipupuId: json['contact_bipupu_id'] as String,
      contactUsername: json['contact_username'] as String,
      contactNickname: json['contact_nickname'] as String?,
      alias: json['alias'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ContactResponseToJson(ContactResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contact_bipupu_id': instance.contactBipupuId,
      'contact_username': instance.contactUsername,
      'contact_nickname': instance.contactNickname,
      'alias': instance.alias,
      'created_at': instance.createdAt.toIso8601String(),
    };

ContactCreate _$ContactCreateFromJson(Map<String, dynamic> json) =>
    ContactCreate(
      contactBipupuId: json['contact_bipupu_id'] as String,
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$ContactCreateToJson(ContactCreate instance) =>
    <String, dynamic>{
      'contact_bipupu_id': instance.contactBipupuId,
      'remark': instance.remark,
    };

ContactUpdate _$ContactUpdateFromJson(Map<String, dynamic> json) =>
    ContactUpdate(remark: json['remark'] as String?);

Map<String, dynamic> _$ContactUpdateToJson(ContactUpdate instance) =>
    <String, dynamic>{'remark': instance.remark};

ContactListResponse _$ContactListResponseFromJson(Map<String, dynamic> json) =>
    ContactListResponse(
      contacts: (json['contacts'] as List<dynamic>)
          .map((e) => ContactResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
    );

Map<String, dynamic> _$ContactListResponseToJson(
  ContactListResponse instance,
) => <String, dynamic>{
  'contacts': instance.contacts,
  'total': instance.total,
  'page': instance.page,
  'page_size': instance.pageSize,
};
