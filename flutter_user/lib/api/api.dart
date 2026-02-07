import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/rest_client.dart';

/// Shorthand accessors for the configured API client.
RestClient get bipupuApi => ApiClient().restClient;
Dio get bipupuHttp => ApiClient().dio;

extension ApiEnum on Enum {
  String get apiValue => name;
}
