import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../../features/auth/logic/auth_notifier.dart';
import 'package:flutter/foundation.dart';

/// 全局认证管理器（用于在非Widget上下文中访问）
class AuthManager {
  static AuthStateNotifier? _instance;

  static void setInstance(AuthStateNotifier instance) {
    _instance = instance;
  }

  static AuthStateNotifier? get instance => _instance;

  /// 刷新token（可在拦截器等非Widget上下文中调用）
  static Future<bool> refreshToken() async {
    if (_instance == null) {
      debugPrint('[AuthManager] 实例未初始化');
      return false;
    }
    return await _instance!.refreshToken();
  }

  /// 清除token（可在拦截器等非Widget上下文中调用）
  static Future<void> clearToken() async {
    if (_instance == null) {
      debugPrint('[AuthManager] 实例未初始化');
      return;
    }
    await _instance!.clearTokenInternal();
  }
}

/// 普通 API 请求的 Dio 客户端
/// receiveTimeout: 10 秒（适用于普通请求）
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConfig.requestTimeout),
      sendTimeout: const Duration(seconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 添加请求拦截器（用于添加认证 token）
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 从本地存储获取 token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 处理 401 错误，自动刷新 token
        if (error.response?.statusCode == 401) {
          debugPrint('[DioInterceptor] 检测到 401 错误，尝试刷新 token');

          try {
            // 使用 AuthManager 刷新 token
            final success = await AuthManager.refreshToken();

            if (success) {
              debugPrint('[DioInterceptor] Token 刷新成功，重试请求');

              // 获取新的 token
              final prefs = await SharedPreferences.getInstance();
              final newAccessToken = prefs.getString('access_token');

              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                // 更新原请求的 Authorization 头
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                // 创建新的请求选项，避免修改原选项的副作用
                final options = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                  contentType: error.requestOptions.contentType,
                  responseType: error.requestOptions.responseType,
                  receiveTimeout: error.requestOptions.receiveTimeout,
                  sendTimeout: error.requestOptions.sendTimeout,
                  extra: error.requestOptions.extra,
                  followRedirects: error.requestOptions.followRedirects,
                  validateStatus: error.requestOptions.validateStatus,
                  receiveDataWhenStatusError:
                      error.requestOptions.receiveDataWhenStatusError,
                );

                // 重新发送原请求
                try {
                  final retryResponse = await dio.request(
                    error.requestOptions.path,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                    options: options,
                    onReceiveProgress: error.requestOptions.onReceiveProgress,
                    onSendProgress: error.requestOptions.onSendProgress,
                    cancelToken: error.requestOptions.cancelToken,
                  );
                  return handler.resolve(retryResponse);
                } catch (retryError) {
                  debugPrint('[DioInterceptor] 重试请求失败: $retryError');
                  return handler.next(error);
                }
              }
            } else {
              debugPrint('[DioInterceptor] Token 刷新失败，清除认证状态');
              await AuthManager.clearToken();
            }
          } catch (e) {
            debugPrint('[DioInterceptor] 刷新 token 过程中发生异常: $e');
            await AuthManager.clearToken();
          }
        }

        // 处理其他网络错误
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          debugPrint('[DioInterceptor] 网络连接错误: ${error.type}');
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
});

/// 长轮询专用的 Dio 客户端
/// receiveTimeout: 45 秒（适配后端 30-40 秒的长轮询挂起）
final pollingDioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConfig.pollingTimeout),
      sendTimeout: const Duration(seconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 添加请求拦截器（用于添加认证 token）
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 从本地存储获取 token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 处理 401 错误，自动刷新 token
        if (error.response?.statusCode == 401) {
          debugPrint('[DioInterceptor] 检测到 401 错误，尝试刷新 token');

          try {
            // 使用 AuthManager 刷新 token
            final success = await AuthManager.refreshToken();

            if (success) {
              debugPrint('[DioInterceptor] Token 刷新成功，重试请求');

              // 获取新的 token
              final prefs = await SharedPreferences.getInstance();
              final newAccessToken = prefs.getString('access_token');

              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                // 更新原请求的 Authorization 头
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                // 创建新的请求选项，避免修改原选项的副作用
                final options = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                  contentType: error.requestOptions.contentType,
                  responseType: error.requestOptions.responseType,
                  receiveTimeout: error.requestOptions.receiveTimeout,
                  sendTimeout: error.requestOptions.sendTimeout,
                  extra: error.requestOptions.extra,
                  followRedirects: error.requestOptions.followRedirects,
                  validateStatus: error.requestOptions.validateStatus,
                  receiveDataWhenStatusError:
                      error.requestOptions.receiveDataWhenStatusError,
                );

                // 重新发送原请求
                try {
                  final retryResponse = await dio.request(
                    error.requestOptions.path,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                    options: options,
                    onReceiveProgress: error.requestOptions.onReceiveProgress,
                    onSendProgress: error.requestOptions.onSendProgress,
                    cancelToken: error.requestOptions.cancelToken,
                  );
                  return handler.resolve(retryResponse);
                } catch (retryError) {
                  debugPrint('[DioInterceptor] 重试请求失败: $retryError');
                  return handler.next(error);
                }
              }
            } else {
              debugPrint('[DioInterceptor] Token 刷新失败，清除认证状态');
              await AuthManager.clearToken();
            }
          } catch (e) {
            debugPrint('[DioInterceptor] 刷新 token 过程中发生异常: $e');
            await AuthManager.clearToken();
          }
        }

        // 处理其他网络错误
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          debugPrint('[DioInterceptor] 网络连接错误: ${error.type}');
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
});
