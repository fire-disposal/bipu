import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/storage_manager.dart';

/// API 拦截器 - 处理 Token、错误处理和日志输出
class ApiInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final Logger _logger = Logger(printer: SimplePrinter());

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
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logger.i('📤 REQUEST: ${options.method} ${options.uri}');

    // 检查是否需要跳过认证
    if (!_shouldSkipAuth(options.uri.path)) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.i('✅ Token attached to request: ${token.substring(0, 20)}...');
      } else {
        _logger.w(
          '⚠️ No token available for authenticated endpoint: ${options.uri.path}',
        );
      }
    } else {
      _logger.i('⏭️ Skipping auth for public endpoint: ${options.uri.path}');
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
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}');

    // 处理 401 未授权错误
    if (err.response?.statusCode == 401) {
      _logger.w('🔒 Token失效或未授权，清除本地认证信息');
      await _clearAuth();
    }

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
      final token = await StorageManager.getSecureData(_tokenKey);
      if (token == null || token.isEmpty) {
        _logger.w('⚠️ Token is null or empty in storage');
        return null;
      }
      _logger.i('✅ Token retrieved from storage: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      _logger.e('❌ Error reading token from storage', error: e);
      return null;
    }
  }

  /// 清除认证信息
  Future<void> _clearAuth() async {
    try {
      await StorageManager.setSecureData(_tokenKey, '');
      await StorageManager.setSecureData(_refreshTokenKey, '');
      _logger.i('✅ Auth info cleared from storage');
    } catch (e) {
      _logger.e('❌ Error clearing auth from storage', error: e);
    }
  }
}
