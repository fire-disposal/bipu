// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'count_response.g.dart';

/// 计数响应
@JsonSerializable()
class CountResponse {
  const CountResponse({
    required this.count,
  });
  
  factory CountResponse.fromJson(Map<String, Object?> json) => _$CountResponseFromJson(json);
  
  /// 数量
  final int count;

  Map<String, Object?> toJson() => _$CountResponseToJson(this);
}
