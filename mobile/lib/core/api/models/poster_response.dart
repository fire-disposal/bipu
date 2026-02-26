// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'poster_response.g.dart';

/// 海报响应 - 用于前端轮播展示.
///
/// 字段说明：.
/// - id: 海报唯一标识.
/// - title: 海报标题.
/// - link_url: 点击跳转链接（可选）.
/// - image_url: 海报图片URL（由业务层构建）.
/// - display_order: 显示顺序（数字越小越靠前）.
/// - is_active: 是否激活（业务层已过滤）.
/// - created_at: 创建时间.
/// - updated_at: 更新时间.
///
/// 注意：.
/// - 前端轮播接口只返回 is_active=True 的海报.
/// - image_url 由业务层在构建响应时动态生成.
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

  /// 显示顺序，数字越小越靠前
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
