import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

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
        // TODO: 处理 401 错误，刷新 token 等
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
        // TODO: 处理 401 错误，刷新 token 等
        return handler.next(error);
      },
    ),
  );

  return dio;
});
