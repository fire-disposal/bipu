// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'poster_response.g.dart';

/// 海报响应
@JsonSerializable()
class PosterResponse {
  const PosterResponse({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.displayOrder = 0,
    this.isActive = true,
    this.linkUrl,
    this.imageUrl,
  });
  
  factory PosterResponse.fromJson(Map<String, Object?> json) => _$PosterResponseFromJson(json);
  
  final int id;

  /// 海报标题
  final String title;

  /// 点击跳转链接
  @JsonKey(name: 'link_url')
  final String? linkUrl;

  /// 海报图片URL
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// 显示顺序
  @JsonKey(name: 'display_order')
  final int displayOrder;

  /// 是否激活
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$PosterResponseToJson(this);
}
