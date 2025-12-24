/// 日志管理器
/// 提供统一的日志记录功能
library;

import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// 日志管理器
class Logger {
  static const String _tag = 'Core';
  static LogLevel _currentLevel = LogLevel.info;

  /// 设置日志级别
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// 记录调试日志
  static void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// 记录信息日志
  static void info(String message) {
    _log(LogLevel.info, message);
  }

  /// 记录警告日志
  static void warning(String message, [dynamic error]) {
    _log(LogLevel.warning, '$message${error != null ? ' - $error' : ''}');
  }

  /// 记录错误日志
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final errorMessage = StringBuffer(message);
    if (error != null) {
      errorMessage.write(' - $error');
    }
    if (stackTrace != null) {
      errorMessage.write('\nStackTrace: $stackTrace');
    }
    _log(LogLevel.error, errorMessage.toString());
  }

  static void _log(LogLevel level, String message) {
    if (level.index < _currentLevel.index) return;

    final logPrefix = _getLogPrefix(level);
    final logMessage = '[$_tag] $logPrefix$message';

    switch (level) {
      case LogLevel.debug:
        developer.log(logMessage, name: _tag, level: 500);
        break;
      case LogLevel.info:
        developer.log(logMessage, name: _tag, level: 800);
        break;
      case LogLevel.warning:
        developer.log(logMessage, name: _tag, level: 900);
        break;
      case LogLevel.error:
        developer.log(logMessage, name: _tag, level: 1000);
        break;
    }
  }

  static String _getLogPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 ';
      case LogLevel.info:
        return 'ℹ️ ';
      case LogLevel.warning:
        return '⚠️ ';
      case LogLevel.error:
        return '❌ ';
    }
  }
}
