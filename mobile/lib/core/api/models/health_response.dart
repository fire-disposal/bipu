// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'health_response.g.dart';

/// 健康检查响应
@JsonSerializable()
class HealthResponse {
  const HealthResponse({
    required this.status,
    required this.service,
    required this.timestamp,
  });
  
  factory HealthResponse.fromJson(Map<String, Object?> json) => _$HealthResponseFromJson(json);
  
  /// 服务状态
  final String status;

  /// 服务名称
  final String service;

  /// 检查时间
  final String timestamp;

  Map<String, Object?> toJson() => _$HealthResponseToJson(this);
}
