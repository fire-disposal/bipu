import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/friendship_model.dart';
import '../../models/message_model.dart';
import '../../models/message_ack_event.dart';
import '../../models/paginated_response.dart';
import '../../models/user_model.dart';
import '../../models/subscription_model.dart';
import '../../models/user_settings_model.dart';
part 'rest_client.g.dart';

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  // --- Auth & Users ---
  @POST('/public/login')
  Future<AuthResponse> login(@Body() Map<String, dynamic> body);

  @POST('/public/register')
  Future<User> register(@Body() Map<String, dynamic> body);

  @POST('/public/refresh')
  Future<AuthResponse> refreshToken(@Body() Map<String, dynamic> body);

  @POST('/public/logout')
  Future<void> logout();

  @GET('/client/profile/me')
  Future<User> getMe();

  @PUT('/client/profile/profile')
  Future<User> updateMe(@Body() Map<String, dynamic> body);

  @PUT('/client/profile/online-status')
  Future<void> updateOnlineStatus(@Body() Map<String, dynamic> body);

  // -- Admin Users (OpenAPI) --
  @GET('/admin/users')
  Future<PaginatedResponse<User>> adminGetUsers({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/admin/users/{user_id}')
  Future<User> adminGetUser(@Path('user_id') int userId);

  @PUT('/admin/users/{user_id}')
  Future<User> adminUpdateUser(
    @Path('user_id') int userId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/admin/users/{user_id}')
  Future<void> adminDeleteUser(@Path('user_id') int userId);

  @PUT('/admin/users/{user_id}/status')
  Future<User> adminUpdateUserStatus(
    @Path('user_id') int userId,
    @Body() Map<String, dynamic> body,
  );

  @GET('/admin/users/stats')
  Future<dynamic> adminGetUserStats();

  // --- Messages ---
  @POST('/client/messages/')
  Future<Message> createMessage(@Body() Map<String, dynamic> body);

  @GET('/client/messages/')
  Future<PaginatedResponse<Message>> getMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('message_type') String? messageType,
    @Query('status') String? status,
    @Query('is_read') bool? isRead,
    @Query('sender_id') int? senderId,
    @Query('receiver_id') int? receiverId,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  });

  @DELETE('/client/messages/batch')
  // 按 OpenAPI，批量删除需提供消息ID数组，请使用下方 batchDeleteMessages
  @GET('/client/messages/conversations/{user_id}')
  Future<PaginatedResponse<Message>> getConversationMessages(
    @Path('user_id') int userId, {
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/client/messages/unread/count')
  Future<int> getUnreadCount();

  // 公开文档未提供未读消息列表与最近消息列表端点，移除以保持一致

  @GET('/client/messages/{message_id}')
  Future<Message> getMessage(@Path('message_id') int messageId);

  @PUT('/client/messages/{message_id}')
  Future<Message> updateMessage(
    @Path('message_id') int messageId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/client/messages/{message_id}')
  Future<void> deleteMessage(@Path('message_id') int messageId);

  @POST('/client/messages/ack')
  Future<MessageAckEvent> createMessageAckEvent(
    @Body() Map<String, dynamic> body,
  );

  @GET('/client/messages/ack/message/{message_id}')
  Future<List<MessageAckEvent>> getMessageAckEvents(
    @Path('message_id') int messageId,
  );

  // 管理端消息回执未在 OpenAPI 中定义，移除

  // --- Message Management ---
  @POST('/client/messages/{id}/favorite')
  Future<void> favoriteMessage(@Path('id') int id);

  @DELETE('/client/messages/{id}/favorite')
  Future<void> unfavoriteMessage(@Path('id') int id);

  @GET('/client/messages/favorites')
  Future<PaginatedResponse<Message>> getFavoriteMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/client/messages/{id}/archive')
  Future<void> archiveMessage(@Path('id') int id);

  // Re-define getReceivedMessages/getSentMessages to support date filters if needed,
  // or overload existing ones? Retrofit doesn't support overloading with same path effectively.
  // The previous definition was:
  // @GET('/message-management/messages/received')
  // Future<PaginatedResponse<Message>> getReceivedMessages({@Query('page') int page = 1, @Query('size') int size = 20});
  // We need to update it to include date params.

  @DELETE('/client/messages/batch')
  Future<void> batchDeleteMessages(@Body() List<int> messageIds);

  @GET('/client/messages/management/stats')
  Future<dynamic> getMessageManagementStats();

  @POST('/client/messages/export')
  Future<dynamic> exportMessagesAdvanced(@Body() Map<String, dynamic> body);

  @GET('/client/messages/search')
  Future<PaginatedResponse<Message>> searchMessages({
    @Query('keyword') required String keyword,
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  // --- System Notifications ---
  // 系统通知未在 OpenAPI 中定义，移除相关端点

  @PUT('/client/messages/{id}/read')
  Future<void> markAsRead(@Path('id') int id);

  @PUT('/client/messages/read-all')
  Future<void> markAllAsRead();

  @GET('/client/messages/stats')
  Future<dynamic> getMessageStats();

  // -- Admin Messages --
  // 管理端消息列表/统计未在 OpenAPI 中定义，移除

  // --- Friendships ---
  @POST('/client/friends/')
  Future<Friendship> sendFriendRequest(@Body() Map<String, dynamic> body);

  @GET('/client/friends/')
  Future<PaginatedResponse<Friendship>> getFriendships({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
  });

  @GET('/client/friends/requests')
  Future<PaginatedResponse<Friendship>> getFriendRequests({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/client/friends/friends')
  Future<PaginatedResponse<User>> getFriends({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/client/friends/{friendship_id}/accept')
  Future<Friendship> acceptFriendRequest(
    @Path('friendship_id') int friendshipId,
  );

  @PUT('/client/friends/{friendship_id}/reject')
  Future<Friendship> rejectFriendRequest(
    @Path('friendship_id') int friendshipId,
  );

  @DELETE('/client/friends/{friendship_id}')
  Future<void> deleteFriendship(@Path('friendship_id') int friendshipId);

  @GET('/admin/friends')
  Future<PaginatedResponse<Friendship>> adminGetAllFriendships({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @DELETE('/admin/friends/{id}')
  Future<void> adminDeleteFriendship(@Path('id') int id);

  // --- Subscriptions ---
  @GET('/client/subscriptions/subscription-types')
  Future<PaginatedResponse<SubscriptionType>> getSubscriptionTypes({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('category') String? category,
    @Query('is_active') bool? isActive,
  });

  @GET('/client/subscriptions/types/{id}')
  Future<SubscriptionType> getSubscriptionType(@Path('id') int id);

  @POST('/admin/subscriptions/types')
  Future<SubscriptionType> createSubscriptionType(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/admin/subscriptions/types/{id}')
  Future<SubscriptionType> updateSubscriptionType(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/admin/subscriptions/types/{id}')
  Future<void> deleteSubscriptionType(@Path('id') int id);

  @GET('/client/subscriptions/user')
  Future<PaginatedResponse<UserSubscriptionResponse>> getUserSubscriptions({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/client/subscriptions/user/{subscriptionTypeId}')
  Future<UserSubscriptionResponse> updateUserSubscription(
    @Path('subscriptionTypeId') int subscriptionTypeId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/client/subscriptions/user/{subscriptionTypeId}')
  Future<void> unsubscribe(@Path('subscriptionTypeId') int subscriptionTypeId);

  @GET('/admin/subscriptions/stats')
  Future<dynamic> getSubscriptionStats();

  @GET('/client/subscriptions/cosmic/status')
  Future<dynamic> getCosmicMessagingStatus();

  @PUT('/client/subscriptions/cosmic/settings')
  Future<dynamic> updateCosmicMessagingSettings(
    @Body() Map<String, dynamic> body,
  );

  // --- User Settings ---
  @GET('/client/profile/profile')
  Future<UserProfile> getUserProfile();

  @PUT('/client/profile/profile')
  Future<UserProfile> updateUserProfileSettings(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/client/profile/settings')
  Future<UserProfile> updateUserSettings(@Body() Map<String, dynamic> body);

  @PUT('/client/profile/password')
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @PUT('/client/profile/terms/accept')
  Future<void> acceptTerms(@Body() Map<String, dynamic> body);

  @GET('/client/profile/terms')
  Future<dynamic> getTermsStatus();

  @POST('/client/blocks/blocks')
  Future<void> blockUser(@Body() Map<String, dynamic> body);

  @DELETE('/client/blocks/blocks/{user_id}')
  Future<void> unblockUser(@Path('user_id') int userId);

  @GET('/client/blocks/blocks')
  Future<PaginatedResponse<BlockedUser>> getBlockedUsers({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/client/profile/privacy')
  Future<PrivacySettings> getPrivacySettings();

  @PUT('/client/profile/privacy')
  Future<PrivacySettings> updatePrivacySettings(
    @Body() Map<String, dynamic> body,
  );

  @GET('/client/profile/subscription-settings')
  Future<SubscriptionSettings> getSubscriptionSettings();

  @PUT('/client/profile/subscription-settings')
  Future<SubscriptionSettings> updateSubscriptionSettings(
    @Body() Map<String, dynamic> body,
  );

  @POST('/client/messages/export')
  Future<dynamic> exportMessages(@Body() Map<String, dynamic> body);
  // 管理端日志未在 OpenAPI 中定义，移除

  // --- Health ---
  @GET('/health')
  Future<dynamic> checkHealth();

  @GET('/ready')
  Future<dynamic> checkReadiness();

  @GET('/live')
  Future<dynamic> checkLiveness();

  // --- Extra Message Methods ---
  @GET('/client/messages/')
  Future<PaginatedResponse<Message>> getReceivedMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('receiver_id') int? receiverId,
  });

  @GET('/client/messages/')
  Future<PaginatedResponse<Message>> getSentMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('sender_id') int? senderId,
  });

  // --- Client Subscriptions (OpenAPI) ---
  @GET('/client/subscriptions/available')
  Future<PaginatedResponse<SubscriptionTypeResponse>>
  getAvailableSubscriptionTypes({
    @Query('category') String? category,
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/client/subscriptions/my')
  Future<PaginatedResponse<MySubscriptionItem>> getMySubscriptions({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @POST('/client/subscriptions/{subscription_type_id}/subscribe')
  Future<SubscribeResponse> subscribe(
    @Path('subscription_type_id') int subscriptionTypeId,
    @Body() SubscribeRequest body,
  );

  @POST('/client/subscriptions/{subscription_type_id}/unsubscribe')
  Future<SubscribeResponse> unsubscribeClient(
    @Path('subscription_type_id') int subscriptionTypeId,
  );

  @PUT('/client/subscriptions/{subscription_type_id}/settings')
  Future<UserSubscriptionModelResponse> updateSubscriptionSettingsByType(
    @Path('subscription_type_id') int subscriptionTypeId,
    @Body() UserSubscriptionUpdate body,
  );

  // --- Admin Subscriptions (OpenAPI) ---
  @GET('/admin/subscriptions/subscription-types')
  Future<PaginatedResponse<SubscriptionTypeDetailResponse>>
  adminGetSubscriptionTypes({
    @Query('category') String? category,
    @Query('is_active') bool? isActive,
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @POST('/admin/subscriptions/subscription-types')
  Future<SubscriptionTypeResponse> adminCreateSubscriptionType(
    @Body() Map<String, dynamic> body,
  );

  @GET('/admin/subscriptions/subscription-types/{subscription_type_id}')
  Future<SubscriptionTypeDetailResponse> adminGetSubscriptionType(
    @Path('subscription_type_id') int subscriptionTypeId,
  );

  @PUT('/admin/subscriptions/subscription-types/{subscription_type_id}')
  Future<SubscriptionTypeResponse> adminUpdateSubscriptionType(
    @Path('subscription_type_id') int subscriptionTypeId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/admin/subscriptions/subscription-types/{subscription_type_id}')
  Future<void> adminDeleteSubscriptionType(
    @Path('subscription_type_id') int subscriptionTypeId,
  );

  @PUT('/admin/subscriptions/subscription-types/{subscription_type_id}/status')
  Future<SubscriptionTypeResponse> adminUpdateSubscriptionTypeStatus(
    @Path('subscription_type_id') int subscriptionTypeId,
    @Body() Map<String, dynamic> body,
  );

  @GET('/admin/subscriptions/subscription-types/{subscription_type_id}/count')
  Future<SubscriptionCountResponse> adminGetSubscriptionTypeCount(
    @Path('subscription_type_id') int subscriptionTypeId,
  );

  @GET(
    '/admin/subscriptions/subscription-types/{subscription_type_id}/subscribers',
  )
  Future<PaginatedResponse<SubscriberItem>> adminGetSubscribers(
    @Path('subscription_type_id') int subscriptionTypeId, {
    @Query('is_enabled') bool? isEnabled,
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/admin/subscriptions/stats/overview')
  Future<SubscriptionOverviewResponse> adminGetSubscriptionOverview();
}
