import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

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

/// Axios风格的API客户端
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  /// 私有构造函数
  ApiClient._internal() {
    _dio = _createDio();
  }

  /// 获取单例实例
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// 获取Dio实例（用于向后兼容）
  Dio get dio => _dio;

  /// 创建Dio实例
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

    // 添加拦截器
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
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

  /// 并发执行多个请求（类似axios.all）
  static Future<List<T>> all<T>(List<Future<T>> requests) {
    return Future.wait(requests);
  }

  /// 并发执行多个请求并解构结果（类似axios.spread）
  static Future<R> spread<T, R>(
    List<Future<T>> requests,
    R Function(List<T>) callback,
  ) async {
    final results = await Future.wait(requests);
    return callback(results);
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

  /// 处理错误
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
