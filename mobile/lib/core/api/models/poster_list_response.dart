// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'poster_response.dart';

part 'poster_list_response.g.dart';

/// 海报列表响应
@JsonSerializable()
class PosterListResponse {
  const PosterListResponse({
    required this.posters,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  });
  
  factory PosterListResponse.fromJson(Map<String, Object?> json) => _$PosterListResponseFromJson(json);
  
  final List<PosterResponse> posters;
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$PosterListResponseToJson(this);
}
