import 'dart:async';
import 'package:dio/dio.dart';
import '../core/storage/mobile_token_storage.dart';
import '../core/utils/logger.dart';
import 'api_service.dart';
export 'api_service.dart';

/// App configuration
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.205716.xyz/api',
  );

  static const int connectTimeout = 5000; // 5 seconds
  static const int receiveTimeout = 5000; // 5 seconds
}

/// Global Dio instance
final Dio _dio = _createDio();

/// Global ApiService instance
final ApiService bipupuApi = ApiService(_dio, baseUrl: AppConfig.baseUrl);

/// Shorthand accessor for Dio
Dio get bipupuHttp => _dio;

/// Create Dio instance with configuration and interceptors
Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final tokenStorage = MobileTokenStorage();
  Completer<void>? _refreshCompleter;

  // Add authentication interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        logger.i('Sending ${options.method} ${options.uri}');

        // Skip auth for public endpoints
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

        // Attach Authorization header when available
        final token = await tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // Log more details for network-level failures where response may be null
        logger.e(
          'HTTP Error: ${error.response?.statusCode ?? 'Unknown'} '
          '(${error.type}) - ${error.requestOptions.method} ${error.requestOptions.uri} '
          'message=${error.message}',
          error: error,
          stackTrace: error.stackTrace,
        );
        // Additional field for debug
        try {
          logger.d('DioException error field: ${error.error}');
        } catch (_) {}

        if (error.requestOptions.data != null) {
          logger.e('Request data: ${error.requestOptions.data}');
        }
        if (error.response?.data != null) {
          logger.e('Response data: ${error.response!.data}');
        } else {
          logger.w(
            'No response data available (network error or no server response)',
          );
        }
        final statusCode = error.response?.statusCode;
        final requestPath = error.requestOptions.uri.path;
        final publicWhitelist = [
          '/public/login',
          '/public/register',
          '/public/refresh',
        ];

        // If 401 on a protected endpoint, attempt refresh with queueing
        if (statusCode == 401 &&
            !publicWhitelist.any((p) => requestPath.endsWith(p))) {
          try {
            final opts = error.requestOptions;

            // prevent infinite retry loops
            if (opts.extra['retried'] == true) {
              await tokenStorage.clearTokens();
              handler.next(error);
              return;
            }

            final refreshToken = await tokenStorage.getRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              await tokenStorage.clearTokens();
              handler.next(error);
              return;
            }

            // If a refresh is already in progress, wait for it
            if (_refreshCompleter != null) {
              try {
                await _refreshCompleter!.future;
              } catch (_) {
                await tokenStorage.clearTokens();
                handler.next(error);
                return;
              }

              final accessAfter = await tokenStorage.getAccessToken();
              if (accessAfter != null && accessAfter.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $accessAfter';
                opts.extra['retried'] = true;
                final cloned = await dio.fetch(opts);
                handler.resolve(cloned);
                return;
              } else {
                await tokenStorage.clearTokens();
                handler.next(error);
                return;
              }
            }

            // start a new refresh and let others wait on the completer
            _refreshCompleter = Completer<void>();
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
              final refreshResp = await refreshDio.post(
                '/public/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newAccess = refreshResp.data['access_token'] as String?;
              final newRefresh = refreshResp.data['refresh_token'] as String?;
              if (newAccess != null && newAccess.isNotEmpty) {
                await tokenStorage.saveTokens(
                  accessToken: newAccess,
                  refreshToken: newRefresh,
                );

                // notify waiters
                _refreshCompleter!.complete();
                _refreshCompleter = null;

                // retry original request
                opts.headers['Authorization'] = 'Bearer $newAccess';
                opts.extra['retried'] = true;
                final cloned = await dio.fetch(opts);
                handler.resolve(cloned);
                return;
              } else {
                _refreshCompleter!.completeError(
                  Exception('Invalid refresh response'),
                );
                _refreshCompleter = null;
                await tokenStorage.clearTokens();
                handler.next(error);
                return;
              }
            } catch (e) {
              if (_refreshCompleter != null &&
                  !_refreshCompleter!.isCompleted) {
                _refreshCompleter!.completeError(e);
                _refreshCompleter = null;
              }
              await tokenStorage.clearTokens();
              handler.next(error);
              return;
            }
          } catch (e) {
            logger.e('Token refresh queue error: $e');
            await tokenStorage.clearTokens();
            handler.next(error);
            return;
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

extension ApiEnum on Enum {
  String get apiValue => name;
}
