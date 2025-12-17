/// 应用配置类
/// 存储应用级别的配置信息
class AppConfig {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8084/api',
  );
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '1';

  /// API基础URL
  String get baseUrl => _baseUrl;

  /// 应用版本
  String get appVersion => _appVersion;

  /// 构建号
  String get buildNumber => _buildNumber;

  /// 完整的应用版本信息
  String get fullVersion => '$_appVersion+$_buildNumber';

  /// 是否启用调试模式
  bool get isDebugMode => bool.fromEnvironment('DEBUG', defaultValue: false);

  /// 是否启用日志
  bool get enableLogging =>
      bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  /// 连接超时时间（秒）
  int get connectionTimeout => 30;

  /// 接收超时时间（秒）
  int get receiveTimeout => 30;

  /// 蓝牙扫描超时时间（秒）
  int get bluetoothScanTimeout => 10;

  /// 蓝牙连接超时时间（秒）
  int get bluetoothConnectTimeout => 15;
}
