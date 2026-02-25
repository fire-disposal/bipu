import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_client.g.dart';

/// API 客户端定义
/// 基于后端真实 API 路由定义
@RestApi(baseUrl: '')
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  /// ==================== 系统 API ====================

  /// 健康检查
  @GET('/health')
  Future<HttpResponse<dynamic>> healthCheck();

  /// 就绪检查
  @GET('/ready')
  Future<HttpResponse<dynamic>> readinessCheck();

  /// 存活检查
  @GET('/live')
  Future<HttpResponse<dynamic>> livenessCheck();

  /// 根路径 API 信息
  @GET('/')
  Future<HttpResponse<dynamic>> getApiInfo();

  /// ==================== 认证 API ====================

  /// 用户注册
  @POST('/api/public/register')
  Future<HttpResponse<dynamic>> register(@Body() Map<String, dynamic> data);

  /// 用户登录
  @POST('/api/public/login')
  Future<HttpResponse<dynamic>> login(@Body() Map<String, dynamic> data);

  /// 刷新令牌
  @POST('/api/public/refresh')
  Future<HttpResponse<dynamic>> refreshToken(@Body() Map<String, dynamic> data);

  /// 用户登出
  @POST('/api/public/logout')
  Future<HttpResponse<dynamic>> logout();

  /// ==================== 消息 API ====================

  /// 发送消息
  ///
  /// 支持普通消息和语音消息（带 waveform 数据）
  @POST('/api/messages/')
  Future<HttpResponse<dynamic>> sendMessage(@Body() Map<String, dynamic> data);

  /// 获取消息列表
  /// direction: "sent" 或 "received" (默认)
  @GET('/api/messages/')
  Future<HttpResponse<dynamic>> getMessages({
    @Query('direction') String? direction,
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  /// 长轮询获取新消息
  ///
  /// 参数：
  /// - lastMsgId: 最后收到的消息 ID，初始为 0
  /// - timeout: 超时时间（秒），默认 30，最大 120
  ///
  /// 响应：新消息数组
  @GET('/api/messages/poll')
  Future<HttpResponse<dynamic>> pollMessages({
    @Query('last_msg_id') required int lastMsgId,
    @Query('timeout') int? timeout,
  });

  /// 获取收藏消息列表
  @GET('/api/messages/favorites')
  Future<HttpResponse<dynamic>> getFavorites({
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  /// 收藏消息
  @POST('/api/messages/{message_id}/favorite')
  Future<HttpResponse<dynamic>> addFavorite(
    @Path('message_id') int messageId,
    @Body() Map<String, dynamic>? data,
  );

  /// 取消收藏
  @DELETE('/api/messages/{message_id}/favorite')
  Future<void> removeFavorite(@Path('message_id') int messageId);

  /// 删除消息
  @DELETE('/api/messages/{message_id}')
  Future<void> deleteMessage(@Path('message_id') int messageId);

  /// ==================== 用户 API ====================

  /// 获取当前用户信息
  @GET('/api/profile/me')
  Future<HttpResponse<dynamic>> getCurrentUser();

  /// 获取用户详细资料
  @GET('/api/profile/')
  Future<HttpResponse<dynamic>> getUserProfile();

  /// 更新用户信息
  @PUT('/api/profile/')
  Future<HttpResponse<dynamic>> updateUserProfile(
    @Body() Map<String, dynamic> data,
  );

  /// 更新用户密码
  @PUT('/api/profile/password')
  Future<HttpResponse<dynamic>> updatePassword(
    @Body() Map<String, dynamic> data,
  );

  /// 更新用户时区
  @PUT('/api/profile/timezone')
  Future<HttpResponse<dynamic>> updateTimezone(
    @Body() Map<String, dynamic> data,
  );

  /// 获取用户推送设置
  @GET('/api/profile/push-settings')
  Future<HttpResponse<dynamic>> getPushSettings();

  /// 上传头像
  @POST('/api/profile/avatar')
  @MultiPart()
  Future<HttpResponse<dynamic>> uploadAvatar(@Part() MultipartFile file);

  /// ==================== 黑名单 API ====================

  /// 获取黑名单列表
  @GET('/api/blocks')
  Future<HttpResponse<dynamic>> getBlockedUsers({
    @Query('page') int? page,
    @Query('size') int? size,
  });

  /// 拉黑用户
  @POST('/api/blocks')
  Future<HttpResponse<dynamic>> blockUser(@Body() Map<String, dynamic> data);

  /// 取消拉黑用户
  @DELETE('/api/blocks/{bipupu_id}')
  Future<HttpResponse<dynamic>> unblockUser(@Path('bipupu_id') String bipupuId);

  /// ==================== 联系人 API ====================

  /// 获取联系人列表
  @GET('/api/contacts')
  Future<HttpResponse<dynamic>> getContacts({
    @Query('page') int? page,
    @Query('size') int? size,
  });

  /// 添加联系人
  @POST('/api/contacts')
  Future<HttpResponse<dynamic>> addContact(@Body() Map<String, dynamic> data);

  /// 删除联系人
  @DELETE('/api/contacts/{contact_bipupu_id}')
  Future<void> deleteContact(@Path('contact_bipupu_id') String contactBipupuId);

  /// 更新联系人备注
  @PUT('/api/contacts/{contact_bipupu_id}')
  Future<HttpResponse<dynamic>> updateContact(
    @Path('contact_bipupu_id') String contactBipupuId,
    @Body() Map<String, dynamic> data,
  );

  /// ==================== 服务号 API ====================

  /// 获取所有活跃服务号列表
  @GET('/api/service_accounts/')
  Future<HttpResponse<dynamic>> getServiceAccounts({
    @Query('skip') int? skip,
    @Query('limit') int? limit,
  });

  /// 获取特定服务号信息
  @GET('/api/service_accounts/{name}')
  Future<HttpResponse<dynamic>> getServiceAccount(
    @Path('name') String serviceName,
  );

  /// 获取服务号头像
  @GET('/api/service_accounts/{name}/avatar')
  Future<HttpResponse<dynamic>> getServiceAccountAvatar(
    @Path('name') String serviceName,
  );

  /// 获取用户订阅的服务号列表
  @GET('/api/service_accounts/subscriptions')
  Future<HttpResponse<dynamic>> getUserSubscriptions();

  /// 获取特定服务号的订阅设置
  @GET('/api/service_accounts/{name}/settings')
  Future<HttpResponse<dynamic>> getSubscriptionSettings(
    @Path('name') String serviceName,
  );

  /// 更新服务号订阅设置
  @PUT('/api/service_accounts/{name}/settings')
  Future<HttpResponse<dynamic>> updateSubscriptionSettings(
    @Path('name') String serviceName,
    @Body() Map<String, dynamic> data,
  );

  /// 订阅服务号
  @POST('/api/service_accounts/{name}/subscribe')
  Future<HttpResponse<dynamic>> subscribeServiceAccount(
    @Path('name') String serviceName,
    @Body() Map<String, dynamic>? data,
  );

  /// 取消订阅服务号
  @DELETE('/api/service_accounts/{name}/unsubscribe')
  Future<void> unsubscribeServiceAccount(@Path('name') String serviceName);

  /// ==================== 用户查询 API ====================

  /// 通过 bipupu_id 获取用户信息
  @GET('/api/users/{bipupu_id}')
  Future<HttpResponse<dynamic>> getUserByBipupuId(
    @Path('bipupu_id') String bipupuId,
  );

  /// ==================== 海报 API ====================

  /// 获取激活的海报列表（前端轮播用）
  @GET('/api/posters/active')
  Future<HttpResponse<dynamic>> getActivePosters({@Query('limit') int? limit});

  /// 获取海报列表（管理用）
  @GET('/api/posters/')
  Future<HttpResponse<dynamic>> getPosters({
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  /// 获取单个海报详情
  @GET('/api/posters/{poster_id}')
  Future<HttpResponse<dynamic>> getPoster(@Path('poster_id') int posterId);

  /// 获取海报图片（二进制格式，直接用于img标签）
  @GET('/api/posters/{poster_id}/image')
  Future<HttpResponse<dynamic>> getPosterImage(@Path('poster_id') int posterId);
}
