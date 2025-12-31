import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: _tokenStorage,
        onUnauthorized: () {
          // This callback will be set by AuthService or handled via a stream
          // For now, we can print or use a global key if needed,
          // but ideally AuthService should listen to this.
          // Since this is a singleton, we might need a way to notify listeners.
          // We'll implement a simple stream controller in AuthService instead.
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
