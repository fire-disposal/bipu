// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactResponse _$ContactResponseFromJson(Map<String, dynamic> json) =>
    ContactResponse(
      id: (json['id'] as num).toInt(),
      contactId: json['contact_id'] as String,
      contactUsername: json['contact_username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      contactNickname: json['contact_nickname'] as String?,
      alias: json['alias'] as String?,
    );

Map<String, dynamic> _$ContactResponseToJson(ContactResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contact_id': instance.contactId,
      'contact_username': instance.contactUsername,
      'contact_nickname': instance.contactNickname,
      'alias': instance.alias,
      'created_at': instance.createdAt.toIso8601String(),
    };
