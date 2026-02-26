// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/body_admin_login_api_admin_login_post.dart';
import '../models/body_update_service_push_time_api_admin_service_accounts_service_id_push_time_post.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  /// Admin Login Page.
  ///
  /// 管理后台登录页面.
  @GET('/api/admin/login')
  Future<void> getApiAdminLogin();

  /// Admin Login.
  ///
  /// 处理管理后台登录.
  @FormUrlEncoded()
  @POST('/api/admin/login')
  Future<void> postApiAdminLogin({
    @Body() required BodyAdminLoginApiAdminLoginPost body,
  });

  /// Admin Logout.
  ///
  /// 处理管理后台登出.
  @POST('/api/admin/logout')
  Future<void> postApiAdminLogout();

  /// Admin Dashboard.
  ///
  /// 管理后台仪表板.
  @GET('/api/admin/')
  Future<void> getApiAdmin();

  /// Admin Users.
  ///
  /// 用户管理页面.
  @GET('/api/admin/users')
  Future<void> getApiAdminUsers({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 20,
  });

  /// Admin User Detail.
  ///
  /// 用户详情页面.
  @GET('/api/admin/users/{user_id}')
  Future<void> getApiAdminUsersUserId({
    @Path('user_id') required int userId,
  });

  /// Toggle User Status.
  ///
  /// 切换用户激活状态（启用/禁用）.
  @POST('/api/admin/users/{user_id}/toggle')
  Future<void> postApiAdminUsersUserIdToggle({
    @Path('user_id') required int userId,
  });

  /// Admin Messages.
  ///
  /// 消息管理页面.
  @GET('/api/admin/messages')
  Future<void> getApiAdminMessages({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 20,
  });

  /// Posters Page.
  ///
  /// 海报管理页面.
  @GET('/api/admin/posters')
  Future<void> getApiAdminPosters();

  /// Admin Services.
  ///
  /// 服务号管理页面.
  @GET('/api/admin/service_accounts')
  Future<void> getApiAdminServiceAccounts({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 20,
  });

  /// Toggle Service Status.
  ///
  /// 切换服务号激活状态.
  @POST('/api/admin/service_accounts/{service_id}/toggle')
  Future<void> postApiAdminServiceAccountsServiceIdToggle({
    @Path('service_id') required int serviceId,
  });

  /// Upload Service Avatar.
  ///
  /// 上传服务号头像.
  @MultiPart()
  @POST('/api/admin/service_accounts/{service_id}/avatar')
  Future<void> postApiAdminServiceAccountsServiceIdAvatar({
    @Path('service_id') required int serviceId,
    @Part(name: 'file') required File file,
  });

  /// Update Service Push Time.
  ///
  /// 更新服务号推送时间和描述.
  @FormUrlEncoded()
  @POST('/api/admin/service_accounts/{service_id}/push-time')
  Future<void> postApiAdminServiceAccountsServiceIdPushTime({
    @Path('service_id') required int serviceId,
    @Body() required BodyUpdateServicePushTimeApiAdminServiceAccountsServiceIdPushTimePost body,
  });

  /// Trigger Service Push.
  ///
  /// 立即触发服务号推送任务（无视时间和用户限制）.
  @POST('/api/admin/service_accounts/{service_name}/trigger-push')
  Future<void> postApiAdminServiceAccountsServiceNameTriggerPush({
    @Path('service_name') required String serviceName,
  });
  /// Admin Push Logs.
  ///
  /// 消息推送日志查看页面.
  @GET('/api/admin/push_logs')
  Future<void> getApiAdminPushLogs({
    @Query('status') String? status,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// Get Push Log Detail.
  ///
  /// 获取推送日志详情（JSON格式）.
  @GET('/api/admin/push_logs/{log_id}/detail')
  Future<void> getApiAdminPushLogsLogIdDetail({
    @Path('log_id') required int logId,
  });
}
