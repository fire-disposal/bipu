import 'package:json_annotation/json_annotation.dart';

part 'poster_update.g.dart';

/// 更新海报请求模型
@JsonSerializable()
class PosterUpdate {
  /// 标题
  final String? title;

  /// 链接URL
  @JsonKey(name: 'link_url')
  final String? linkUrl;

  /// 显示顺序
  @JsonKey(name: 'display_order')
  final int? displayOrder;

  /// 是否活跃
  @JsonKey(name: 'is_active')
  final bool? isActive;

  PosterUpdate({this.title, this.linkUrl, this.displayOrder, this.isActive});

  factory PosterUpdate.fromJson(Map<String, dynamic> json) =>
      _$PosterUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$PosterUpdateToJson(this);
}
