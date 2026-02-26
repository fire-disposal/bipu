import 'package:json_annotation/json_annotation.dart';

part 'block_user_request.g.dart';

/// 屏蔽用户请求模型
@JsonSerializable()
class BlockUserRequest {
  /// 用户ID
  @JsonKey(name: 'bipupu_id')
  final String bipupuId;

  BlockUserRequest({required this.bipupuId});

  factory BlockUserRequest.fromJson(Map<String, dynamic> json) =>
      _$BlockUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BlockUserRequestToJson(this);
}
