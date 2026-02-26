// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'service_account_response.g.dart';

/// 服务号响应
@JsonSerializable()
class ServiceAccountResponse {
  const ServiceAccountResponse({
    required this.name,
    required this.id,
    required this.createdAt,
    this.isActive = true,
    this.description,
    this.avatarUrl,
    this.updatedAt,
  });
  
  factory ServiceAccountResponse.fromJson(Map<String, Object?> json) => _$ServiceAccountResponseFromJson(json);
  
  /// 服务号名称
  final String name;

  /// 服务号描述
  final String? description;

  /// 头像URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 是否激活
  @JsonKey(name: 'is_active')
  final bool isActive;
  final int id;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$ServiceAccountResponseToJson(this);
}
