/// 应用配置管理
class AppConfig {
  /// API 基础 URL
  /// 开发环境: http://localhost:8000
  /// 生产环境: https://api.205716.xyz
  static const String baseUrl = 'https://api.205716.xyz';

  /// 长轮询超时时间（秒）
  static const int pollingTimeout = 45;

  /// 普通请求超时时间（秒）
  static const int requestTimeout = 10;

  /// 连接超时时间（秒）
  static const int connectTimeout = 10;

  /// 发送超时时间（秒）
  static const int sendTimeout = 10;

  /// 是否启用调试模式
  static const bool debugMode = true;

  /// 蓝牙服务 UUID
  static const String bleServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';

  /// 蓝牙写特征 UUID
  static const String bleWriteUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';

  /// 蓝牙通知特征 UUID
  static const String bleNotifyUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  /// 获取用户头像 URL
  static String getUserAvatarUrl(String bipupuId) {
    return '$baseUrl/api/profile/avatar/$bipupuId';
  }

  /// 获取服务号头像 URL
  static String getServiceAccountAvatarUrl(String serviceName) {
    return '$baseUrl/api/service-accounts/$serviceName/avatar';
  }

  /// 获取 API 配置信息
  static Map<String, dynamic> getApiConfig() {
    return {
      'baseUrl': baseUrl,
      'pollingTimeout': pollingTimeout,
      'requestTimeout': requestTimeout,
      'connectTimeout': connectTimeout,
      'sendTimeout': sendTimeout,
      'debugMode': debugMode,
    };
  }
}
