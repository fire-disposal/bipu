// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'live_response.g.dart';

/// 存活检查响应
@JsonSerializable()
class LiveResponse {
  const LiveResponse({
    required this.status,
    required this.timestamp,
  });
  
  factory LiveResponse.fromJson(Map<String, Object?> json) => _$LiveResponseFromJson(json);
  
  /// 存活状态
  final String status;

  /// 检查时间
  final String timestamp;

  Map<String, Object?> toJson() => _$LiveResponseToJson(this);
}
