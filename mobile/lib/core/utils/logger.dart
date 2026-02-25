// bipupu/mobile/lib/core/utils/logger.dart

/// 简单的日志工具类
class Logger {
  /// 输出信息日志
  static void info(String message) {
    print('[INFO] $message');
  }

  /// 输出错误日志
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[ERROR] $message');
    if (error != null) {
      print('[ERROR] Error: $error');
    }
    if (stackTrace != null) {
      print('[ERROR] StackTrace: $stackTrace');
    }
  }

  /// 输出调试日志
  static void debug(String message) {
    print('[DEBUG] $message');
  }

  /// 输出警告日志
  static void warning(String message) {
    print('[WARNING] $message');
  }
}
