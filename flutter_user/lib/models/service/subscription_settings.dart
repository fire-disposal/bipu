import 'package:json_annotation/json_annotation.dart';

part 'subscription_settings.g.dart';

/// 订阅设置响应模型
@JsonSerializable()
class SubscriptionSettings {
  /// 推送时间
  @JsonKey(name: 'push_time')
  final String? pushTime;

  /// 是否启用
  @JsonKey(name: 'is_enabled', defaultValue: true)
  final bool isEnabled;

  /// 推送频率
  @JsonKey(name: 'push_frequency')
  final String? pushFrequency;

  /// 最后推送时间
  @JsonKey(name: 'last_push_at')
  final DateTime? lastPushAt;

  /// 创建时间
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 更新时间
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  SubscriptionSettings({
    this.pushTime,
    this.isEnabled = true,
    this.pushFrequency,
    this.lastPushAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionSettings.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionSettingsToJson(this);
}
