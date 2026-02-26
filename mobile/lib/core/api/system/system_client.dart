// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/api_info_response.dart';
import '../models/health_response.dart';
import '../models/live_response.dart';
import '../models/ready_response.dart';

part 'system_client.g.dart';

@RestApi()
abstract class SystemClient {
  factory SystemClient(Dio dio, {String? baseUrl}) = _SystemClient;

  /// Health Check.
  ///
  /// 系统健康检查.
  @GET('/api/health')
  Future<HealthResponse> getApiHealth();

  /// Readiness Check.
  ///
  /// 就绪检查端点.
  @GET('/api/ready')
  Future<ReadyResponse> getApiReady();

  /// Liveness Check.
  ///
  /// 存活检查端点.
  @GET('/api/live')
  Future<LiveResponse> getApiLive();

  /// Root.
  ///
  /// 根路径 - 返回API信息.
  @GET('/api/')
  Future<ApiInfoResponse> getApi();
}
