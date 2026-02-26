// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'success_response.g.dart';

/// 成功响应
@JsonSerializable()
class SuccessResponse {
  const SuccessResponse({
    required this.message,
    this.data,
    this.success = true,
  });
  
  factory SuccessResponse.fromJson(Map<String, Object?> json) => _$SuccessResponseFromJson(json);
  
  /// 是否成功
  final bool success;

  /// 成功消息
  final String message;

  /// 响应数据
  final dynamic data;

  Map<String, Object?> toJson() => _$SuccessResponseToJson(this);
}
