import 'environment_config.dart';

/// 应用配置类
/// 存储应用级别的配置信息
class AppConfig {
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '1';

  /// API基础URL - 优先使用环境配置
  String get baseUrl => EnvironmentConfig.apiBaseUrl;

  /// 应用版本
  String get appVersion => _appVersion;

  /// 构建号
  String get buildNumber => _buildNumber;

  /// 完整的应用版本信息
  String get fullVersion => '$_appVersion+$_buildNumber';

  /// 是否启用调试模式
  bool get isDebugMode => EnvironmentConfig.isDebugMode;

  /// 是否启用日志
  bool get enableLogging =>
      const bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  /// 连接超时时间（秒）
  int get connectionTimeout => EnvironmentConfig.connectionTimeout;

  /// 接收超时时间（秒）
  int get receiveTimeout => EnvironmentConfig.receiveTimeout;

  /// 蓝牙扫描超时时间（秒）
  int get bluetoothScanTimeout => 10;

  /// 蓝牙连接超时时间（秒）
  int get bluetoothConnectTimeout => 15;

  /// WebSocket URL
  String get websocketUrl => EnvironmentConfig.websocketUrl;
}
