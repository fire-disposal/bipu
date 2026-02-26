// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'block_user_request.g.dart';

/// 拉黑用户请求
@JsonSerializable()
class BlockUserRequest {
  const BlockUserRequest({
    required this.bipupuId,
  });
  
  factory BlockUserRequest.fromJson(Map<String, Object?> json) => _$BlockUserRequestFromJson(json);
  
  /// 要拉黑的用户ID
  @JsonKey(name: 'bipupu_id')
  final String bipupuId;

  Map<String, Object?> toJson() => _$BlockUserRequestToJson(this);
}
