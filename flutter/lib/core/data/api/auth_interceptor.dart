/// 认证拦截器
library;

import 'package:dio/dio.dart';
import '../storage/jwt_storage.dart';
import '../../foundation/logger.dart';

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  final JwtStorage _jwtStorage;

  AuthInterceptor(this._jwtStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 添加JWT令牌到请求头
      final token = await _jwtStorage.getToken();
      if (token != null && !token.isExpired) {
        options.headers['Authorization'] = 'Bearer ${token.accessToken}';
        Logger.debug('Added JWT token to request: ${options.uri}');
      }
    } catch (e) {
      Logger.warning('Failed to add JWT token to request: $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理401错误，尝试刷新令牌或清除过期令牌
    if (err.response?.statusCode == 401) {
      Logger.warning(
        'JWT authentication failed (401) for: ${err.requestOptions.uri}',
      );

      try {
        // 清除过期的令牌
        await _jwtStorage.clearToken();
        Logger.info('Cleared expired JWT token due to 401 error');
      } catch (e) {
        Logger.error('Failed to clear expired JWT token: $e');
      }
    }

    handler.next(err);
  }
}

/// 认证状态监听器
class AuthStateListener {
  final List<void Function(bool isAuthenticated)> _listeners = [];

  void addListener(void Function(bool isAuthenticated) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(bool isAuthenticated) listener) {
    _listeners.remove(listener);
  }

  void notifyAuthStateChanged(bool isAuthenticated) {
    for (final listener in _listeners) {
      try {
        listener(isAuthenticated);
      } catch (e) {
        Logger.error('Error in auth state listener: $e');
      }
    }
  }
}
