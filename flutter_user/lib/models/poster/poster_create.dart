import 'package:json_annotation/json_annotation.dart';

part 'poster_create.g.dart';

/// 创建海报请求模型
@JsonSerializable()
class PosterCreate {
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

  PosterCreate({
    required this.title,
    this.linkUrl,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory PosterCreate.fromJson(Map<String, dynamic> json) =>
      _$PosterCreateFromJson(json);

  Map<String, dynamic> toJson() => _$PosterCreateToJson(this);
}
