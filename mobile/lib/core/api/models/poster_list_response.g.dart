// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosterListResponse _$PosterListResponseFromJson(Map<String, dynamic> json) =>
    PosterListResponse(
      posters: (json['posters'] as List<dynamic>)
          .map((e) => PosterResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$PosterListResponseToJson(PosterListResponse instance) =>
    <String, dynamic>{
      'posters': instance.posters,
      'total': instance.total,
      'page': instance.page,
      'page_size': instance.pageSize,
    };
