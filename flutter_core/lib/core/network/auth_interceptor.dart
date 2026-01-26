import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  static const String _refreshTokenPath = '/users/refresh';

  final TokenStorage _tokenStorage;
  final Function() _onUnauthorized;
  final Dio _dio; // Store the Dio instance
  bool _isRefreshing = false;
  Dio? _refreshDio;

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
      // 如果正在刷新，或者请求本身就是刷新Token的请求，则直接失败
      if (_isRefreshing ||
          err.requestOptions.path.contains(_refreshTokenPath)) {
        await _performLogout();
        return handler.next(err);
      }

      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
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
          final newAccessToken = response.data['access_token'];
          // 后端可能不返回新的 refresh_token，如果返回了也更新
          final newRefreshToken = response.data['refresh_token'];

          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );

          logger.i('Token refresh successful');

          // 重试原请求
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';

          // 使用原本的 Dio 实例重试
          final cloneReq = await _dio.fetch(opts);

          return handler.resolve(cloneReq);
        } else {
          await _performLogout();
        }
      } catch (e) {
        logger.e('Token refresh failed: $e');
        await _performLogout();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  Future<void> _performLogout() async {
    await _tokenStorage.clearTokens();
    _onUnauthorized();
  }
}
