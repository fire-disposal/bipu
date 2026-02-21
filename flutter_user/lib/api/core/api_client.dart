import 'package:dio/dio.dart';
import 'token_storage.dart';
import '../../../core/utils/logger.dart';
import 'exceptions.dart';

/// App配置
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.205716.xyz',
  );

  static const int connectTimeout = 5000; // 5秒
  static const int receiveTimeout = 5000; // 5秒
  static const int sendTimeout = 5000; // 5秒
}

/// 简化的API客户端，合并了所有拦截器逻辑
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  /// 私有构造函数
  ApiClient._internal({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? MobileTokenStorage() {
    _dio = _createDio();
  }

  /// 获取单例实例
  factory ApiClient({TokenStorage? tokenStorage}) {
    _instance ??= ApiClient._internal(tokenStorage: tokenStorage);
    return _instance!;
  }

  /// 获取Dio实例（用于向后兼容）
  Dio get dio => _dio;

  /// 创建Dio实例并设置拦截器
  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: AppConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加合并的拦截器
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    return dio;
  }

  /// 请求拦截器（合并了认证和日志）
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 日志记录
    logger.i('🚀 ${options.method.toUpperCase()} ${options.uri}');

    // 跳过公共端点的认证
    final publicWhitelist = [
      '/public/login',
      '/public/register',
      '/public/refresh',
    ];

    final path = options.uri.path;
    final shouldSkipAuth = publicWhitelist.any((p) => path.endsWith(p));

    if (!shouldSkipAuth) {
      // 添加认证头
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  /// 响应拦截器（合并了日志）
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode;
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri;

    final emoji = _getStatusEmoji(statusCode);
    logger.i('$emoji $method $uri - Status: $statusCode');

    handler.next(response);
  }

  /// 错误拦截器（合并了错误处理和日志）
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode ?? 'Unknown';
    final method = err.requestOptions.method.toUpperCase();
    final uri = err.requestOptions.uri;

    logger.e('❌ $method $uri - Status: $statusCode - ${err.message}');

    // 处理401错误 - 尝试刷新token
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // 尝试刷新token
          final newToken = await _refreshToken(refreshToken);
          final accessToken = newToken['access'] as String;
          final refreshTokenNew = newToken['refresh'] as String;
          await _tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshTokenNew,
          );

          // 重试原始请求
          requestOptions.headers['Authorization'] = 'Bearer $accessToken';
          final retryResponse = await _dio.fetch<dynamic>(requestOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (e) {
        logger.e('Failed to refresh token or retry request', error: e);
        // 刷新失败，清除token
        await _tokenStorage.clearTokens();
      }
    }

    // 转换为统一的API异常
    final exception = _handleError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
        stackTrace: err.stackTrace,
      ),
    );
  }

  /// 刷新token
  Future<Map<String, dynamic>> _refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/public/refresh',
      data: {'refresh': refreshToken},
    );
    return response.data!;
  }

  /// 处理错误并转换为统一的异常
  Exception _handleError(DioException e) {
    // 如果错误已经被转换过，直接抛出
    if (e.error is ApiException) {
      return e.error as ApiException;
    }

    // 否则创建通用的API异常
    final statusCode = e.response?.statusCode;
    final message = e.message ?? 'Unknown error occurred';

    return ServerException(
      message,
      statusCode: statusCode,
      data: e.response?.data,
    );
  }

  /// 获取状态表情符号
  String _getStatusEmoji(int? statusCode) {
    if (statusCode == null) return '❓';
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '🔄';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    return '❌';
  }

  /// GET请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT请求
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE请求
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH请求
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 下载文件
  Future<void> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    dynamic data,
    Options? options,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 上传文件
  Future<T> upload<T>(
    String path,
    FormData data, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 设置基础URL
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// 添加请求头
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// 移除请求头
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// 清空所有请求头
  void clearHeaders() {
    _dio.options.headers.clear();
    // 重新添加默认头
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
  }

  /// 获取当前基础URL
  String get baseUrl => _dio.options.baseUrl;

  /// 获取当前请求头
  Map<String, dynamic> get headers => Map.from(_dio.options.headers);
}

/// 全局API客户端实例
final api = ApiClient();
