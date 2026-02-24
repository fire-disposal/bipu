// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosterResponse _$PosterResponseFromJson(Map<String, dynamic> json) =>
    PosterResponse(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      linkUrl: json['link_url'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PosterResponseToJson(PosterResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'link_url': instance.linkUrl,
      'display_order': instance.displayOrder,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

PosterListResponse _$PosterListResponseFromJson(Map<String, dynamic> json) =>
    PosterListResponse(
      posters: (json['posters'] as List<dynamic>)
          .map((e) => PosterResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
    );

Map<String, dynamic> _$PosterListResponseToJson(PosterListResponse instance) =>
    <String, dynamic>{
      'posters': instance.posters,
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
    };

PosterImageResponse _$PosterImageResponseFromJson(Map<String, dynamic> json) =>
    PosterImageResponse(
      posterId: (json['poster_id'] as num).toInt(),
      title: json['title'] as String,
      imageData: json['image_data'] as String,
      mimeType: json['mime_type'] as String,
    );

Map<String, dynamic> _$PosterImageResponseToJson(
  PosterImageResponse instance,
) => <String, dynamic>{
  'poster_id': instance.posterId,
  'title': instance.title,
  'image_data': instance.imageData,
  'mime_type': instance.mimeType,
};
