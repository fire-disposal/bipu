import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// API 客户端类 - 单例模式
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;
  ApiClient._internal();

  static ApiClient get instance => _instance;

  late Dio _dio;
  bool _initialized = false;

  /// 初始化 API 客户端
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _dio = Dio();

      // 配置基础选项
      _dio.options = BaseOptions(
        baseUrl: 'http://localhost:8084/api', // TODO: 从配置读取
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      );

      // 添加拦截器
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // TODO: 添加认证token
            Logger.info('API Request: ${options.method} ${options.path}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            Logger.info(
              'API Response: ${response.statusCode} ${response.requestOptions.path}',
            );
            return handler.next(response);
          },
          onError: (error, handler) {
            Logger.error(
              'API Error: ${error.message} ${error.requestOptions.path}',
            );
            return handler.next(error);
          },
        ),
      );

      _initialized = true;
      Logger.info('API 客户端初始化完成');
    } catch (e) {
      Logger.error('API 客户端初始化失败: $e');
      rethrow;
    }
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!_initialized) {
      throw Exception('API 客户端未初始化');
    }

    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      Logger.error('GET 请求失败: $e');
      rethrow;
    }
  }

  /// POST 请求
  Future<Response> post(String path, {dynamic data}) async {
    if (!_initialized) {
      throw Exception('API 客户端未初始化');
    }

    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      Logger.error('POST 请求失败: $e');
      rethrow;
    }
  }

  /// PUT 请求
  Future<Response> put(String path, {dynamic data}) async {
    if (!_initialized) {
      throw Exception('API 客户端未初始化');
    }

    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      Logger.error('PUT 请求失败: $e');
      rethrow;
    }
  }

  /// DELETE 请求
  Future<Response> delete(String path) async {
    if (!_initialized) {
      throw Exception('API 客户端未初始化');
    }

    try {
      return await _dio.delete(path);
    } catch (e) {
      Logger.error('DELETE 请求失败: $e');
      rethrow;
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _initialized;
}
