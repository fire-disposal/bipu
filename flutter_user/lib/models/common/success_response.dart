import 'package:json_annotation/json_annotation.dart';

part 'success_response.g.dart';

/// 成功响应模型
@JsonSerializable()
class SuccessResponse {
  /// 是否成功
  final bool success;

  /// 消息
  final String message;

  SuccessResponse({required this.success, required this.message});

  factory SuccessResponse.fromJson(Map<String, dynamic> json) =>
      _$SuccessResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SuccessResponseToJson(this);
}
