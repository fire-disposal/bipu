// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosterUpdate _$PosterUpdateFromJson(Map<String, dynamic> json) => PosterUpdate(
  title: json['title'] as String?,
  linkUrl: json['link_url'] as String?,
  displayOrder: (json['display_order'] as num?)?.toInt(),
  isActive: json['is_active'] as bool?,
);

Map<String, dynamic> _$PosterUpdateToJson(PosterUpdate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'link_url': instance.linkUrl,
      'display_order': instance.displayOrder,
      'is_active': instance.isActive,
    };
