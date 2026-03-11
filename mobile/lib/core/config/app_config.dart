/// 应用配置 - 环境相关配置的统一管理
///
/// 使用方式：
/// ```dart
/// // 获取 API Base URL
/// String baseUrl = AppConfig.apiBaseUrl;
///
/// // 创建请求超时
/// Duration timeout = AppConfig.requestTimeout;
/// ```

class AppConfig {
  // ========== API 配置 ==========
  /// API Base URL
  /// 支持通过编译时环境变量 API_BASE_URL 覆盖
  ///
  /// 运行方式：
  /// flutter run --dart-define=API_BASE_URL=https://api.example.com
  /// flutter build apk --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.205716.xyz',
  );

  /// WebSocket Base URL
  /// 支持通过编译时环境变量 WS_BASE_URL 覆盖
  /// 
  /// 运行方式：
  /// flutter run --dart-define=WS_BASE_URL=wss://ws.example.com
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.205716.xyz/api/ws',
  );

  // ========== 超时配置 ==========
  /// 普通请求超时时间
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Token 刷新请求超时时间
  static const Duration tokenRefreshTimeout = Duration(seconds: 20);

  /// WebSocket 连接超时
  static const Duration websocketConnectTimeout = Duration(seconds: 10);

  /// WebSocket 消息超时
  static const Duration websocketMessageTimeout = Duration(seconds: 30);

  // ========== Token 配置 ==========
  /// Token 过期预警时间（秒）
  /// 当 Token 剩余有效期少于此时间时，提前刷新
  static const int tokenExpiryWarningSeconds = 300; // 5 分钟

  /// Token 刷新失败最大重试次数
  static const int maxTokenRefreshRetries = 3;

  // ========== 存储配置 ==========
  /// Secure Storage Key 前缀
  static const String storageKeyPrefix = 'bipupu_';

  /// Access Token 存储 Key
  static const String accessTokenKey = '${storageKeyPrefix}access_token';

  /// Refresh Token 存储 Key
  static const String refreshTokenKey = '${storageKeyPrefix}refresh_token';

  // ========== 日志配置 ==========
  /// 是否启用 API 请求日志
  static const bool enableApiLogging = true;

  /// 是否启用 Token 相关日志
  static const bool enableTokenLogging = true;

  // ========== 错误处理 ==========
  /// Token 刷新失败后是否自动清除本地认证信息
  static const bool clearAuthOnTokenRefreshFailure = true;

  /// 是否启用自动 Token 刷新
  static const bool enableAutoTokenRefresh = true;

  // ========== 功能开关 ==========
  /// 是否启用 JWT Token 验证日志（开发调试用）
  static const bool enableJwtDebugLogging = false;

  /// 是否验证 Token 过期时间
  static const bool validateTokenExpiry = true;
}
