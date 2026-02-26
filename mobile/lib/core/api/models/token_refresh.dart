// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'token_refresh.g.dart';

/// 刷新令牌请求
@JsonSerializable()
class TokenRefresh {
  const TokenRefresh({
    required this.refreshToken,
  });
  
  factory TokenRefresh.fromJson(Map<String, Object?> json) => _$TokenRefreshFromJson(json);
  
  /// 刷新令牌
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  Map<String, Object?> toJson() => _$TokenRefreshToJson(this);
}
