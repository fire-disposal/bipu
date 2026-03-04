/// 错误消息映射器 - 提供统一的错误消息和用户提示
///
/// 使用方式：
/// ```dart
/// try {
///   // 某些操作
/// } catch (e) {
///   final message = ErrorMessageMapper.getMessage(e);
///   SnackBarManager.showError(message);
/// }
/// ```

import '../network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorMessageMapper {
  /// 获取错误消息
  ///
  /// 参数：
  /// - exception: 异常对象
  /// - isUserFacing: 是否返回用户友好的消息（true）或技术细节（false）
  ///
  /// 返回：
  /// - 中文错误消息
  static String getMessage(dynamic exception, {bool isUserFacing = true}) {
    if (exception is AuthException) {
      return _getAuthExceptionMessage(exception, isUserFacing);
    } else if (exception is ValidationException) {
      return _getValidationExceptionMessage(exception, isUserFacing);
    } else if (exception is NetworkException) {
      return _getNetworkExceptionMessage(exception, isUserFacing);
    } else if (exception is ServerException) {
      return _getServerExceptionMessage(exception, isUserFacing);
    } else if (exception is ParseException) {
      return _getParseExceptionMessage(exception, isUserFacing);
    } else if (exception is ApiException) {
      return _getApiExceptionMessage(exception, isUserFacing);
    } else {
      return isUserFacing ? '出现了一个意外错误，请稍后重试' : exception.toString();
    }
  }

  /// 获取是否应该重试的建议
  static bool shouldRetry(dynamic exception) {
    if (exception is NetworkException) {
      return true;
    }
    if (exception is ServerException) {
      // 5xx 错误应该重试，4xx 不应该
      return (exception.statusCode ?? 0) >= 500;
    }
    return false;
  }

  /// 获取用户友好的操作建议
  static String getActionSuggestion(dynamic exception) {
    if (exception is AuthException) {
      switch (exception.statusCode) {
        case 401:
          return '请重新登录';
        case 403:
          return '您没有权限执行此操作';
        default:
          return '请尝试重新登录';
      }
    }
    if (exception is NetworkException) {
      return '请检查网络连接，然后重试';
    }
    if (exception is ServerException) {
      return '服务器出现问题，请稍后重试';
    }
    return '请稍后重试';
  }

  // ========== 私有方法 ==========

  static String _getAuthExceptionMessage(AuthException e, bool isUserFacing) {
    if (isUserFacing) {
      switch (e.statusCode) {
        case 401:
          return '登录已过期，请重新登录';
        case 403:
          return '无权限访问，请联系管理员';
        default:
          return '认证失败，请重新登录';
      }
    } else {
      return '认证异常: ${e.message}';
    }
  }

  static String _getValidationExceptionMessage(
    ValidationException e,
    bool isUserFacing,
  ) {
    if (isUserFacing) {
      // 如果有具体的字段错误，汇总显示
      if (e.errors != null && e.errors!.isNotEmpty) {
        final errors = e.errors!.entries
            .map((entry) => _formatFieldError(entry.key, entry.value))
            .join('、');
        return '输入有误: $errors';
      }
      return '输入数据不合法，请检查';
    } else {
      return '验证异常: ${e.message}';
    }
  }

  static String _getNetworkExceptionMessage(
    NetworkException e,
    bool isUserFacing,
  ) {
    if (isUserFacing) {
      // Check if it's a DioException and get the type from originalError
      if (e.originalError is DioException) {
        final dioError = e.originalError as DioException;
        switch (dioError.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            return '请求超时，请检查网络后重试';
          case DioExceptionType.connectionError:
            return '无法连接到服务器，请检查网络';
          case DioExceptionType.unknown:
            return '网络错误，请检查连接';
          default:
            return '网络连接失败，请重试';
        }
      }
      return '网络连接失败，请重试';
    } else {
      return '网络异常: ${e.message}';
    }
  }

  static String _getServerExceptionMessage(
    ServerException e,
    bool isUserFacing,
  ) {
    if (isUserFacing) {
      final status = e.statusCode ?? 500;
      if (status == 500) {
        return '服务器内部错误，请稍后重试';
      } else if (status == 503) {
        return '服务器维护中，请稍后重试';
      } else if (status == 502 || status == 504) {
        return '服务器暂时无法响应，请稍后重试';
      }
      return '服务器错误，请稍后重试';
    } else {
      return '服务器异常 (${e.statusCode}): ${e.message}';
    }
  }

  static String _getParseExceptionMessage(ParseException e, bool isUserFacing) {
    if (isUserFacing) {
      return '数据解析错误，请稍后重试';
    } else {
      return '解析异常: ${e.message}';
    }
  }

  static String _getApiExceptionMessage(ApiException e, bool isUserFacing) {
    if (isUserFacing) {
      return 'API 错误，请稍后重试';
    } else {
      return 'API 异常: ${e.message}';
    }
  }

  /// 格式化字段错误信息
  static String _formatFieldError(String field, dynamic error) {
    // 将字段名转换为中文（可扩展）
    final fieldNameMap = {
      'username': '用户名',
      'password': '密码',
      'email': '邮箱',
      'nickname': '昵称',
      'refresh_token': 'Token',
      'old_password': '原密码',
      'new_password': '新密码',
    };

    final fieldName = fieldNameMap[field] ?? field;
    final errorMessage = _formatErrorValue(error);
    return '$fieldName: $errorMessage';
  }

  /// 格式化错误值
  static String _formatErrorValue(dynamic error) {
    if (error is String) {
      return error;
    }
    if (error is List) {
      return error.map((e) => _formatErrorValue(e)).join('，');
    }
    return error.toString();
  }

  /// 日志打印（调试用）
  static void logException(dynamic exception, String operation) {
    if (kDebugMode) {
      debugPrint(
        '❌ $operation 异常: ${getMessage(exception, isUserFacing: false)}',
      );
    }
  }
}

/// 错误恢复提示类
class ErrorRecoveryHint {
  final String title;
  final String message;
  final String? buttonText;
  final Function()? onRetry;

  ErrorRecoveryHint({
    required this.title,
    required this.message,
    this.buttonText = '重试',
    this.onRetry,
  });

  /// 根据异常生成恢复提示
  factory ErrorRecoveryHint.fromException(dynamic exception) {
    if (exception is NetworkException) {
      return ErrorRecoveryHint(
        title: '网络连接失败',
        message: '请检查您的网络连接，然后重试。',
        buttonText: '重试',
      );
    }
    if (exception is ServerException) {
      return ErrorRecoveryHint(
        title: '服务器错误',
        message: '服务器暂时不可用，请稍后重试。',
        buttonText: '重试',
      );
    }
    if (exception is AuthException) {
      return ErrorRecoveryHint(
        title: '认证失败',
        message: '您的登录已过期或不足以执行此操作，请重新登录。',
        buttonText: '重新登录',
      );
    }
    return ErrorRecoveryHint(
      title: '操作失败',
      message: '发生了一个错误，请稍后重试。',
      buttonText: '重试',
    );
  }
}
