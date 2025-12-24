/// 应用配置数据模型
library;

/// 应用类型枚举
enum AppType { user, admin }

/// 应用功能特性
enum AppFeature {
  auth,
  ble,
  messaging,
  userManagement,
  analytics,
  notifications,
}

/// 应用配置
class AppConfig {
  final String baseUrl;
  final int connectionTimeout;
  final int receiveTimeout;
  final AppType appType;
  final Set<AppFeature> enabledFeatures;
  final bool enableLogging;
  final LogLevel logLevel;

  const AppConfig({
    this.baseUrl = 'http://localhost:8848/api',
    this.connectionTimeout = 30,
    this.receiveTimeout = 30,
    this.appType = AppType.user,
    this.enabledFeatures = const {AppFeature.auth, AppFeature.ble},
    this.enableLogging = true,
    this.logLevel = LogLevel.info,
  });

  /// 用户端配置
  factory AppConfig.user() {
    return const AppConfig(
      appType: AppType.user,
      enabledFeatures: {
        AppFeature.auth,
        AppFeature.ble,
        AppFeature.messaging,
        AppFeature.notifications,
      },
    );
  }

  /// 管理端配置
  factory AppConfig.admin() {
    return const AppConfig(
      appType: AppType.admin,
      enabledFeatures: {
        AppFeature.auth,
        AppFeature.userManagement,
        AppFeature.analytics,
        AppFeature.notifications,
      },
    );
  }

  /// 检查是否启用某个功能
  bool isFeatureEnabled(AppFeature feature) {
    return enabledFeatures.contains(feature);
  }

  /// 是否为管理端
  bool get isAdmin => appType == AppType.admin;

  /// 是否为用户端
  bool get isUser => appType == AppType.user;

  /// 复制配置
  AppConfig copyWith({
    String? baseUrl,
    int? connectionTimeout,
    int? receiveTimeout,
    AppType? appType,
    Set<AppFeature>? enabledFeatures,
    bool? enableLogging,
    LogLevel? logLevel,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      appType: appType ?? this.appType,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
    );
  }

  @override
  String toString() {
    return 'AppConfig{baseUrl: $baseUrl, appType: $appType, '
        'enabledFeatures: $enabledFeatures}';
  }
}

/// 日志级别
enum LogLevel { debug, info, warning, error }
