import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import 'api_service.dart';
export 'api_service.dart';

/// Shorthand accessors for the configured API client.
ApiService get bipupuApi => ApiClient().apiService;
Dio get bipupuHttp => ApiClient().dio;

extension ApiEnum on Enum {
  String get apiValue => name;
}
