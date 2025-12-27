/// 统一异常处理
library;

/// 基础应用异常
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, [this.code, this.originalError]);

  @override
  String toString() => message;
}

/// API异常
class ApiException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? responseData;

  const ApiException(
    String message, {
    this.statusCode,
    this.responseData,
    String? code,
    dynamic originalError,
  }) : super(message, code, originalError);

  @override
  String toString() {
    if (statusCode != null) {
      return 'API错误 [$statusCode]: $message';
    }
    return 'API错误: $message';
  }
}

/// 认证异常
class AuthException extends AppException {
  const AuthException(super.message, [super.code, super.originalError]);
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code, super.originalError]);
}

/// 数据异常
class DataException extends AppException {
  const DataException(super.message, [super.code, super.originalError]);
}

/// 验证异常
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(
    String message, {
    required this.fieldErrors,
    String? code,
    dynamic originalError,
  }) : super(message, code, originalError);
}

/// 权限异常
class PermissionException extends AppException {
  const PermissionException(
    super.message, [
    super.code,
    super.originalError,
  ]);
}

/// 服务异常
class ServiceException extends AppException {
  const ServiceException(super.message, [super.code, super.originalError]);
}
