import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 普通 API 请求的 Dio 客户端
/// receiveTimeout: 10 秒（适用于普通请求）
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000', // TODO: 根据环境配置
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
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
      baseUrl: 'http://localhost:8000', // TODO: 根据环境配置
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45), // 长轮询专用超时
      sendTimeout: const Duration(seconds: 10),
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
