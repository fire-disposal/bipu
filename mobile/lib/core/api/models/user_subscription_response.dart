// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'service_account_response.dart';
import 'subscription_settings_response.dart';

part 'user_subscription_response.g.dart';

/// 用户订阅详情响应
@JsonSerializable()
class UserSubscriptionResponse {
  const UserSubscriptionResponse({
    required this.service,
    required this.settings,
  });
  
  factory UserSubscriptionResponse.fromJson(Map<String, Object?> json) => _$UserSubscriptionResponseFromJson(json);
  
  final ServiceAccountResponse service;
  final SubscriptionSettingsResponse settings;

  Map<String, Object?> toJson() => _$UserSubscriptionResponseToJson(this);
}
