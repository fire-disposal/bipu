// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ready_response.g.dart';

/// 就绪检查响应
@JsonSerializable()
class ReadyResponse {
  const ReadyResponse({
    required this.status,
    required this.timestamp,
  });
  
  factory ReadyResponse.fromJson(Map<String, Object?> json) => _$ReadyResponseFromJson(json);
  
  /// 就绪状态
  final String status;

  /// 检查时间
  final String timestamp;

  Map<String, Object?> toJson() => _$ReadyResponseToJson(this);
}
