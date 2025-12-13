/// 用户数据模型
/// 定义用户相关的数据结构
library;

/// 用户模型
class User {
  final String id;
  final String email;
  final String? username;
  final String? nickname;
  final String? avatar;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  User({
    required this.id,
    required this.email,
    this.username,
    this.nickname,
    this.avatar,
    this.phone,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.metadata,
  });

  /// 从 JSON 创建
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'role': role.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 复制对象
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? nickname,
    String? avatar,
    String? phone,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 用户角色枚举
enum UserRole {
  user, // 普通用户
  admin, // 管理员
  superAdmin, // 超级管理员
}

/// 用户状态枚举
enum UserStatus {
  active, // 活跃
  inactive, // 非活跃
  suspended, // 暂停
  deleted, // 已删除
}

/// 用户配置模型
class UserConfig {
  final String userId;
  final Map<String, dynamic> preferences;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final DateTime updatedAt;

  UserConfig({
    required this.userId,
    required this.preferences,
    required this.notificationSettings,
    required this.privacySettings,
    required this.updatedAt,
  });

  /// 从 JSON 创建
  factory UserConfig.fromJson(Map<String, dynamic> json) {
    return UserConfig(
      userId: json['user_id'] as String,
      preferences: json['preferences'] as Map<String, dynamic>,
      notificationSettings: NotificationSettings.fromJson(
        json['notification_settings'] as Map<String, dynamic>,
      ),
      privacySettings: PrivacySettings.fromJson(
        json['privacy_settings'] as Map<String, dynamic>,
      ),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'preferences': preferences,
      'notification_settings': notificationSettings.toJson(),
      'privacy_settings': privacySettings.toJson(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// 通知设置模型
class NotificationSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final Map<String, bool> notificationTypes;

  NotificationSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.notificationTypes = const {},
  });

  /// 从 JSON 创建
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      smsNotifications: json['sms_notifications'] as bool? ?? false,
      notificationTypes:
          (json['notification_types'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          {},
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'sms_notifications': smsNotifications,
      'notification_types': notificationTypes,
    };
  }
}

/// 隐私设置模型
class PrivacySettings {
  final bool profileVisible;
  final bool activityVisible;
  final bool allowDirectMessages;
  final Map<String, bool> privacyOptions;

  PrivacySettings({
    this.profileVisible = true,
    this.activityVisible = true,
    this.allowDirectMessages = true,
    this.privacyOptions = const {},
  });

  /// 从 JSON 创建
  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisible: json['profile_visible'] as bool? ?? true,
      activityVisible: json['activity_visible'] as bool? ?? true,
      allowDirectMessages: json['allow_direct_messages'] as bool? ?? true,
      privacyOptions:
          (json['privacy_options'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          {},
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'profile_visible': profileVisible,
      'activity_visible': activityVisible,
      'allow_direct_messages': allowDirectMessages,
      'privacy_options': privacyOptions,
    };
  }
}
