/// 日志工具类
library;

enum LogLevel { debug, info, warning, error }

class Logger {
  static LogLevel _currentLevel = LogLevel.info;

  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  static void debug(String message) {
    if (_shouldLog(LogLevel.debug)) {
      print('[DEBUG] $message');
    }
  }

  static void info(String message) {
    if (_shouldLog(LogLevel.info)) {
      print('[INFO] $message');
    }
  }

  static void warning(String message) {
    if (_shouldLog(LogLevel.warning)) {
      print('[WARNING] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.error)) {
      print('[ERROR] $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static bool _shouldLog(LogLevel level) {
    return level.index >= _currentLevel.index;
  }

  /// 用户行为日志
  static void logUserAction(String message) {
    info('[UserAction] $message');
  }

  /// 蓝牙相关日志
  static void logBluetooth(String message) {
    debug('[Bluetooth] $message');
  }

  /// 事件日志
  static void logEvent(String message) {
    info('[Event] $message');
  }

  /// 错误日志（便于统一调用）
  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    error(message, error, stackTrace);
  }
}
