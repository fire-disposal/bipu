import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'rest_client.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  late final TokenStorage _tokenStorage;
  late RestClient restClient;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: '', // 默认为空，需调用 init 初始�?
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

  /// 初始�?API 客户端配�?
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

    // Initialize RestClient
    restClient = RestClient(dio, baseUrl: baseUrl);

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
    // 移除旧的 AuthInterceptor，并尽量保持其在日志拦截器之前的顺序
    dio.interceptors.removeWhere((element) => element is AuthInterceptor);

    final auth = AuthInterceptor(
      dio: dio,
      tokenStorage: _tokenStorage,
      onUnauthorized: callback,
    );

    // 尽量�?AuthInterceptor 插入�?Logger 之前，以便在日志打印前完成鉴权头设置
    final loggerIndex = dio.interceptors.indexWhere(
      (e) => e is GlobalHttpInterceptor,
    );
    if (loggerIndex >= 0) {
      dio.interceptors.insert(loggerIndex, auth);
    } else {
      dio.interceptors.add(auth);
    }
  }
}
