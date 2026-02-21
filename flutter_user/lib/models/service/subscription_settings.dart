class SubscriptionSettings {
  /// 服务号名称
  final String serviceName;

  /// 服务号描述
  final String? serviceDescription;

  /// 推送时间 (HH:MM 格式)
  final String? pushTime;

  /// 是否启用推送
  final bool? isEnabled;

  /// 订阅时间
  final DateTime? subscribedAt;

  /// 最后更新时间
  final DateTime? updatedAt;

  const SubscriptionSettings({
    required this.serviceName,
    this.serviceDescription,
    this.pushTime,
    this.isEnabled,
    this.subscribedAt,
    this.updatedAt,
  });

  /// 从 JSON 创建 SubscriptionSettings
  factory SubscriptionSettings.fromJson(Map<String, dynamic> json) {
    return SubscriptionSettings(
      serviceName: json['service_name'] as String,
      serviceDescription: json['service_description'] as String?,
      pushTime: json['push_time'] as String?,
      isEnabled: json['is_enabled'] as bool?,
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.parse(json['subscribed_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 从 ServiceAccount JSON 创建 SubscriptionSettings
  factory SubscriptionSettings.fromServiceAccountJson(
    Map<String, dynamic> json,
  ) {
    return SubscriptionSettings(
      serviceName: json['name'] as String,
      serviceDescription: json['description'] as String?,
      pushTime: json['push_time'] as String?,
      isEnabled: json['is_enabled'] as bool?,
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.parse(json['subscribed_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      if (serviceDescription != null) 'service_description': serviceDescription,
      if (pushTime != null) 'push_time': pushTime,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (subscribedAt != null)
        'subscribed_at': subscribedAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 转换为更新API请求的JSON格式
  Map<String, dynamic> toUpdateJson() {
    return {
      if (pushTime != null) 'push_time': pushTime,
      if (isEnabled != null) 'is_enabled': isEnabled,
    };
  }

  /// 创建副本并更新字段
  SubscriptionSettings copyWith({
    String? serviceName,
    String? serviceDescription,
    String? pushTime,
    bool? isEnabled,
    DateTime? subscribedAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionSettings(
      serviceName: serviceName ?? this.serviceName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      pushTime: pushTime ?? this.pushTime,
      isEnabled: isEnabled ?? this.isEnabled,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  bool get isActive => (isEnabled ?? true) && hasPushTime;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionSettings &&
          runtimeType == other.runtimeType &&
          serviceName == other.serviceName &&
          serviceDescription == other.serviceDescription &&
          pushTime == other.pushTime &&
          isEnabled == other.isEnabled &&
          subscribedAt == other.subscribedAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      serviceName.hashCode ^
      serviceDescription.hashCode ^
      pushTime.hashCode ^
      isEnabled.hashCode ^
      subscribedAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'SubscriptionSettings(serviceName: $serviceName, serviceDescription: $serviceDescription, pushTime: $pushTime, isEnabled: $isEnabled, subscribedAt: $subscribedAt, updatedAt: $updatedAt)';
  }
}
