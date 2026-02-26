// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'timezone_update.g.dart';

/// 更新时区请求
@JsonSerializable()
class TimezoneUpdate {
  const TimezoneUpdate({
    required this.timezone,
  });
  
  factory TimezoneUpdate.fromJson(Map<String, Object?> json) => _$TimezoneUpdateFromJson(json);
  
  /// 时区标识符，如 Asia/Shanghai
  final String timezone;

  Map<String, Object?> toJson() => _$TimezoneUpdateToJson(this);
}
