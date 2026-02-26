import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/storage_manager.dart';
import 'api_exception.dart';

/// API 拦截器 - 处理 Token、错误处理和日志输出
class ApiInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// 公开端点白名单 - 不需要 Token 的接口
  static const List<String> _publicEndpoints = [
    '/api/public/login',
    '/api/public/register',
    '/api/public/refresh',
    '/api/public/logout',
    '/api/public/verify-token',
    '/health',
    '/ready',
    '/live',
    '/',
    '/api/count',
    '/api/posters/',
    '/api/posters/active',
    '/api/service_accounts/',
    '/api/service_accounts/{name}/avatar',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logger.i('📤 REQUEST: ${options.method} ${options.uri}');

    if (options.headers.isNotEmpty) {
      _logger.d('📋 Headers: ${options.headers}');
    }
    if (options.data != null) {
      _logger.d('📦 Body: ${options.data}');
    }

    // 检查是否需要跳过认证
    if (!_shouldSkipAuth(options.uri.path)) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.d('🔐 Token attached to request');
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _logger.i(
      '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
    );

    if (response.data != null) {
      _logger.d('📄 Response data: ${response.data}');
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e(
      '❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}',
      error: err.message,
      stackTrace: err.stackTrace,
    );

    if (err.response?.data != null) {
      _logger.d('📄 Error response: ${err.response?.data}');
    }

    // 处理 401 未授权错误
    if (err.response?.statusCode == 401) {
      _logger.w('🔒 Token失效或未授权，清除本地认证信息');
      await _clearAuth();

      // 触发登出事件 - 由 AuthService 监听处理
      // 这里只负责清除 Token，业务逻辑由上层处理
    }

    // 转换为 ApiException
    final apiException = _convertToApiException(err);
    handler.reject(err);
  }

  /// 检查是否应该跳过认证
  bool _shouldSkipAuth(String path) {
    for (final endpoint in _publicEndpoints) {
      if (endpoint.contains('{')) {
        // 处理带参数的路径模式
        final patternParts = endpoint.split('/');
        final pathParts = path.split('/');

        if (patternParts.length == pathParts.length) {
          bool matches = true;
          for (int i = 0; i < patternParts.length; i++) {
            if (patternParts[i].startsWith('{') &&
                patternParts[i].endsWith('}')) {
              continue;
            }
            if (patternParts[i] != pathParts[i]) {
              matches = false;
              break;
            }
          }
          if (matches) return true;
        }
      } else {
        if (path == endpoint || path.startsWith('$endpoint/')) {
          return true;
        }
      }
    }
    return false;
  }

  /// 获取 Token
  Future<String?> _getToken() async {
    try {
      return await StorageManager.getSecureData(_tokenKey);
    } catch (e) {
      _logger.e('Error reading token', error: e);
      return null;
    }
  }

  /// 获取刷新 Token
  Future<String?> _getRefreshToken() async {
    try {
      return await StorageManager.getSecureData(_refreshTokenKey);
    } catch (e) {
      _logger.e('Error reading refresh token', error: e);
      return null;
    }
  }

  /// 保存 Token
  Future<void> _saveToken(String token) async {
    try {
      await StorageManager.setSecureData(_tokenKey, token);
    } catch (e) {
      _logger.e('Error saving token', error: e);
    }
  }

  /// 保存刷新 Token
  Future<void> _saveRefreshToken(String refreshToken) async {
    try {
      await StorageManager.setSecureData(_refreshTokenKey, refreshToken);
    } catch (e) {
      _logger.e('Error saving refresh token', error: e);
    }
  }

  /// 清除认证信息
  Future<void> _clearAuth() async {
    try {
      await StorageManager.setSecureData(_tokenKey, '');
      await StorageManager.setSecureData(_refreshTokenKey, '');
    } catch (e) {
      _logger.e('Error clearing auth', error: e);
    }
  }

  /// 将 DioException 转换为 ApiException
  ApiException _convertToApiException(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;

      if (statusCode == 401) {
        return AuthException.unauthorized();
      } else if (statusCode == 403) {
        return AuthException.forbidden();
      } else if (statusCode == 400) {
        return ValidationException.fromResponse(error.response!);
      } else if (statusCode != null && statusCode >= 500) {
        return ServerException.fromResponse(error.response!);
      }
    }

    return NetworkException.fromDioException(error);
  }
}
