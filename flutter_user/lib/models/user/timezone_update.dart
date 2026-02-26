import 'package:json_annotation/json_annotation.dart';

part 'timezone_update.g.dart';

/// 时区更新请求模型
@JsonSerializable()
class TimezoneUpdate {
  /// 时区
  final String timezone;

  TimezoneUpdate({required this.timezone});

  factory TimezoneUpdate.fromJson(Map<String, dynamic> json) =>
      _$TimezoneUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$TimezoneUpdateToJson(this);
}
