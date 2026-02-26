import 'package:dio/dio.dart';

/// API 异常基类
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({required this.message, this.statusCode, this.originalError});

  @override
  String toString() => message;
}

/// 网络异常
class NetworkException extends ApiException {
  NetworkException({required String message, dynamic originalError})
    : super(message: message, originalError: originalError);

  factory NetworkException.fromDioException(DioException error) {
    String message = '网络错误';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时';
        break;
      case DioExceptionType.sendTimeout:
        message = '发送超时';
        break;
      case DioExceptionType.receiveTimeout:
        message = '接收超时';
        break;
      case DioExceptionType.badResponse:
        message = '服务器错误: ${error.response?.statusCode}';
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        break;
      case DioExceptionType.unknown:
        message = error.message ?? '未知网络错误';
        break;
      case DioExceptionType.badCertificate:
        message = '证书错误';
        break;
      case DioExceptionType.connectionError:
        message = '连接错误';
        break;
    }

    return NetworkException(message: message, originalError: error);
  }
}

/// 认证异常
class AuthException extends ApiException {
  AuthException({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) : super(
         message: message,
         statusCode: statusCode,
         originalError: originalError,
       );

  factory AuthException.unauthorized() {
    return AuthException(message: '未授权，请重新登录', statusCode: 401);
  }

  factory AuthException.forbidden() {
    return AuthException(message: '禁止访问', statusCode: 403);
  }

  factory AuthException.tokenExpired() {
    return AuthException(message: 'Token已过期', statusCode: 401);
  }
}

/// 服务器异常
class ServerException extends ApiException {
  final Map<String, dynamic>? responseData;

  ServerException({
    required String message,
    required int statusCode,
    this.responseData,
    dynamic originalError,
  }) : super(
         message: message,
         statusCode: statusCode,
         originalError: originalError,
       );

  factory ServerException.fromResponse(Response response) {
    String message = '服务器错误';

    if (response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      message = data['message'] ?? data['detail'] ?? message;
    }

    return ServerException(
      message: message,
      statusCode: response.statusCode ?? 500,
      responseData: response.data is Map ? response.data : null,
      originalError: response,
    );
  }
}

/// 验证异常
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({
    required String message,
    this.errors,
    dynamic originalError,
  }) : super(message: message, statusCode: 400, originalError: originalError);

  factory ValidationException.fromResponse(Response response) {
    String message = '验证失败';
    Map<String, dynamic>? errors;

    if (response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      message = data['message'] ?? message;
      errors = data['errors'] as Map<String, dynamic>?;
    }

    return ValidationException(
      message: message,
      errors: errors,
      originalError: response,
    );
  }
}

/// 解析异常
class ParseException extends ApiException {
  ParseException({required String message, dynamic originalError})
    : super(message: message, originalError: originalError);
}
