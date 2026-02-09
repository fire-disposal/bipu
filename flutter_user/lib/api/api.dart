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

        // For 401 errors, just clear tokens and let the app handle re-auth
        if (error.response?.statusCode == 401) {
          await tokenStorage.clearTokens();
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
