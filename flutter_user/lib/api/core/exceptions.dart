/// API异常基类
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// 认证异常
class AuthException extends ApiException {
  const AuthException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}

/// 权限异常
class ForbiddenException extends ApiException {
  const ForbiddenException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}

/// 资源未找到异常
class NotFoundException extends ApiException {
  const NotFoundException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}

/// 验证异常
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  const ValidationException(
    String message, {
    this.errors,
    int? statusCode,
    dynamic data,
  }) : super(message, statusCode: statusCode, data: data);
}

/// 服务器异常
class ServerException extends ApiException {
  const ServerException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}

/// 网络异常
class NetworkException extends ApiException {
  const NetworkException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}

/// 请求超时异常
class TimeoutException extends ApiException {
  const TimeoutException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}

/// 取消请求异常
class CancelException extends ApiException {
  const CancelException(String message, {int? statusCode, dynamic data})
    : super(message, statusCode: statusCode, data: data);
}
