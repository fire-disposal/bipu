// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_account_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccountResponse _$ServiceAccountResponseFromJson(
  Map<String, dynamic> json,
) => ServiceAccountResponse(
  name: json['name'] as String,
  id: (json['id'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  isActive: json['is_active'] as bool? ?? true,
  description: json['description'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ServiceAccountResponseToJson(
  ServiceAccountResponse instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'avatar_url': instance.avatarUrl,
  'is_active': instance.isActive,
  'id': instance.id,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
