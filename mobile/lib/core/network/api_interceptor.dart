import 'dart:async'; // 添加此行
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/storage_manager.dart';
import '../network/network.dart';
import '../config/app_config.dart';

/// API 拦截器 - 处理 Token、错误处理和日志输出
class ApiInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final Logger _logger = Logger(printer: SimplePrinter());

  // 防止并发刷新 Token
  bool _isRefreshing = false;
  // 等待刷新的请求队列
  final List<Completer<void>> _refreshCompleters = [];
  // Token 刷新失败计数
  int _refreshFailureCount = 0;
  // Token 刷新超时计时器
  Timer? _refreshTimeoutTimer;

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
      // 如果是刷新 Token 的请求本身失败，或者登出/登录失败，则直接清除 Token
      final path = err.requestOptions.uri.path;
      if (path.contains('/api/public/refresh') ||
          path.contains('/api/public/login') ||
          path.contains('/api/public/logout')) {
        _logger.w('🔒 认证相关接口 401，清除本地认证信息');
        await _clearAuth();
        handler.reject(err);
        return;
      }

      // 尝试刷新 Token
      try {
        _logger.i('🔒 遇到 401，尝试刷新 Token');
        final newToken = await _refreshToken();
        if (newToken != null) {
          // 刷新成功，重试原请求
          _logger.i('✅ Token 刷新成功，重试原请求');
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';

          final clonedRequest = await Dio().fetch(opts);
          handler.resolve(clonedRequest);
          return;
        } else {
          _logger.w('🔒 Token 刷新失败，清除本地认证信息');
          await _clearAuth();
        }
      } catch (e) {
        _logger.e('❌ Token 刷新过程出错', error: e);
        await _clearAuth();
      }
    }

    handler.reject(err);
  }

  /// 刷新 Token
  Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      // 如果正在刷新，等待刷新完成
      final completer = Completer<void>();
      _refreshCompleters.add(completer);

      // 设置超时，防止无限等待
      _refreshTimeoutTimer = Timer(AppConfig.tokenRefreshTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Token refresh timeout'));
        }
      });

      try {
        await completer.future;
      } catch (e) {
        _logger.e('⏱️ Token refresh wait timeout or failed', error: e);
        return null;
      }

      return await _getToken();
    }

    _isRefreshing = true;
    _refreshFailureCount = 0;

    try {
      final refreshToken = await StorageManager.getSecureData(_refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('⚠️ No refresh token available');
        return null;
      }

      // 使用新的 Dio 实例请求刷新，避免拦截器死循环
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.tokenRefreshTimeout,
          receiveTimeout: AppConfig.tokenRefreshTimeout,
          sendTimeout: AppConfig.tokenRefreshTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        '/api/public/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        if (accessToken != null) {
          await StorageManager.setSecureData(_tokenKey, accessToken);
          if (newRefreshToken != null) {
            await StorageManager.setSecureData(
              _refreshTokenKey,
              newRefreshToken,
            );
          }
          _logger.i('✅ Token 刷新成功');
          return accessToken;
        }
      }
      return null;
    } catch (e) {
      _logger.e('❌ Token 刷新 API 调用失败', error: e);
      _refreshFailureCount++;

      // 如果多次刷新失败，清除认证信息
      if (_refreshFailureCount >= AppConfig.maxTokenRefreshRetries) {
        _logger.w('⚠️ Token 刷新失败次数过多，清除认证信息');
        await _clearAuth();
      }

      return null;
    } finally {
      _isRefreshing = false;
      _refreshTimeoutTimer?.cancel();

      // 唤醒所有等待的请求
      for (final completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      _refreshCompleters.clear();
    }
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
      TokenManager.tokenExpired.value = true; // 通知 Auth 服务
      _logger.i('✅ Auth info cleared from storage');
    } catch (e) {
      _logger.e('❌ Error clearing auth from storage', error: e);
    }
  }
}
