/// 环境配置类
/// 从环境变量读取配置信息
class EnvironmentConfig {
  /// API基础URL - 优先从环境变量读取，其次使用默认值
  static String get apiBaseUrl {
    return const String.fromEnvironment(
      'FLUTTER_API_BASE_URL',
      defaultValue: 'http://localhost:8848',
    );
  }

  /// WebSocket URL - 优先从环境变量读取，其次使用默认值
  static String get websocketUrl {
    return const String.fromEnvironment(
      'FLUTTER_WEBSOCKET_URL',
      defaultValue: 'ws://localhost:8848/ws',
    );
  }

  /// 是否启用调试模式
  static bool get isDebugMode {
    return const bool.fromEnvironment('FLUTTER_DEBUG_MODE', defaultValue: true);
  }

  /// 连接超时时间（秒）
  static int get connectionTimeout {
    return const int.fromEnvironment(
      'FLUTTER_CONNECTION_TIMEOUT',
      defaultValue: 30,
    );
  }

  /// 接收超时时间（秒）
  static int get receiveTimeout {
    return const int.fromEnvironment(
      'FLUTTER_RECEIVE_TIMEOUT',
      defaultValue: 30,
    );
  }
}
