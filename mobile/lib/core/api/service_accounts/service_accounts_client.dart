// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/service_account_list.dart';
import '../models/service_account_response.dart';
import '../models/subscription_settings_response.dart';
import '../models/subscription_settings_update.dart';
import '../models/user_subscription_list.dart';

part 'service_accounts_client.g.dart';

@RestApi()
abstract class ServiceAccountsClient {
  factory ServiceAccountsClient(Dio dio, {String? baseUrl}) = _ServiceAccountsClient;

  /// List Service Accounts.
  ///
  /// 获取所有活跃的服务号列表.
  ///
  /// 参数：.
  /// - skip: 跳过的记录数，用于分页.
  /// - limit: 每页返回的记录数，最大100.
  ///
  /// 返回：.
  /// - items: 服务号列表.
  /// - total: 活跃服务号总数.
  ///
  /// 注意：只返回 is_active=True 的服务号.
  @GET('/api/service_accounts/')
  Future<ServiceAccountList> getApiServiceAccounts({
    @Query('skip') int? skip = 0,
    @Query('limit') int? limit = 100,
  });

  /// Get Service Account.
  ///
  /// 获取指定服务号详情.
  ///
  /// 参数：.
  /// - name: 服务号名称.
  ///
  /// 返回：.
  /// - 成功：返回服务号详细信息.
  /// - 失败：404（服务号不存在）.
  ///
  /// 注意：需要用户认证.
  @GET('/api/service_accounts/{name}')
  Future<ServiceAccountResponse> getApiServiceAccountsName({
    @Path('name') required String name,
  });

  /// Get Service Avatar.
  ///
  /// 获取服务号头像.
  ///
  /// 参数：.
  /// - name: 服务号名称.
  ///
  /// 特性：.
  /// - 支持ETag缓存，减少带宽消耗.
  /// - 支持HTTP 304 Not Modified响应.
  /// - 头像数据缓存24小时.
  ///
  /// 返回：.
  /// - 成功：返回JPEG格式的头像图片.
  /// - 失败：404（服务号或头像不存在）.
  @GET('/api/service_accounts/{name}/avatar')
  Future<void> getApiServiceAccountsNameAvatar({
    @Path('name') required String name,
  });

  /// Get User Subscriptions.
  ///
  /// 获取当前用户订阅的所有服务号列表.
  ///
  /// 返回：.
  /// - subscriptions: 订阅的服务号列表，包含服务信息和订阅设置.
  /// - total: 订阅的服务号总数.
  ///
  /// 包含信息：.
  /// - 服务号基本信息（名称、描述、头像等）.
  /// - 订阅设置（推送时间、启用状态、订阅时间等）.
  ///
  /// 注意：需要用户认证.
  @GET('/api/service_accounts/subscriptions/')
  Future<UserSubscriptionList> getApiServiceAccountsSubscriptions();

  /// Get Subscription Settings.
  ///
  /// 获取指定服务号的订阅设置.
  ///
  /// 参数：.
  /// - name: 服务号名称.
  ///
  /// 返回：.
  /// - 成功：返回该服务号的订阅设置详情.
  /// - 失败：404（服务号不存在或未订阅）.
  ///
  /// 包含信息：.
  /// - 服务号基本信息.
  /// - 推送时间设置及来源.
  /// - 订阅启用状态.
  /// - 订阅时间戳.
  ///
  /// 注意：需要用户认证且已订阅该服务号.
  @GET('/api/service_accounts/{name}/settings')
  Future<SubscriptionSettingsResponse> getApiServiceAccountsNameSettings({
    @Path('name') required String name,
  });

  /// Update Subscription Settings.
  ///
  /// 更新服务号订阅设置.
  ///
  /// 参数：.
  /// - name: 服务号名称.
  /// - push_time: 推送时间（HH:MM格式），可选.
  /// - is_enabled: 是否启用推送，可选.
  ///
  /// 返回：.
  /// - 成功：返回更新后的订阅设置.
  /// - 失败：404（服务号不存在或未订阅）或400（时间格式无效）.
  ///
  /// 注意：.
  /// - 需要用户认证且已订阅该服务号.
  /// - 推送时间格式必须为 HH:MM（24小时制）.
  /// - 如果只更新部分字段，其他字段保持不变.
  /// - 设置 push_time=null 可清除个人化设置，恢复使用默认时间.
  @PUT('/api/service_accounts/{name}/settings')
  Future<SubscriptionSettingsResponse> putApiServiceAccountsNameSettings({
    @Path('name') required String name,
    @Body() required SubscriptionSettingsUpdate body,
  });

  /// Subscribe Service Account.
  ///
  /// 订阅服务号.
  ///
  /// 参数：.
  /// - name: 要订阅的服务号名称.
  /// - push_time: 初始推送时间（HH:MM格式），可选.
  /// - is_enabled: 初始启用状态，可选，默认为True.
  ///
  /// 返回：.
  /// - 成功：返回订阅成功信息.
  /// - 失败：404（服务号不存在）或400（已订阅）或500（数据库操作失败）.
  ///
  /// 注意：.
  /// - 需要用户认证.
  /// - 只能订阅 is_active=True 的服务号.
  /// - 推送时间格式必须为 HH:MM（24小时制）.
  /// - 如果未提供推送时间，使用服务号默认推送时间.
  @POST('/api/service_accounts/{name}/subscribe')
  Future<void> postApiServiceAccountsNameSubscribe({
    @Path('name') required String name,
    @Body() SubscriptionSettingsUpdate? body,
  });

  /// Unsubscribe Service Account.
  ///
  /// 取消订阅服务号.
  ///
  /// 参数：.
  /// - name: 要取消订阅的服务号名称.
  ///
  /// 返回：.
  /// - 成功：返回取消订阅成功信息.
  /// - 失败：404（服务号不存在）或400（未订阅）或500（数据库操作失败）.
  ///
  /// 注意：.
  /// - 需要用户认证.
  /// - 取消订阅后，该服务号的推送将停止.
  /// - 订阅记录将被删除，相关设置不会保留.
  @DELETE('/api/service_accounts/{name}/subscribe')
  Future<void> deleteApiServiceAccountsNameSubscribe({
    @Path('name') required String name,
  });
}
