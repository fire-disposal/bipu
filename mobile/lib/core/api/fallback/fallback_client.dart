// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/api_info_response.dart';
import '../models/body_admin_login_admin_login_post.dart';
import '../models/body_update_service_push_time_admin_service_accounts_service_id_push_time_post.dart';
import '../models/health_response.dart';
import '../models/live_response.dart';
import '../models/ready_response.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Health Check.
  ///
  /// 系统健康检查.
  @GET('/health')
  Future<HealthResponse> getHealth();

  /// Readiness Check.
  ///
  /// 就绪检查端点.
  @GET('/ready')
  Future<ReadyResponse> getReady();

  /// Liveness Check.
  ///
  /// 存活检查端点.
  @GET('/live')
  Future<LiveResponse> getLive();

  /// Root.
  ///
  /// 根路径 - 返回API信息.
  @GET('/')
  Future<ApiInfoResponse> get();

  /// Admin Login Page.
  ///
  /// 管理后台登录页面.
  @GET('/admin/login')
  Future<void> getAdminLogin();

  /// Admin Login.
  ///
  /// 处理管理后台登录.
  @FormUrlEncoded()
  @POST('/admin/login')
  Future<void> postAdminLogin({
    @Body() required BodyAdminLoginAdminLoginPost body,
  });

  /// Admin Logout.
  ///
  /// 处理管理后台登出.
  @POST('/admin/logout')
  Future<void> postAdminLogout();

  /// Admin Dashboard.
  ///
  /// 管理后台仪表板.
  @GET('/admin/')
  Future<void> getAdmin();

  /// Admin Users.
  ///
  /// 用户管理页面.
  @GET('/admin/users')
  Future<void> getAdminUsers({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 20,
  });

  /// Admin User Detail.
  ///
  /// 用户详情页面.
  @GET('/admin/users/{user_id}')
  Future<void> getAdminUsersUserId({
    @Path('user_id') required int userId,
  });

  /// Toggle User Status.
  ///
  /// 切换用户激活状态（启用/禁用）.
  @POST('/admin/users/{user_id}/toggle')
  Future<void> postAdminUsersUserIdToggle({
    @Path('user_id') required int userId,
  });

  /// Admin Messages.
  ///
  /// 消息管理页面.
  @GET('/admin/messages')
  Future<void> getAdminMessages({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 20,
  });

  /// Posters Page.
  ///
  /// 海报管理页面.
  @GET('/admin/posters')
  Future<void> getAdminPosters();

  /// Admin Services.
  ///
  /// 服务号管理页面.
  @GET('/admin/service_accounts')
  Future<void> getAdminServiceAccounts({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 20,
  });

  /// Toggle Service Status.
  ///
  /// 切换服务号激活状态.
  @POST('/admin/service_accounts/{service_id}/toggle')
  Future<void> postAdminServiceAccountsServiceIdToggle({
    @Path('service_id') required int serviceId,
  });

  /// Upload Service Avatar.
  ///
  /// 上传服务号头像.
  @MultiPart()
  @POST('/admin/service_accounts/{service_id}/avatar')
  Future<void> postAdminServiceAccountsServiceIdAvatar({
    @Path('service_id') required int serviceId,
    @Part(name: 'file') required File file,
  });

  /// Update Service Push Time.
  ///
  /// 更新服务号推送时间和描述.
  @FormUrlEncoded()
  @POST('/admin/service_accounts/{service_id}/push-time')
  Future<void> postAdminServiceAccountsServiceIdPushTime({
    @Path('service_id') required int serviceId,
    @Body() required BodyUpdateServicePushTimeAdminServiceAccountsServiceIdPushTimePost body,
  });

  /// Trigger Service Push.
  ///
  /// 立即触发服务号推送任务（无视时间和用户限制）.
  @POST('/admin/service_accounts/{service_name}/trigger-push')
  Future<void> postAdminServiceAccountsServiceNameTriggerPush({
    @Path('service_name') required String serviceName,
  });
}
