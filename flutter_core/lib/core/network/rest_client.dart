import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/friendship_model.dart';
import '../../models/message_model.dart';
import '../../models/message_ack_event.dart'; // Add this
import '../../models/paginated_response.dart';
import '../../models/user_model.dart';
import '../../models/subscription_model.dart'; // Add
import '../../models/user_settings_model.dart'; // Add
import '../../models/admin_log_model.dart'; // Add
part 'rest_client.g.dart';

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  // --- Auth & Users ---
  @POST('/api/public/login')
  Future<AuthResponse> login(@Body() Map<String, dynamic> body);

  @POST('/api/public/register')
  Future<User> register(@Body() Map<String, dynamic> body);

  @POST('/api/public/refresh')
  Future<AuthResponse> refreshToken(@Body() Map<String, dynamic> body);

  @POST('/api/public/logout')
  Future<void> logout();

  @GET('/api/client/profile/me')
  Future<User> getMe();

  @PUT('/api/client/profile/profile')
  Future<User> updateMe(@Body() Map<String, dynamic> body);

  @GET('/users')
  Future<PaginatedResponse<User>> getUsers({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('search') String? search,
  });

  @GET('/users/{id}')
  Future<User> getUserDetails(@Path('id') int id);

  @PUT('/users/{id}')
  Future<User> updateUser(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/users/{id}')
  Future<void> deleteUser(@Path('id') int id);

  @PUT('/users/profile')
  Future<User> updateProfile(@Body() Map<String, dynamic> body);

  @PUT('/api/client/profile/online-status')
  Future<void> updateOnlineStatus(@Body() Map<String, dynamic> body);

  @GET('/users/online-status')
  Future<dynamic> getOnlineStatus(@Query('user_ids') List<int> userIds);

  // -- Admin Users --
  @GET('/users/admin/all')
  Future<PaginatedResponse<User>> adminGetAllUsers({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('search') String? search,
    @Query('role') String? role,
    @Query('is_active') bool? isActive,
  });

  @PUT('/users/admin/{id}/status')
  Future<User> adminUpdateUserStatus(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  // --- Messages ---
  @POST('/api/client/messages/')
  Future<Message> createMessage(@Body() Map<String, dynamic> body);

  @GET('/api/client/messages/')
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

  @DELETE('/api/client/messages/batch')
  Future<void> deleteReadMessages();

  @GET('/api/client/messages/conversations/{userId}')
  Future<PaginatedResponse<Message>> getConversationMessages(
    @Path('userId') int userId, {
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/api/client/messages/unread/count')
  Future<int> getUnreadCount();

  @GET('/api/client/messages/')
  Future<PaginatedResponse<Message>> getUnreadMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('is_read') bool? isRead = false,
  });

  @GET('/api/client/messages/')
  Future<List<Message>> getRecentMessages({@Query('limit') int limit = 10});

  @GET('/api/client/messages/{id}')
  Future<Message> getMessage(@Path('id') int id);

  @PUT('/api/client/messages/{id}')
  Future<Message> updateMessage(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/client/messages/{id}')
  Future<void> deleteMessage(@Path('id') int id);

  @POST('/api/client/messages/ack')
  Future<MessageAckEvent> createMessageAckEvent(
    @Body() Map<String, dynamic> body,
  );

  @GET('/api/client/messages/ack/message/{messageId}')
  Future<List<MessageAckEvent>> getMessageAckEvents(
    @Path('messageId') int messageId,
  );

  @GET('/api/admin/messages/ack')
  Future<PaginatedResponse<MessageAckEvent>> getAllAckEvents({
    @Query('page') int page = 1,
    @Query('size') int size = 100,
  });

  @GET('/api/admin/messages/ack/stats')
  Future<dynamic> getAckStats();

  // --- Message Management ---
  @POST('/api/client/messages/{id}/favorite')
  Future<void> favoriteMessage(@Path('id') int id);

  @DELETE('/api/client/messages/{id}/favorite')
  Future<void> unfavoriteMessage(@Path('id') int id);

  @GET('/api/client/messages/favorites')
  Future<PaginatedResponse<Message>> getFavoriteMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/api/client/messages/{id}/archive')
  Future<void> archiveMessage(@Path('id') int id);

  // Re-define getReceivedMessages/getSentMessages to support date filters if needed,
  // or overload existing ones? Retrofit doesn't support overloading with same path effectively.
  // The previous definition was:
  // @GET('/message-management/messages/received')
  // Future<PaginatedResponse<Message>> getReceivedMessages({@Query('page') int page = 1, @Query('size') int size = 20});
  // We need to update it to include date params.

  @DELETE('/api/client/messages/batch')
  Future<void> batchDeleteMessages(@Body() Map<String, dynamic> body);

  @GET('/api/client/messages/management/stats')
  Future<dynamic> getMessageManagementStats();

  @POST('/api/client/messages/export')
  Future<dynamic> exportMessagesAdvanced(@Body() Map<String, dynamic> body);

  @GET('/api/client/messages/search') // 假设存在搜索端点
  Future<PaginatedResponse<Message>> searchMessages({
    @Query('q') String? query,
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  // --- System Notifications ---
  @POST('/api/client/system-notifications')
  Future<Message> createSystemNotification(@Body() Map<String, dynamic> body);

  @GET('/api/client/system-notifications')
  Future<PaginatedResponse<Message>> getSystemNotifications({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
    @Query('priority_min') int? priorityMin,
    @Query('priority_max') int? priorityMax,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
  });

  @GET('/api/client/system-notifications/{id}')
  Future<Message> getSystemNotification(@Path('id') int id);

  @PUT('/api/client/system-notifications/{id}/read')
  Future<void> markSystemNotificationAsRead(@Path('id') int id);

  @PUT('/api/client/system-notifications/read-all')
  Future<void> markAllSystemNotificationsAsRead();

  @DELETE('/api/client/system-notifications/{id}')
  Future<void> deleteSystemNotification(@Path('id') int id);

  @GET('/api/admin/system-notifications')
  Future<PaginatedResponse<Message>> adminGetAllSystemNotifications({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
    @Query('priority_min') int? priorityMin,
    @Query('priority_max') int? priorityMax,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
  });

  @DELETE('/api/admin/system-notifications/{id}')
  Future<void> adminDeleteSystemNotification(@Path('id') int id);

  @GET('/api/client/system-notifications/stats')
  Future<dynamic> getSystemNotificationStats();

  @GET('/api/admin/system-notifications/stats')
  Future<dynamic> adminGetSystemNotificationStats();

  @PUT('/api/client/messages/{id}/read')
  Future<void> markAsRead(@Path('id') int id);

  @PUT('/api/client/messages/read-all')
  Future<void> markAllAsRead();

  @GET('/api/client/messages/stats')
  Future<dynamic> getMessageStats();

  // -- Admin Messages --
  @GET('/api/admin/messages')
  Future<PaginatedResponse<Message>> adminGetAllMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @DELETE('/api/admin/messages/{id}')
  Future<void> adminDeleteMessage(@Path('id') int id);

  @GET('/api/admin/messages/stats')
  Future<dynamic> adminGetMessageStats();

  // --- Friendships ---
  @POST('/api/client/friends')
  Future<Friendship> sendFriendRequest(@Body() Map<String, dynamic> body);

  @GET('/api/client/friends')
  Future<PaginatedResponse<Friendship>> getFriendships({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
  });

  @GET('/api/client/friends/requests')
  Future<PaginatedResponse<Friendship>> getFriendRequests({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/api/client/friends/friends')
  Future<PaginatedResponse<User>> getFriends({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/api/client/friends/{id}/accept')
  Future<Friendship> acceptFriendRequest(@Path('id') int id);

  @PUT('/api/client/friends/{id}/reject')
  Future<Friendship> rejectFriendRequest(@Path('id') int id);

  @DELETE('/api/client/friends/{id}')
  Future<void> deleteFriendship(@Path('id') int id);

  @GET('/api/admin/friends')
  Future<PaginatedResponse<Friendship>> adminGetAllFriendships({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @DELETE('/api/admin/friends/{id}')
  Future<void> adminDeleteFriendship(@Path('id') int id);

  // --- Subscriptions ---
  @GET('/api/client/subscriptions/subscription-types')
  Future<PaginatedResponse<SubscriptionType>> getSubscriptionTypes({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('category') String? category,
    @Query('is_active') bool? isActive,
  });

  @GET('/api/client/subscriptions/types/{id}')
  Future<SubscriptionType> getSubscriptionType(@Path('id') int id);

  @POST('/api/admin/subscriptions/types')
  Future<SubscriptionType> createSubscriptionType(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/api/admin/subscriptions/types/{id}')
  Future<SubscriptionType> updateSubscriptionType(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/admin/subscriptions/types/{id}')
  Future<void> deleteSubscriptionType(@Path('id') int id);

  @GET('/api/client/subscriptions/user')
  Future<PaginatedResponse<UserSubscriptionResponse>> getUserSubscriptions({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/api/client/subscriptions/user/{subscriptionTypeId}')
  Future<UserSubscriptionResponse> updateUserSubscription(
    @Path('subscriptionTypeId') int subscriptionTypeId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/client/subscriptions/user/{subscriptionTypeId}')
  Future<void> unsubscribe(@Path('subscriptionTypeId') int subscriptionTypeId);

  @GET('/api/admin/subscriptions/stats')
  Future<dynamic> getSubscriptionStats();

  @GET('/api/client/subscriptions/cosmic/status')
  Future<dynamic> getCosmicMessagingStatus();

  @PUT('/api/client/subscriptions/cosmic/settings')
  Future<dynamic> updateCosmicMessagingSettings(
    @Body() Map<String, dynamic> body,
  );

  // --- User Settings ---
  @GET('/api/client/profile/profile')
  Future<UserProfile> getUserProfile();

  @PUT('/api/client/profile/profile')
  Future<UserProfile> updateUserProfileSettings(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/api/client/profile/settings')
  Future<UserProfile> updateUserSettings(@Body() Map<String, dynamic> body);

  @PUT('/api/client/profile/password')
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @PUT('/api/client/profile/terms/accept')
  Future<void> acceptTerms(@Body() Map<String, dynamic> body);

  @GET('/api/client/profile/terms')
  Future<dynamic> getTermsStatus();

  @POST('/api/client/blocks')
  Future<void> blockUser(@Body() Map<String, dynamic> body);

  @DELETE('/api/client/blocks/{userId}')
  Future<void> unblockUser(@Path('userId') int userId);

  @GET('/api/client/blocks')
  Future<PaginatedResponse<BlockedUser>> getBlockedUsers({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/api/client/profile/privacy')
  Future<PrivacySettings> getPrivacySettings();

  @PUT('/api/client/profile/privacy')
  Future<PrivacySettings> updatePrivacySettings(
    @Body() Map<String, dynamic> body,
  );

  @GET('/api/client/profile/subscription-settings')
  Future<SubscriptionSettings> getSubscriptionSettings();

  @PUT('/api/client/profile/subscription-settings')
  Future<SubscriptionSettings> updateSubscriptionSettings(
    @Body() Map<String, dynamic> body,
  );

  @POST('/api/client/messages/export')
  Future<dynamic> exportMessages(@Body() Map<String, dynamic> body);

  // --- Admin Logs ---
  @GET('/api/admin/logs')
  Future<PaginatedResponse<AdminLog>> getAdminLogs({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/api/admin/logs/{id}')
  Future<AdminLog> getAdminLog(@Path('id') int id);

  @DELETE('/api/admin/logs/{id}')
  Future<void> deleteAdminLog(@Path('id') int id);

  @GET('/api/admin/logs/stats')
  Future<dynamic> getAdminLogStats();

  // --- Health ---
  @GET('/api/health')
  Future<dynamic> checkHealth();

  @GET('/api/ready')
  Future<dynamic> checkReadiness();

  @GET('/api/live')
  Future<dynamic> checkLiveness();

  // --- Extra Message Methods ---
  @GET('/api/client/messages/')
  Future<PaginatedResponse<Message>> getReceivedMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('receiver_id') int? receiverId,
  });

  @GET('/api/client/messages/')
  Future<PaginatedResponse<Message>> getSentMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('sender_id') int? senderId,
  });
}
