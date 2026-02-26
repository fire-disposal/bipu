import 'package:json_annotation/json_annotation.dart';

part 'poster_response.g.dart';

/// 海报响应模型
@JsonSerializable()
class PosterResponse {
  /// 海报ID
  final int id;

  /// 标题
  final String title;

  /// 链接URL
  @JsonKey(name: 'link_url')
  final String? linkUrl;

  /// 显示顺序
  @JsonKey(name: 'display_order', defaultValue: 0)
  final int displayOrder;

  /// 是否活跃
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;

  /// 创建时间
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 更新时间
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// 图片URL
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  PosterResponse({
    required this.id,
    required this.title,
    this.linkUrl,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  factory PosterResponse.fromJson(Map<String, dynamic> json) =>
      _$PosterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PosterResponseToJson(this);
}
