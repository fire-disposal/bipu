/// API客户端接口
library;

import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

/// API配置
class ApiConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> headers;

  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.headers = const {'Content-Type': 'application/json'},
  });

  /// 创建默认配置
  factory ApiConfig.defaultConfig() {
    return const ApiConfig(baseUrl: 'http://localhost:8848');
  }

  /// 复制配置
  ApiConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, String>? headers,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      headers: headers ?? this.headers,
    );
  }
}

/// API客户端接口
abstract class ApiClient {
  /// 获取OpenAPI实例
  Openapi get openapi;

  /// 设置认证令牌
  void setAuthToken(String token);

  /// 清除认证信息
  void clearAuth();

  /// 更新基础URL
  void updateBaseUrl(String baseUrl);
}

/// API客户端实现
class ApiClientImpl implements ApiClient {
  late Openapi _openapi;
  final ApiConfig _config;

  ApiClientImpl({ApiConfig? config})
    : _config = config ?? ApiConfig.defaultConfig() {
    _initialize();
  }

  void _initialize() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        headers: _config.headers,
      ),
    );

    _openapi = Openapi(dio: dio);
  }

  @override
  Openapi get openapi => _openapi;

  @override
  void setAuthToken(String token) {
    _openapi.setBearerAuth('HTTPBearer', token);
  }

  @override
  void clearAuth() {
    _openapi.setBearerAuth('HTTPBearer', '');
  }

  @override
  void updateBaseUrl(String baseUrl) {
    final newConfig = _config.copyWith(baseUrl: baseUrl);
    _initializeWithConfig(newConfig);
  }

  void _initializeWithConfig(ApiConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: config.headers,
      ),
    );

    _openapi = Openapi(dio: dio);
  }
}
