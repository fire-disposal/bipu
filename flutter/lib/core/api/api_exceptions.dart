/// API 异常定义
/// 定义各种 API 相关的异常类型
library;

/// 基础 API 异常
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// 网络连接异常
class NetworkException extends ApiException {
  NetworkException({super.message = '网络连接失败'});
}

/// 认证异常
class AuthException extends ApiException {
  AuthException({super.message = '认证失败'});
}

/// 授权异常
class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = '未授权访问'})
    : super(statusCode: 401);
}

/// 禁止访问异常
class ForbiddenException extends ApiException {
  ForbiddenException({super.message = '禁止访问'})
    : super(statusCode: 403);
}

/// 资源未找到异常
class NotFoundException extends ApiException {
  NotFoundException({super.message = '资源未找到'})
    : super(statusCode: 404);
}

/// 服务器错误异常
class ServerException extends ApiException {
  ServerException({super.message = '服务器错误'})
    : super(statusCode: 500);
}

/// 请求超时异常
class TimeoutException extends ApiException {
  TimeoutException({super.message = '请求超时'});
}

/// 数据解析异常
class ParseException extends ApiException {
  ParseException({super.message = '数据解析失败'});
}

/// 验证异常
class ValidationException extends ApiException {
  ValidationException({required super.message, this.errors})
    : super(statusCode: 422);

  final Map<String, List<String>>? errors;
}

/// 速率限制异常
class RateLimitException extends ApiException {
  RateLimitException({super.message = '请求过于频繁', this.retryAfter})
    : super(statusCode: 429);

  final int? retryAfter; // 重试等待时间（秒）
}
