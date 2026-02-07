import 'package:dio/dio.dart';
import '../../api/api_service.dart';
import '../storage/token_storage.dart';
import '../storage/mobile_token_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  late ApiService apiService;
  final TokenStorage _tokenStorage = MobileTokenStorage();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: '', // 默认为空，需调用 init 初始化
        connectTimeout: const Duration(milliseconds: 15000), // 增加到15秒
        receiveTimeout: const Duration(milliseconds: 10000), // 增加到10秒
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加认证拦截器
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 不对特定 public 端点添加认证头（login/register/refresh）。
          // 使用 options.uri.path 来匹配，以兼容 baseUrl 中包含 `/api` 前缀的情况。
          final publicWhitelist = [
            '/public/login',
            '/public/register',
            '/public/refresh',
          ];
          final path =
              options.uri.path; // 例如 '/api/public/login' 或 '/public/login'
          final shouldSkipAuth = publicWhitelist.any((p) => path.endsWith(p));
          if (!shouldSkipAuth) {
            final token = await _tokenStorage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshToken = await _tokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                // 这里可以添加刷新token的逻辑，但需要小心循环
                // 暂时只清除token
                await _tokenStorage.clearTokens();
              } catch (e) {
                // Ignore
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 初始化API 客户端配置
  void init({
    required String baseUrl,
    int connectTimeout = 15000,
    int receiveTimeout = 15000,
  }) {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = Duration(milliseconds: connectTimeout);
    dio.options.receiveTimeout = Duration(milliseconds: receiveTimeout);

    // Initialize ApiService
    apiService = ApiService(dio, baseUrl: baseUrl);
  }
}
