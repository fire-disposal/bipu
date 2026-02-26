// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'favorite_create.g.dart';

/// 创建收藏请求
@JsonSerializable()
class FavoriteCreate {
  const FavoriteCreate({
    this.note,
  });
  
  factory FavoriteCreate.fromJson(Map<String, Object?> json) => _$FavoriteCreateFromJson(json);
  
  /// 备注
  final String? note;

  Map<String, Object?> toJson() => _$FavoriteCreateToJson(this);
}
