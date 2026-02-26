// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_subscription_response.dart';

part 'user_subscription_list.g.dart';

/// 用户订阅列表响应
@JsonSerializable()
class UserSubscriptionList {
  const UserSubscriptionList({
    required this.subscriptions,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  });
  
  factory UserSubscriptionList.fromJson(Map<String, Object?> json) => _$UserSubscriptionListFromJson(json);
  
  final List<UserSubscriptionResponse> subscriptions;
  final int total;

  /// 当前页码
  final int page;

  /// 每页数量
  @JsonKey(name: 'page_size')
  final int pageSize;

  Map<String, Object?> toJson() => _$UserSubscriptionListToJson(this);
}
