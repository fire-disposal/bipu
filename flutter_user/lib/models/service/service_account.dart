import 'subscription_settings.dart';

class ServiceAccount {
  final int id;
  final String name; // unique id string e.g. 'weather.service'
  final String? displayName;
  final String? description;
  final String? avatarUrl;
  final bool isActive;
  final String? defaultPushTime; // 服务号默认推送时间 (HH:MM)
  final String? pushTime; // 用户设置的推送时间 (HH:MM)
  final bool? isEnabled; // 是否启用推送
  final DateTime? subscribedAt; // 订阅时间
  final DateTime? updatedAt; // 最后更新时间

  ServiceAccount({
    required this.id,
    required this.name,
    this.displayName,
    this.description,
    this.avatarUrl,
    required this.isActive,
    this.defaultPushTime,
    this.pushTime,
    this.isEnabled,
    this.subscribedAt,
    this.updatedAt,
  });

  factory ServiceAccount.fromJson(Map<String, dynamic> json) {
    // 处理订阅设置相关的字段
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return ServiceAccount(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'],
      description: json['description'],
      avatarUrl:
          json['avatar_url'] ??
          json['avatarUrl'], // Handle snake_case or camelCase
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      defaultPushTime: json['default_push_time'] ?? json['defaultPushTime'],
      pushTime: json['push_time'] ?? json['pushTime'],
      isEnabled: json['is_enabled'] ?? json['isEnabled'],
      subscribedAt: parseDateTime(
        json['subscribed_at'] ?? json['subscribedAt'],
      ),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// 检查是否有有效的推送时间设置
  bool get hasPushTime => pushTime != null && pushTime!.isNotEmpty;

  /// 获取推送时间的TimeOfDay对象
  /// 返回null如果推送时间无效
  (int hour, int minute)? get pushTimeComponents {
    if (!hasPushTime) return null;

    try {
      final parts = pushTime!.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return (hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// 格式化显示推送时间
  String get formattedPushTime {
    if (!hasPushTime) return '未设置';

    final components = pushTimeComponents;
    if (components == null) return '格式错误';

    final (hour, minute) = components;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 检查订阅是否活跃
  bool get isSubscriptionActive => (isEnabled ?? true) && hasPushTime;

  /// 获取订阅时长（如果已订阅）
  Duration? get subscriptionDuration {
    if (subscribedAt == null) return null;
    return DateTime.now().difference(subscribedAt!);
  }

  /// 格式化订阅时长
  String get formattedSubscriptionDuration {
    final duration = subscriptionDuration;
    if (duration == null) return '未知';

    if (duration.inDays > 365) {
      final years = (duration.inDays / 365).floor();
      return '$years年';
    } else if (duration.inDays > 30) {
      final months = (duration.inDays / 30).floor();
      return '$months个月';
    } else if (duration.inDays > 0) {
      return '${duration.inDays}天';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时';
    } else {
      return '${duration.inMinutes}分钟';
    }
  }

  /// 转换为订阅设置对象
  SubscriptionSettings toSubscriptionSettings() {
    return SubscriptionSettings(
      serviceName: name,
      serviceDescription: description,
      pushTime: pushTime,
      isEnabled: isEnabled,
      subscribedAt: subscribedAt,
      updatedAt: updatedAt,
    );
  }
}
