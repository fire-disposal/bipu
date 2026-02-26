import 'package:dio/dio.dart';
import '../core/storage/mobile_token_storage.dart';
import '../core/utils/logger.dart';
import 'api_service.dart';
export 'api_service.dart';
export 'auth_api.dart';
export 'message_api.dart';
export 'contact_api.dart';
export 'service_account_api.dart';
export 'user_api.dart';
export 'block_api.dart';
export 'poster_api.dart';

/// App configuration
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.205716.xyz',
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

  // Add authentication interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        logger.i('Sending ${options.method} ${options.uri}');

        // Skip auth for public endpoints
        final publicWhitelist = [
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
        final path = options.uri.path;

        bool shouldSkipAuth = false;
        for (final p in publicWhitelist) {
          if (p.contains('{')) {
            // Handle path patterns with parameters
            final patternParts = p.split('/');
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
              if (matches) {
                shouldSkipAuth = true;
                break;
              }
            }
          } else {
            if (path == p || path.startsWith('$p/')) {
              shouldSkipAuth = true;
              break;
            }
          }
        }

        if (shouldSkipAuth) {
          handler.next(options);
          return;
        }

        // Attach Authorization header when available
        final token = await tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        logger.e(
          'HTTP Error: ${error.response?.statusCode ?? 'Unknown'} '
          '(${error.type}) - ${error.requestOptions.method} ${error.requestOptions.uri} '
          'message=${error.message}',
          error: error,
          stackTrace: error.stackTrace,
        );

        if (error.response?.statusCode == 401) {
          final refreshToken = await tokenStorage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // 1. Exchange refresh token for new tokens
              final refreshResponse = await dio.post(
                '/api/public/refresh',
                data: {'refresh_token': refreshToken},
              );

              final newAccessToken = refreshResponse.data['access_token'];
              final newRefreshToken = refreshResponse.data['refresh_token'];

              // 2. Save new tokens
              await tokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // 3. Retry the original request with the new access token
              final originalRequest = error.requestOptions;
              originalRequest.headers['Authorization'] =
                  'Bearer $newAccessToken';

              // Clone the request to ensure it's a new operation
              final retryResponse = await dio.fetch(originalRequest);
              return handler.resolve(retryResponse);
            } catch (e) {
              logger.e('Failed to refresh token or retry request', error: e);
              // If refresh fails, clear tokens and proceed with error
              await tokenStorage.clearTokens();
            }
          } else {
            // No refresh token, clear all tokens
            await tokenStorage.clearTokens();
          }
        }

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

        handler.next(error);
      },
    ),
  );

  return dio;
}

extension ApiEnum on Enum {
  String get apiValue => name;
}
