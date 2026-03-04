import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../api/rest_client.dart';
import 'api_interceptor.dart';
import 'api_exception.dart';
import '../config/app_config.dart';

/// API 客户端 - 围绕生成的 RestClient 的封装
/// 提供统一的网络请求接口，处理 Token、错误处理和日志输出
class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  late final Dio _dio;
  late final RestClient _restClient;
  late final Logger _logger;

  ApiClient._internal() {
    _logger = Logger(printer: SimplePrinter());

    _initializeDio();
    _restClient = RestClient(_dio);
  }

  /// 初始化 Dio 实例
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.requestTimeout,
        receiveTimeout: AppConfig.requestTimeout,
        sendTimeout: AppConfig.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.addAll([
      ApiInterceptor(),
      if (kDebugMode && AppConfig.enableApiLogging) _createLogInterceptor(),
    ]);
  }

  /// 创建日志拦截器
  LogInterceptor _createLogInterceptor() {
    return LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (message) {
        _logger.d('🌐 DIO: $message');
      },
    );
  }

  /// 获取 Dio 实例
  Dio get dio => _dio;

  /// 获取 RestClient 实例
  RestClient get restClient => _restClient;

  /// 获取生成的 API 客户端
  /// 使用示例：
  /// ```dart
  /// final users = await apiClient.api.users.getUsers();
  /// final token = await apiClient.api.authentication.login(body: loginRequest);
  /// ```
  RestClient get api => _restClient;

  /// 执行 API 请求并处理异常
  ///
  /// 使用示例：
  /// ```dart
  /// try {
  ///   final result = await apiClient.execute(
  ///     () => apiClient.api.users.getUsers(),
  ///   );
  /// } on AuthException catch (e) {
  ///   // 处理认证异常
  /// } on ServerException catch (e) {
  ///   // 处理服务器异常
  /// } on NetworkException catch (e) {
  ///   // 处理网络异常
  /// }
  /// ```
  Future<T> execute<T>(
    Future<T> Function() request, {
    String? operationName,
  }) async {
    try {
      _logger.i('🚀 Executing: ${operationName ?? 'API Request'}');
      final result = await request();
      _logger.i('✅ Success: ${operationName ?? 'API Request'}');
      return result;
    } on DioException catch (e) {
      final apiException = _convertException(e);
      _logger.e(
        '❌ Error: ${operationName ?? 'API Request'}: ${apiException.message} (Status: ${e.response?.statusCode})',
      );
      rethrow;
    } catch (e) {
      _logger.e('❌ Unexpected Error: ${operationName ?? 'API Request'}: $e');
      rethrow;
    }
  }

  /// 将 DioException 转换为 ApiException
  ApiException _convertException(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;

      if (statusCode == 401) {
        return AuthException.unauthorized();
      } else if (statusCode == 403) {
        return AuthException.forbidden();
      } else if (statusCode == 400) {
        return ValidationException.fromResponse(error.response!);
      } else if (statusCode != null && statusCode >= 500) {
        return ServerException.fromResponse(error.response!);
      }
    }

    return NetworkException.fromDioException(error);
  }

  /// 清除所有拦截器
  void clearInterceptors() {
    _dio.interceptors.clear();
  }

  /// 添加自定义拦截器
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// 移除拦截器
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// 重置 Dio 实例
  void reset() {
    _dio.close();
    _initializeDio();
    _restClient = RestClient(_dio);
  }
}
