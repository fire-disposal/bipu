import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/config/api_config.dart';
import 'token_service.dart';

/// 服务层统一错误类型
enum ServiceErrorType {
  network,
  server,
  unauthorized,
  validation,
  unknown,
  tokenExpired,
}

/// 服务层统一错误
class ServiceError {
  final String message;
  final ServiceErrorType type;
  final int? statusCode;

  ServiceError(this.message, this.type, {this.statusCode});

  @override
  String toString() => 'ServiceError($type): $message';
}

/// 服务层统一响应
class ServiceResponse<T> {
  final T? data;
  final ServiceError? error;
  final bool success;

  ServiceResponse.success(this.data) : success = true, error = null;

  ServiceResponse.failure(this.error) : success = false, data = null;
}

/// 基础服务类 - 所有服务的基类
abstract class BaseService {
  static Dio? _sharedDio;
  static bool _isRefreshingToken = false;
  static final List<Completer<void>> _refreshWaiters = [];

  Dio get dio {
    _sharedDio ??= _createDio();
    return _sharedDio!;
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 添加拦截器
    dio.interceptors.add(_createTokenInterceptor());
    dio.interceptors.add(_createLoggingInterceptor());

    return dio;
  }

  /// 更新token（供TokenService调用）
  void updateToken(String newToken) {
    // 更新所有等待中的请求的token
    _sharedDio?.options.headers['Authorization'] = 'Bearer $newToken';
  }

