/// API 拦截器
/// 处理请求和响应的拦截逻辑
library;

import 'package:dio/dio.dart';
import '../utils/logger.dart';
import 'api_exceptions.dart';

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  final String Function() getToken;
  final void Function() onAuthFailed;

  AuthInterceptor({required this.getToken, required this.onAuthFailed});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 添加认证令牌
    final token = getToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理认证失败
    if (err.response?.statusCode == 401) {
      onAuthFailed();
    }

    handler.next(err);
  }
}

/// 日志拦截器
class LoggingInterceptor extends Interceptor {
  final bool enableRequestLog;
  final bool enableResponseLog;
  final bool enableErrorLog;

  LoggingInterceptor({
    this.enableRequestLog = true,
    this.enableResponseLog = true,
    this.enableErrorLog = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enableRequestLog) {
      Logger.info('🚀 API Request: ${options.method} ${options.uri}');
      Logger.debug('Headers: ${options.headers}');
      if (options.data != null) {
        Logger.debug('Data: ${options.data}');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enableResponseLog) {
      Logger.info(
        '✅ API Response: ${response.statusCode} ${response.requestOptions.uri}',
      );
      if (response.data != null) {
        Logger.debug('Data: ${response.data}');
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enableErrorLog) {
      Logger.error('❌ API Error: ${err.message}');
      Logger.debug('URL: ${err.requestOptions.uri}');
      if (err.response != null) {
        Logger.debug('Status: ${err.response?.statusCode}');
        Logger.debug('Data: ${err.response?.data}');
      }
    }

    handler.next(err);
  }
}

/// 错误处理拦截器
class ErrorHandlingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 转换 Dio 异常为自定义异常
    final customError = _convertToCustomException(err);
    handler.reject(customError);
  }

  DioException _convertToCustomException(DioException err) {
    if (err.response == null) {
      return err.copyWith(error: NetworkException(message: '网络连接失败'));
    }

    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    switch (statusCode) {
      case 401:
        return err.copyWith(error: UnauthorizedException());
      case 403:
        return err.copyWith(error: ForbiddenException());
      case 404:
        return err.copyWith(error: NotFoundException());
      case 422:
        return err.copyWith(
          error: ValidationException(
            message: '数据验证失败',
            errors: data is Map<String, dynamic>
                ? _parseValidationErrors(data)
                : null,
          ),
        );
      case 429:
        return err.copyWith(
          error: RateLimitException(
            retryAfter: data is Map ? data['retry_after'] as int? : null,
          ),
        );
      case int status when status >= 500 && status < 600:
        return err.copyWith(error: ServerException());
      default:
        return err;
    }
  }

  Map<String, List<String>>? _parseValidationErrors(Map<String, dynamic> data) {
    final errors = <String, List<String>>{};

    data.forEach((key, value) {
      if (value is List) {
        errors[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        errors[key] = [value];
      }
    });

    return errors.isEmpty ? null : errors;
  }
}

/// 重试拦截器
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) &&
        err.requestOptions.extra['retry_count'] != maxRetries) {
      final retryCount = (err.requestOptions.extra['retry_count'] ?? 0) as int;

      // 延迟重试
      await Future.delayed(retryDelay * (retryCount + 1));

      // 更新重试次数
      err.requestOptions.extra['retry_count'] = retryCount + 1;

      // 重试请求
      try {
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.reject(err);
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // 只在网络错误或服务器错误时重试
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
