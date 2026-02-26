// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'subscription_settings_update.g.dart';

/// 更新订阅设置请求
@JsonSerializable()
class SubscriptionSettingsUpdate {
  const SubscriptionSettingsUpdate({
    this.isEnabled = true,
    this.pushTime,
  });
  
  factory SubscriptionSettingsUpdate.fromJson(Map<String, Object?> json) => _$SubscriptionSettingsUpdateFromJson(json);
  
  /// 推送时间，格式: HH:MM
  @JsonKey(name: 'push_time')
  final String? pushTime;

  /// 是否启用推送
  @JsonKey(name: 'is_enabled')
  final bool? isEnabled;

  Map<String, Object?> toJson() => _$SubscriptionSettingsUpdateToJson(this);
}
