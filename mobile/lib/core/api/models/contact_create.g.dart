// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactCreate _$ContactCreateFromJson(Map<String, dynamic> json) =>
    ContactCreate(
      contactId: json['contact_id'] as String,
      alias: json['alias'] as String?,
    );

Map<String, dynamic> _$ContactCreateToJson(ContactCreate instance) =>
    <String, dynamic>{
      'contact_id': instance.contactId,
      'alias': instance.alias,
    };
