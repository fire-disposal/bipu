import 'package:dio/dio.dart';
import '../../api/api_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  late ApiService apiService;

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
