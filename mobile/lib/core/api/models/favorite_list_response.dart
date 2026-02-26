// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'favorite_response.dart';

part 'favorite_list_response.g.dart';

/// 收藏列表响应
@JsonSerializable()
class FavoriteListResponse {
  const FavoriteListResponse({
    required this.favorites,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  });
  
  factory FavoriteListResponse.fromJson(Map<String, Object?> json) => _$FavoriteListResponseFromJson(json);
  
  final List<FavoriteResponse> favorites;
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$FavoriteListResponseToJson(this);
}
