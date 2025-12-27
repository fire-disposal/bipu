/// 日志管理器
/// 提供统一的日志记录功能
library;

import 'package:logger/logger.dart' as log_package;

/// 日志管理器
class Logger {
  static final log_package.Logger _logger = log_package.Logger(
    printer: log_package.PrettyPrinter(
      methodCount: 0, // 减少堆栈信息
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: log_package.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// 记录调试日志
  static void debug(String message) {
    _logger.d(message);
  }

  /// 记录信息日志
  static void info(String message) {
    _logger.i(message);
  }

  /// 记录警告日志
  static void warning(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  /// 记录错误日志
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
