/// 应用常量定义
library;

/// API相关常量
class ApiConstants {
  static const String defaultBaseUrl = 'http://localhost:8848';
  static const int defaultConnectionTimeout = 30;
  static const int defaultReceiveTimeout = 30;
  static const String contentType = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}

/// JWT相关常量
class JwtConstants {
  static const String accessTokenKey = 'jwt_access_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String expiresAtKey = 'jwt_expires_at';
  static const int tokenExpiryThresholdMinutes = 5;
}

/// BLE相关常量
class BleConstants {
  static const String deviceControlServiceUuid =
      '00001800-0000-1000-8000-00805f9b34fb';
  static const String commandCharacteristicUuid =
      '00002a00-0000-1000-8000-00805f9b34fb';
  static const String statusCharacteristicUuid =
      '00002a01-0000-1000-8000-00805f9b34fb';

  static const int maxMessageSize = 512;
  static const int chunkSize = 20;
  static const int chunkDelayMs = 50;
  static const int connectionTimeoutSeconds = 15;
  static const int scanTimeoutSeconds = 10;
}

/// 存储相关常量
class StorageConstants {
  static const String appConfigKey = 'app_config';
  static const String userPreferencesKey = 'user_preferences';
}

/// 路由相关常量
class RouteConstants {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String adminDashboard = '/admin/dashboard';
  static const String userManagement = '/admin/users';
}

/// 错误消息常量
class ErrorMessages {
  static const String networkError = '网络连接失败';
  static const String authenticationError = '认证失败';
  static const String authorizationError = '权限不足';
  static const String validationError = '数据验证失败';
  static const String serverError = '服务器错误';
  static const String unknownError = '未知错误';
  static const String bluetoothNotSupported = '设备不支持蓝牙';
  static const String bluetoothNotEnabled = '蓝牙未开启';
}
