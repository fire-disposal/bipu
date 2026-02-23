import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'service_account_model.g.dart';

/// 服务号基础信息（匹配后端 ServiceAccountResponse）
@JsonSerializable()
class ServiceAccountResponse {
  /// 服务号ID
  final int id;

  /// 服务号名称（全局唯一，如 cosmic.fortune）
  final String name;

  /// 服务号描述
  final String? description;

  /// 头像URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 头像版本号，用于缓存失效
  @JsonKey(name: 'avatar_version')
  final int avatarVersion;

  /// 是否活跃
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// 默认推送时间
  @JsonKey(name: 'default_push_time')
  final String? defaultPushTime;

  /// 创建时间
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 更新时间
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  ServiceAccountResponse({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.avatarVersion = 0,
    this.isActive = true,
    this.defaultPushTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceAccountResponse.fromJson(Map<String, dynamic> json) =>
      _$ServiceAccountResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceAccountResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAccountResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          avatarUrl == other.avatarUrl &&
          avatarVersion == other.avatarVersion &&
          isActive == other.isActive &&
          defaultPushTime == other.defaultPushTime &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      avatarUrl.hashCode ^
      avatarVersion.hashCode ^
      isActive.hashCode ^
      defaultPushTime.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'ServiceAccountResponse(id: $id, name: $name, description: $description, avatarUrl: $avatarUrl, avatarVersion: $avatarVersion, isActive: $isActive, defaultPushTime: $defaultPushTime, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// 订阅设置基础模型（匹配后端 SubscriptionSettingsBase）
@JsonSerializable()
class SubscriptionSettingsBase {
  /// 推送时间，格式: HH:MM
  @JsonKey(name: 'push_time')
  final String? pushTime;

  /// 是否启用推送
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;

  SubscriptionSettingsBase({this.pushTime, this.isEnabled = true});

  factory SubscriptionSettingsBase.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsBaseFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionSettingsBaseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsBase &&
          runtimeType == other.runtimeType &&
          pushTime == other.pushTime &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => pushTime.hashCode ^ isEnabled.hashCode;

  @override
  String toString() =>
      'SubscriptionSettingsBase(pushTime: $pushTime, isEnabled: $isEnabled)';
}

/// 更新订阅设置（匹配后端 SubscriptionSettingsUpdate）
@JsonSerializable()
class SubscriptionSettingsUpdate {
  /// 推送时间，格式: HH:MM，设置为空字符串可清除个人化设置
  @JsonKey(name: 'push_time')
  final String? pushTime;

  /// 是否启用推送
  @JsonKey(name: 'is_enabled')
  final bool? isEnabled;

  SubscriptionSettingsUpdate({this.pushTime, this.isEnabled});

  factory SubscriptionSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionSettingsUpdateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsUpdate &&
          runtimeType == other.runtimeType &&
          pushTime == other.pushTime &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => pushTime.hashCode ^ isEnabled.hashCode;

  @override
  String toString() =>
      'SubscriptionSettingsUpdate(pushTime: $pushTime, isEnabled: $isEnabled)';
}

/// 订阅设置响应（匹配后端 SubscriptionSettingsResponse）
@JsonSerializable()
class SubscriptionSettingsResponse {
  @JsonKey(name: 'service_name')
  final String serviceName;
  @JsonKey(name: 'service_description')
  final String? serviceDescription;
  @JsonKey(name: 'push_time')
  final String? pushTime;
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;
  @JsonKey(name: 'subscribed_at')
  final DateTime subscribedAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'push_time_source')
  final String? pushTimeSource;

  SubscriptionSettingsResponse({
    required this.serviceName,
    this.serviceDescription,
    this.pushTime,
    this.isEnabled = true,
    required this.subscribedAt,
    this.updatedAt,
    this.pushTimeSource,
  });

  factory SubscriptionSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSettingsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionSettingsResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettingsResponse &&
          runtimeType == other.runtimeType &&
          serviceName == other.serviceName &&
          serviceDescription == other.serviceDescription &&
          pushTime == other.pushTime &&
          isEnabled == other.isEnabled &&
          subscribedAt == other.subscribedAt &&
          updatedAt == other.updatedAt &&
          pushTimeSource == other.pushTimeSource;

  @override
  int get hashCode =>
      serviceName.hashCode ^
      serviceDescription.hashCode ^
      pushTime.hashCode ^
      isEnabled.hashCode ^
      subscribedAt.hashCode ^
      updatedAt.hashCode ^
      pushTimeSource.hashCode;

  @override
  String toString() {
    return 'SubscriptionSettingsResponse(serviceName: $serviceName, serviceDescription: $serviceDescription, pushTime: $pushTime, isEnabled: $isEnabled, subscribedAt: $subscribedAt, updatedAt: $updatedAt, pushTimeSource: $pushTimeSource)';
  }
}

/// 用户订阅详情响应（匹配后端 UserSubscriptionResponse）
@JsonSerializable()
class UserSubscriptionResponse {
  final ServiceAccountResponse service;
  final SubscriptionSettingsResponse settings;

  UserSubscriptionResponse({required this.service, required this.settings});

  factory UserSubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserSubscriptionResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscriptionResponse &&
          runtimeType == other.runtimeType &&
          service == other.service &&
          settings == other.settings;

  @override
  int get hashCode => service.hashCode ^ settings.hashCode;

  @override
  String toString() =>
      'UserSubscriptionResponse(service: $service, settings: $settings)';
}

/// 用户订阅列表响应（匹配后端 UserSubscriptionList）
@JsonSerializable()
class UserSubscriptionList {
  final List<UserSubscriptionResponse> subscriptions;
  final int total;

  UserSubscriptionList({required this.subscriptions, required this.total});

  factory UserSubscriptionList.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionListFromJson(json);
  Map<String, dynamic> toJson() => _$UserSubscriptionListToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscriptionList &&
          runtimeType == other.runtimeType &&
          subscriptions == other.subscriptions &&
          total == other.total;

  @override
  int get hashCode => subscriptions.hashCode ^ total.hashCode;

  @override
  String toString() =>
      'UserSubscriptionList(subscriptions: $subscriptions, total: $total)';
}

/// 服务号列表响应（匹配后端 ServiceAccountList）
@JsonSerializable()
class ServiceAccountList {
  final List<ServiceAccountResponse> items;
  final int total;

  ServiceAccountList({required this.items, required this.total});

  factory ServiceAccountList.fromJson(Map<String, dynamic> json) =>
      _$ServiceAccountListFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceAccountListToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAccountList &&
          runtimeType == other.runtimeType &&
          items == other.items &&
          total == other.total;

  @override
  int get hashCode => items.hashCode ^ total.hashCode;

  @override
  String toString() => 'ServiceAccountList(items: $items, total: $total)';
}

/// 推送时间来源枚举
@JsonEnum(alwaysCreate: true) // 显式声明
enum PushTimeSource {
  @JsonValue('subscription')
  subscription,
  @JsonValue('service_default')
  serviceDefault,
  @JsonValue('none')
  none,
}

/// 本地使用的服务号模型（包含订阅状态）
@JsonSerializable()
class ServiceAccountModel {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String? avatarUrl;
  final bool isSubscribed;
  final bool isEnabled;
  final String? pushTime;
  final PushTimeSource pushTimeSource;
  final DateTime? subscribedAt;
  final DateTime? updatedAt;

  ServiceAccountModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    this.avatarUrl,
    this.isSubscribed = false,
    this.isEnabled = true,
    this.pushTime,
    this.pushTimeSource = PushTimeSource.none,
    this.subscribedAt,
    this.updatedAt,
  });

  factory ServiceAccountModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceAccountModelFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceAccountModelToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAccountModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          displayName == other.displayName &&
          description == other.description &&
          avatarUrl == other.avatarUrl &&
          isSubscribed == other.isSubscribed &&
          isEnabled == other.isEnabled &&
          pushTime == other.pushTime &&
          pushTimeSource == other.pushTimeSource &&
          subscribedAt == other.subscribedAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      displayName.hashCode ^
      description.hashCode ^
      avatarUrl.hashCode ^
      isSubscribed.hashCode ^
      isEnabled.hashCode ^
      pushTime.hashCode ^
      pushTimeSource.hashCode ^
      subscribedAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'ServiceAccountModel(id: $id, name: $name, displayName: $displayName, description: $description, avatarUrl: $avatarUrl, isSubscribed: $isSubscribed, isEnabled: $isEnabled, pushTime: $pushTime, pushTimeSource: $pushTimeSource, subscribedAt: $subscribedAt, updatedAt: $updatedAt)';
  }
}

/// 时间解析和格式化工具
class TimeUtils {
  static bool isValidTimeFormat(String time) {
    return RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(time);
  }

  static TimeOfDay? parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
