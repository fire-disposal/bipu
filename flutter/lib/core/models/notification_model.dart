/// 通知数据模型
/// 定义通知相关的数据结构
library;

/// 通知模型
class Notification {
  final String id;
  final String title;
  final String? content;
  final NotificationType type;
  final NotificationStatus status;
  final NotificationPriority priority;
  final String? userId;
  final String? relatedId; // 相关对象ID（如消息ID、设备ID等）
  final NotificationAction? action;
  final Map<String, dynamic>? metadata;
  final DateTime? scheduledTime;
  final DateTime? readTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Notification({
    required this.id,
    required this.title,
    this.content,
    this.type = NotificationType.info,
    this.status = NotificationStatus.unread,
    this.priority = NotificationPriority.normal,
    this.userId,
    this.relatedId,
    this.action,
    this.metadata,
    this.scheduledTime,
    this.readTime,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 创建
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.unread,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      userId: json['user_id'] as String?,
      relatedId: json['related_id'] as String?,
      action: json['action'] != null
          ? NotificationAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      readTime: json['read_time'] != null
          ? DateTime.parse(json['read_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'user_id': userId,
      'related_id': relatedId,
      'action': action?.toJson(),
      'metadata': metadata,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'read_time': readTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 复制对象
  Notification copyWith({
    String? id,
    String? title,
    String? content,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    String? userId,
    String? relatedId,
    NotificationAction? action,
    Map<String, dynamic>? metadata,
    DateTime? scheduledTime,
    DateTime? readTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      relatedId: relatedId ?? this.relatedId,
      action: action ?? this.action,
      metadata: metadata ?? this.metadata,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      readTime: readTime ?? this.readTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: $type, status: $status, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 通知类型枚举
enum NotificationType {
  info, // 信息
  warning, // 警告
  error, // 错误
  success, // 成功
  reminder, // 提醒
  system, // 系统
  message, // 消息
  device, // 设备
  security, // 安全
}

/// 通知状态枚举
enum NotificationStatus {
  unread, // 未读
  read, // 已读
  dismissed, // 已忽略
  archived, // 已归档
}

/// 通知优先级枚举
enum NotificationPriority {
  low, // 低
  normal, // 正常
  high, // 高
  urgent, // 紧急
}

/// 通知动作模型
class NotificationAction {
  final String type;
  final String label;
  final Map<String, dynamic>? data;
  final String? route;

  NotificationAction({
    required this.type,
    required this.label,
    this.data,
    this.route,
  });

  /// 从 JSON 创建
  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      type: json['type'] as String,
      label: json['label'] as String,
      data: json['data'] as Map<String, dynamic>?,
      route: json['route'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'type': type, 'label': label, 'data': data, 'route': route};
  }
}

/// 通知偏好设置模型
class NotificationPreferences {
  final String userId;
  final Map<NotificationType, bool> typePreferences;
  final Map<NotificationPriority, bool> priorityPreferences;
  final Map<String, dynamic> channelPreferences;
  final bool doNotDisturb;
  final TimeOfDay? doNotDisturbStart;
  final TimeOfDay? doNotDisturbEnd;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.userId,
    required this.typePreferences,
    required this.priorityPreferences,
    required this.channelPreferences,
    this.doNotDisturb = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
    required this.updatedAt,
  });

  /// 从 JSON 创建
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'] as String,
      typePreferences: (json['type_preferences'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          NotificationType.values.firstWhere((e) => e.name == k),
          v as bool,
        ),
      ),
      priorityPreferences:
          (json['priority_preferences'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(
              NotificationPriority.values.firstWhere((e) => e.name == k),
              v as bool,
            ),
          ),
      channelPreferences: json['channel_preferences'] as Map<String, dynamic>,
      doNotDisturb: json['do_not_disturb'] as bool? ?? false,
      doNotDisturbStart: json['do_not_disturb_start'] != null
          ? TimeOfDay.fromDateTime(
              DateTime.parse('2023-01-01 ${json['do_not_disturb_start']}:00'),
            )
          : null,
      doNotDisturbEnd: json['do_not_disturb_end'] != null
          ? TimeOfDay.fromDateTime(
              DateTime.parse('2023-01-01 ${json['do_not_disturb_end']}:00'),
            )
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type_preferences': typePreferences.map((k, v) => MapEntry(k.name, v)),
      'priority_preferences': priorityPreferences.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'channel_preferences': channelPreferences,
      'do_not_disturb': doNotDisturb,
      'do_not_disturb_start': doNotDisturbStart != null
          ? '${doNotDisturbStart!.hour.toString().padLeft(2, '0')}:${doNotDisturbStart!.minute.toString().padLeft(2, '0')}'
          : null,
      'do_not_disturb_end': doNotDisturbEnd != null
          ? '${doNotDisturbEnd!.hour.toString().padLeft(2, '0')}:${doNotDisturbEnd!.minute.toString().padLeft(2, '0')}'
          : null,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 检查是否应该发送通知
  bool shouldSendNotification(Notification notification) {
    // 检查勿扰模式
    if (doNotDisturb && _isInDoNotDisturbPeriod()) {
      return false;
    }

    // 检查类型偏好
    if (!(typePreferences[notification.type] ?? false)) {
      return false;
    }

    // 检查优先级偏好
    if (!(priorityPreferences[notification.priority] ?? false)) {
      return false;
    }

    return true;
  }

  /// 检查当前时间是否在勿扰时间段内
  bool _isInDoNotDisturbPeriod() {
    if (doNotDisturbStart == null || doNotDisturbEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = doNotDisturbStart!;
    final end = doNotDisturbEnd!;

    if (start.hour < end.hour ||
        (start.hour == end.hour && start.minute <= end.minute)) {
      // 同一天内
      return now.hour > start.hour ||
          (now.hour == start.hour && now.minute >= start.minute) ||
          now.hour < end.hour ||
          (now.hour == end.hour && now.minute <= end.minute);
    } else {
      // 跨天
      return now.hour > start.hour ||
          (now.hour == start.hour && now.minute >= start.minute) ||
          now.hour < end.hour ||
          (now.hour == end.hour && now.minute <= end.minute);
    }
  }
}

/// 通知统计模型
class NotificationStats {
  final String userId;
  final int totalCount;
  final int unreadCount;
  final Map<NotificationType, int> typeStats;
  final Map<NotificationPriority, int> priorityStats;
  final DateTime lastCalculated;

  NotificationStats({
    required this.userId,
    required this.totalCount,
    required this.unreadCount,
    required this.typeStats,
    required this.priorityStats,
    required this.lastCalculated,
  });

  /// 从 JSON 创建
  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      userId: json['user_id'] as String,
      totalCount: json['total_count'] as int,
      unreadCount: json['unread_count'] as int,
      typeStats: (json['type_stats'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          NotificationType.values.firstWhere((e) => e.name == k),
          v as int,
        ),
      ),
      priorityStats: (json['priority_stats'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          NotificationPriority.values.firstWhere((e) => e.name == k),
          v as int,
        ),
      ),
      lastCalculated: DateTime.parse(json['last_calculated'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_count': totalCount,
      'unread_count': unreadCount,
      'type_stats': typeStats.map((k, v) => MapEntry(k.name, v)),
      'priority_stats': priorityStats.map((k, v) => MapEntry(k.name, v)),
      'last_calculated': lastCalculated.toIso8601String(),
    };
  }
}

/// 时间模型（用于通知偏好设置）
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  /// 从 DateTime 创建
  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  /// 获取当前时间
  factory TimeOfDay.now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