  // 统一的HTTP方法封装
  Future<ServiceResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic>)? fromJson,
    bool retryOnTokenExpired = true,
  }) => _request<T>(
    'GET',
    path,
    query: query,
    fromJson: fromJson,
    retryOnTokenExpired: retryOnTokenExpired,
  );

  Future<ServiceResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
    bool retryOnTokenExpired = true,
  }) => _request<T>(
    'POST',
    path,
    data: data,
    fromJson: fromJson,
    retryOnTokenExpired: retryOnTokenExpired,
  );

  Future<ServiceResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
    bool retryOnTokenExpired = true,
  }) => _request<T>(
    'PUT',
    path,
    data: data,
    fromJson: fromJson,
    retryOnTokenExpired: retryOnTokenExpired,
  );

  Future<ServiceResponse<T>> delete<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
    bool retryOnTokenExpired = true,
  }) => _request<T>(
    'DELETE',
    path,
    fromJson: fromJson,
    retryOnTokenExpired: retryOnTokenExpired,
  );

  // 统一的请求处理
  Future<ServiceResponse<T>> _request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic>)? fromJson,
    bool retryOnTokenExpired = true,
  }) async {
    print('🌐 开始API请求: $method $path');
    if (data != null) {
      print('📦 请求数据: $data');
    }

    try {
      final response = await dio.request<T>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );

      print('✅ API响应: ${response.statusCode} $path');
      if (response.data != null) {
        print('📄 响应数据: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (fromJson != null && response.data is Map<String, dynamic>) {
          final parsedData = fromJson(response.data as Map<String, dynamic>);
          return ServiceResponse.success(parsedData);
        }
        return ServiceResponse.success(response.data as T);
      } else {
        print('❌ API错误状态码: ${response.statusCode}');
        return ServiceResponse.failure(
          ServiceError(
            '请求失败: ${response.statusCode}',
            ServiceErrorType.server,
            statusCode: response.statusCode,
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ Dio异常: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('📄 错误响应数据: ${e.response?.data}');
        print('🔧 错误响应头: ${e.response?.headers}');
      }
      return ServiceResponse.failure(_handleDioError(e));
    } catch (e) {
      print('❌ 未知异常: $e');
      return ServiceResponse.failure(
        ServiceError(e.toString(), ServiceErrorType.unknown),
      );
    }
  }

  // 错误处理
  ServiceError _handleDioError(DioException e) {
    print(
      '🔧 处理Dio错误: type=${e.type}, status=${e.response?.statusCode}, message=${e.message}',
    );

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      print('⏰ 网络超时错误');
      return ServiceError('网络连接超时', ServiceErrorType.network);
    } else if (e.type == DioExceptionType.connectionError) {
      print('🔌 网络连接错误');
      return ServiceError('网络连接错误', ServiceErrorType.network);
    } else if (e.response?.statusCode == 401) {
      print('🔑 401未授权错误');
      // 检查是否是token过期
      final responseData = e.response?.data;
      print('📄 401响应数据: $responseData');
      if (responseData is Map<String, dynamic>) {
        final errorMsg = responseData['detail']?.toString().toLowerCase() ?? '';
        if (errorMsg.contains('token') && errorMsg.contains('expired')) {
          print('🔑 Token过期错误');
          return ServiceError('令牌已过期', ServiceErrorType.tokenExpired);
        }
      }
      return ServiceError('未授权访问', ServiceErrorType.unauthorized);
    } else if (e.response?.statusCode == 400) {
      print('📝 400请求参数错误');
      final responseData = e.response?.data;
      print('📄 400响应数据: $responseData');
      return ServiceError('请求参数错误', ServiceErrorType.validation);
    } else if (e.response?.statusCode == 500) {
      print('💥 500服务器内部错误');
      final responseData = e.response?.data;
      print('📄 500响应数据: $responseData');
      return ServiceError('服务器内部错误', ServiceErrorType.server);
    } else if (e.response?.statusCode == 404) {
      print('🔍 404未找到资源');
      return ServiceError('请求的资源不存在', ServiceErrorType.server);
    }

    print('❓ 未知Dio错误类型: ${e.type}');
    return ServiceError(e.message ?? '未知错误', ServiceErrorType.unknown);
  }

  // Token拦截器
  InterceptorsWrapper _createTokenInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 等待token刷新完成（如果有）
        if (_isRefreshingToken) {
          await _waitForTokenRefresh();
        }

        final tokenService = Get.find<TokenService>();
        final token = await tokenService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final tokenService = Get.find<TokenService>();

          // 检查是否是token过期
          final responseData = error.response?.data;
          bool isTokenExpired = false;
          if (responseData is Map<String, dynamic>) {
            final errorMsg =
                responseData['detail']?.toString().toLowerCase() ?? '';
            isTokenExpired =
                errorMsg.contains('token') &&
                (errorMsg.contains('expired') || errorMsg.contains('invalid'));
          }

          if (isTokenExpired) {
            // 尝试刷新token
            final refreshed = await _refreshTokenWithLock();
            if (refreshed) {
              // 重试原始请求
              final newToken = await tokenService.getAccessToken();
              if (newToken != null) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
              }

              final response = await dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
              );
              return handler.resolve(response);
            } else {
              // 刷新失败，检查是否是refresh token过期
              if (tokenService.refreshStatus.value ==
                  TokenRefreshStatus.expired) {
                // 通知应用需要重新登录
                Get.snackbar('会话过期', '请重新登录');
                // 可以在这里触发全局登出逻辑
              }
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  /// 等待token刷新完成
  Future<void> _waitForTokenRefresh() async {
    final completer = Completer<void>();
    _refreshWaiters.add(completer);
    return completer.future;
  }

  /// 通知所有等待者token刷新完成
  void _notifyRefreshWaiters() {
    for (final waiter in _refreshWaiters) {
      waiter.complete();
    }
    _refreshWaiters.clear();
  }

  /// 带锁的token刷新（防止并发刷新）
  Future<bool> _refreshTokenWithLock() async {
    if (_isRefreshingToken) {
      // 已经在刷新中，等待结果
      await _waitForTokenRefresh();
      final tokenService = Get.find<TokenService>();
      return tokenService.refreshStatus.value == TokenRefreshStatus.success;
    }

    _isRefreshingToken = true;
    try {
      final tokenService = Get.find<TokenService>();
      final result = await tokenService.refreshToken();

      // 通知所有等待者
      _notifyRefreshWaiters();

      return result;
    } finally {
      _isRefreshingToken = false;
    }
  }

  // 日志拦截器
  InterceptorsWrapper _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          log('🚀 ${options.method} ${options.path}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          log('✅ ${response.statusCode} ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          log('❌ ${error.response?.statusCode} ${error.requestOptions.path}');
        }
        return handler.next(error);
      },
    );
  }

  // Token管理 - 已迁移到TokenService
}
