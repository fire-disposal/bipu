import 'package:dio/dio.dart';
import '../exceptions.dart';
import '../../../core/utils/logger.dart';

/// 错误处理拦截器
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
      'HTTP Error: ${err.response?.statusCode ?? 'Unknown'} '
      '(${err.type}) - ${err.requestOptions.method} ${err.requestOptions.uri} '
      'message=${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );

    if (err.requestOptions.data != null) {
      logger.e('Request data: ${err.requestOptions.data}');
    }

    if (err.response?.data != null) {
      logger.e('Response data: ${err.response!.data}');
    } else {
      logger.w(
        'No response data available (network error or no server response)',
      );
    }

    // 转换DioException为业务异常
    final apiException = _convertToApiException(err);

    // 创建新的DioException，包含转换后的异常
    final newError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
      stackTrace: err.stackTrace,
    );

    handler.next(newError);
  }

  /// 将DioException转换为具体的业务异常
  ApiException _convertToApiException(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final message =
        _extractErrorMessage(data) ?? err.message ?? 'Unknown error';

    // 根据错误类型和状态码进行分类
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'Request timeout: $message',
          statusCode: statusCode,
          data: data,
        );

      case DioExceptionType.cancel:
        return CancelException(
          'Request cancelled: $message',
          statusCode: statusCode,
          data: data,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return NetworkException(
          'Network error: $message',
          statusCode: statusCode,
          data: data,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(statusCode, message, data);

      default:
        return ServerException(
          'Server error: $message',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// 处理HTTP错误响应
  ApiException _handleBadResponse(
    int? statusCode,
    String message,
    dynamic data,
  ) {
    switch (statusCode) {
      case 400:
        final errors = data is Map<String, dynamic>
            ? data['errors'] as Map<String, dynamic>?
            : null;
        return ValidationException(
          'Validation error: $message',
          errors: errors,
          statusCode: statusCode,
          data: data,
        );

      case 401:
        return AuthException(
          'Authentication failed: $message',
          statusCode: statusCode,
          data: data,
        );

      case 403:
        return ForbiddenException(
          'Access forbidden: $message',
          statusCode: statusCode,
          data: data,
        );

      case 404:
        return NotFoundException(
          'Resource not found: $message',
          statusCode: statusCode,
          data: data,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          'Server error: $message',
          statusCode: statusCode,
          data: data,
        );

      default:
        return ServerException(
          'HTTP error: $message',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// 从响应数据中提取错误信息
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) return data;

    if (data is Map<String, dynamic>) {
      // 常见的错误字段
      final possibleFields = ['message', 'error', 'detail', 'msg'];
      for (final field in possibleFields) {
        if (data.containsKey(field) && data[field] != null) {
          return data[field].toString();
        }
      }
    }

    return null;
  }
}
