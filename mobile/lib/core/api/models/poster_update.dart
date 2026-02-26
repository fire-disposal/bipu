// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'poster_update.g.dart';

/// 更新海报请求
@JsonSerializable()
class PosterUpdate {
  const PosterUpdate({
    this.title,
    this.linkUrl,
    this.displayOrder,
    this.isActive,
  });
  
  factory PosterUpdate.fromJson(Map<String, Object?> json) => _$PosterUpdateFromJson(json);
  
  /// 海报标题
  final String? title;

  /// 点击跳转链接
  @JsonKey(name: 'link_url')
  final String? linkUrl;

  /// 显示顺序
  @JsonKey(name: 'display_order')
  final int? displayOrder;

  /// 是否激活
  @JsonKey(name: 'is_active')
  final bool? isActive;

  Map<String, Object?> toJson() => _$PosterUpdateToJson(this);
}
