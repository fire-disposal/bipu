// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'token.g.dart';

/// 认证令牌响应
@JsonSerializable()
class Token {
  const Token({
    required this.accessToken,
    required this.expiresIn,
    this.tokenType = 'bearer',
    this.refreshToken,
  });
  
  factory Token.fromJson(Map<String, Object?> json) => _$TokenFromJson(json);
  
  /// 访问令牌
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// 刷新令牌
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  /// 令牌类型
  @JsonKey(name: 'token_type')
  final String tokenType;

  /// 过期时间（秒）
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  Map<String, Object?> toJson() => _$TokenToJson(this);
}
