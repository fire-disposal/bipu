// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'push_time_source.dart';

part 'subscription_settings_response.g.dart';

/// 订阅设置响应
@JsonSerializable()
class SubscriptionSettingsResponse {
  const SubscriptionSettingsResponse({
    required this.serviceName,
    required this.subscribedAt,
    this.isEnabled = true,
    this.pushTimeSource = PushTimeSource.none,
    this.pushTime,
    this.serviceDescription,
    this.updatedAt,
  });
  
  factory SubscriptionSettingsResponse.fromJson(Map<String, Object?> json) => _$SubscriptionSettingsResponseFromJson(json);
  
  /// 推送时间，格式: HH:MM
  @JsonKey(name: 'push_time')
  final String? pushTime;

  /// 是否启用推送
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;

  /// 服务号名称
  @JsonKey(name: 'service_name')
  final String serviceName;

  /// 服务号描述
  @JsonKey(name: 'service_description')
  final String? serviceDescription;

  /// 订阅时间
  @JsonKey(name: 'subscribed_at')
  final DateTime subscribedAt;

  /// 最后更新时间
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// 推送时间来源
  @JsonKey(name: 'push_time_source')
  final PushTimeSource pushTimeSource;

  Map<String, Object?> toJson() => _$SubscriptionSettingsResponseToJson(this);
}
