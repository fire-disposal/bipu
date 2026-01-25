import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  late final TokenStorage _tokenStorage;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: '', // 默认为空，需调用 init 初始化
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 3000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    // Interceptors will be added in init() because they need tokenStorage
  }

  /// 初始化 API 客户端配置
  void init({
    required String baseUrl,
    required TokenStorage tokenStorage,
    int connectTimeout = 15000,
    int receiveTimeout = 15000,
  }) {
    _tokenStorage = tokenStorage;
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = Duration(milliseconds: connectTimeout);
    dio.options.receiveTimeout = Duration(milliseconds: receiveTimeout);

    // Clear existing interceptors to avoid duplicates if init is called multiple times
    dio.interceptors.clear();

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: _tokenStorage,
        onUnauthorized: () {
          // This callback will be set by AuthService or handled via a stream
        },
      ),
    );

    // Add logger interceptor
    dio.interceptors.add(GlobalHttpInterceptor());
  }

  // Helper to update the unauthorized callback
  void setUnauthorizedCallback(Function() callback) {
    // We need to find the AuthInterceptor and update it, or just re-add it.
    // For simplicity in this "No DI" approach, we can just expose a static stream/callback
    // or let AuthService handle the 401 check independently.
    // But let's keep it simple:
    dio.interceptors.removeWhere((element) => element is AuthInterceptor);
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: _tokenStorage,
        onUnauthorized: callback,
      ),
    );
  }
}
