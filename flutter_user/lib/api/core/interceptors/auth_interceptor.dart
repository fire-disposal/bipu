import 'package:dio/dio.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/mobile_token_storage.dart';
import '../../../core/utils/logger.dart';

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? MobileTokenStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    logger.i('Sending ${options.method} ${options.uri}');

    // 跳过公共端点的认证
    final publicWhitelist = [
      '/public/login',
      '/public/register',
      '/public/refresh',
    ];

    final path = options.uri.path;
    final shouldSkipAuth = publicWhitelist.any((p) => path.endsWith(p));

    if (shouldSkipAuth) {
      handler.next(options);
      return;
    }

    // 添加认证头
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理401错误 - 尝试刷新token
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // 创建新的Dio实例用于刷新token，避免循环依赖
          final refreshDio = Dio();
          refreshDio.options.baseUrl = requestOptions.baseUrl;

          // 刷新token
          final refreshResponse = await refreshDio.post(
            '/api/public/refresh',
            data: {'refresh_token': refreshToken},
          );

          final newAccessToken = refreshResponse.data['access_token'];
          final newRefreshToken = refreshResponse.data['refresh_token'];

          // 保存新token
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // 重试原始请求
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await Dio().fetch(requestOptions);

          return handler.resolve(retryResponse);
        } else {
          // 没有刷新token，清除所有token
          await _tokenStorage.clearTokens();
        }
      } catch (e) {
        logger.e('Failed to refresh token or retry request', error: e);
        // 刷新失败，清除token
        await _tokenStorage.clearTokens();
      }
    }

    handler.next(err);
  }
}
