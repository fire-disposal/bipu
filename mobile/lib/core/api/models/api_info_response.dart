// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'api_info_response.g.dart';

/// API信息响应
@JsonSerializable()
class ApiInfoResponse {
  const ApiInfoResponse({
    required this.message,
    required this.version,
    required this.project,
    required this.docsUrl,
    required this.redocUrl,
    required this.adminUrl,
  });
  
  factory ApiInfoResponse.fromJson(Map<String, Object?> json) => _$ApiInfoResponseFromJson(json);
  
  /// 欢迎消息
  final String message;

  /// API版本
  final String version;

  /// 项目名称
  final String project;

  /// 文档URL
  @JsonKey(name: 'docs_url')
  final String docsUrl;

  /// Redoc文档URL
  @JsonKey(name: 'redoc_url')
  final String redocUrl;

  /// 管理后台URL
  @JsonKey(name: 'admin_url')
  final String adminUrl;

  Map<String, Object?> toJson() => _$ApiInfoResponseToJson(this);
}
