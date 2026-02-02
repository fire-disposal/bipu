import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  // 应与后端实际刷新接口一致（RestClient.refreshToken: '/public/refresh'，'/api' 由 baseUrl 提供）
  static const String _refreshTokenPath = '/public/refresh';

  final TokenStorage _tokenStorage;
  final Function() _onUnauthorized;
  final Dio _dio; // Store the Dio instance
  bool _isRefreshing = false;
  Dio? _refreshDio;
  // 用于并发 401 时排队等待刷新结果
  Completer<bool>? _refreshCompleter;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Function() onUnauthorized,
    required Dio dio,
  }) : _tokenStorage = tokenStorage,
       _onUnauthorized = onUnauthorized,
       _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      // 刷新接口自身 401，直接登出
      if (path.endsWith(_refreshTokenPath)) {
        await _performLogout();
        return handler.next(err);
      }

      // 如果已有刷新任务，等待完成后再决定是否重试
      if (_refreshCompleter != null) {
        try {
          final ok = await _refreshCompleter!.future;
          if (ok) {
            final newToken = await _tokenStorage.getAccessToken();
            if (newToken != null) {
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResp = await _dio.fetch(opts);
              return handler.resolve(retryResp);
            }
          }
          // 刷新失败或无 token
          await _performLogout();
          return handler.next(err);
        } catch (e) {
          await _performLogout();
          return handler.next(err);
        }
      }

      // 发起刷新
      _refreshCompleter = Completer<bool>();

      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter?.complete(false);
        _refreshCompleter = null;
        await _performLogout();
        return handler.next(err);
      }

      try {
        _isRefreshing = true;
        logger.i('Access Token expired, attempting to refresh...');

        // 使用独立的 Dio 实例进行刷新，避免拦截器循环
        _refreshDio ??= Dio(
          BaseOptions(
            baseUrl: _dio.options.baseUrl,
            connectTimeout: _dio.options.connectTimeout,
            receiveTimeout: _dio.options.receiveTimeout,
          ),
        );

        final response = await _refreshDio!.post(
          _refreshTokenPath,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          final newAccessToken = response.data['access_token'] as String?;
          final newRefreshToken = response.data['refresh_token'] as String?;

          if (newAccessToken == null || newAccessToken.isEmpty) {
            throw DioException(
              requestOptions: err.requestOptions,
              message: 'No access_token in refresh response',
            );
          }

          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );

          logger.i('Token refresh successful');
          _refreshCompleter?.complete(true);

          // 重试当前原请求
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final cloneReq = await _dio.fetch(opts);
          return handler.resolve(cloneReq);
        } else {
          _refreshCompleter?.complete(false);
          await _performLogout();
        }
      } catch (e) {
        logger.e('Token refresh failed: $e');
        _refreshCompleter?.completeError(e);
        await _performLogout();
      } finally {
        _isRefreshing = false;
        _refreshCompleter = null;
      }
      return; // 已在分支内 resolve 或 next
    }
    handler.next(err);
  }

  Future<void> _performLogout() async {
    await _tokenStorage.clearTokens();
    _onUnauthorized();
  }
}
