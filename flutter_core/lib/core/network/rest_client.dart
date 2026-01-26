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
  @POST('/users/login')
  Future<AuthResponse> login(@Body() Map<String, dynamic> body);

  @POST('/users/register')
  Future<User> register(@Body() Map<String, dynamic> body);

  @POST('/users/refresh')
  Future<AuthResponse> refreshToken(@Body() Map<String, dynamic> body);

  @POST('/users/logout')
  Future<void> logout();

  @GET('/users/me')
  Future<User> getMe();

  @PUT('/users/me')
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

  @PUT('/users/online-status')
  Future<void> updateOnlineStatus(@Query('is_online') bool isOnline);

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
  @POST('/messages')
  Future<Message> createMessage(@Body() Map<String, dynamic> body);

  @GET('/messages')
  Future<PaginatedResponse<Message>> getMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('message_type') String? messageType,
    @Query('status') String? status,
    @Query('is_read') bool? isRead,
    @Query('sender_id') int? senderId,
    @Query('receiver_id') int? receiverId,
  });

  @DELETE('/messages')
  Future<void> deleteReadMessages();

  @GET('/messages/conversations/{userId}')
  Future<PaginatedResponse<Message>> getConversationMessages(
    @Path('userId') int userId, {
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/messages/unread/count')
  Future<dynamic> getUnreadCount();

  @GET('/messages/unread')
  Future<PaginatedResponse<Message>> getUnreadMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/messages/recent')
  Future<List<Message>> getRecentMessages({@Query('limit') int limit = 10});

  @GET('/messages/{id}')
  Future<Message> getMessage(@Path('id') int id);

  @PUT('/messages/{id}')
  Future<Message> updateMessage(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/messages/{id}')
  Future<void> deleteMessage(@Path('id') int id);

  @POST('/message-ack')
  Future<MessageAckEvent> createMessageAckEvent(
    @Body() Map<String, dynamic> body,
  );

  @GET('/message-ack/message/{messageId}')
  Future<List<MessageAckEvent>> getMessageAckEvents(
    @Path('messageId') int messageId,
  );

  @GET('/message-ack/admin/all')
  Future<PaginatedResponse<MessageAckEvent>> getAllAckEvents({
    @Query('page') int page = 1,
    @Query('size') int size = 100,
  });

  @GET('/message-ack/admin/stats')
  Future<dynamic> getAckStats();

  // --- Message Management ---
  @POST('/message-management/messages/{id}/favorite')
  Future<void> favoriteMessage(@Path('id') int id);

  @DELETE('/message-management/messages/{id}/favorite')
  Future<void> unfavoriteMessage(@Path('id') int id);

  @GET('/message-management/messages/favorites')
  Future<PaginatedResponse<Message>> getFavoriteMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/message-management/messages/{id}/archive')
  Future<void> archiveMessage(@Path('id') int id);

  // Re-define getReceivedMessages/getSentMessages to support date filters if needed,
  // or overload existing ones? Retrofit doesn't support overloading with same path effectively.
  // The previous definition was:
  // @GET('/message-management/messages/received')
  // Future<PaginatedResponse<Message>> getReceivedMessages({@Query('page') int page = 1, @Query('size') int size = 20});
  // We need to update it to include date params.

  @DELETE('/message-management/messages/batch')
  Future<void> batchDeleteMessages(@Body() Map<String, dynamic> body);

  @GET('/message-management/messages/stats')
  Future<dynamic> getMessageManagementStats();

  @POST('/message-management/messages/export')
  Future<dynamic> exportMessagesAdvanced(@Body() Map<String, dynamic> body);

  @GET(
    '/message-management/messages/search',
  ) // Assuming this exists based on ApiEndpoints
  Future<PaginatedResponse<Message>> searchMessages({
    @Query('q') String? query,
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  // --- System Notifications ---
  @POST('/system-notifications')
  Future<Message> createSystemNotification(@Body() Map<String, dynamic> body);

  @GET('/system-notifications')
  Future<PaginatedResponse<Message>> getSystemNotifications({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
    @Query('priority_min') int? priorityMin,
    @Query('priority_max') int? priorityMax,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
  });

  @GET('/system-notifications/{id}')
  Future<Message> getSystemNotification(@Path('id') int id);

  @PUT('/system-notifications/{id}/read')
  Future<void> markSystemNotificationAsRead(@Path('id') int id);

  @PUT('/system-notifications/read-all')
  Future<void> markAllSystemNotificationsAsRead();

  @DELETE('/system-notifications/{id}')
  Future<void> deleteSystemNotification(@Path('id') int id);

  @GET('/system-notifications/admin/all')
  Future<PaginatedResponse<Message>> adminGetAllSystemNotifications({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
    @Query('priority_min') int? priorityMin,
    @Query('priority_max') int? priorityMax,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
  });

  @DELETE('/system-notifications/admin/{id}')
  Future<void> adminDeleteSystemNotification(@Path('id') int id);

  @GET('/system-notifications/stats')
  Future<dynamic> getSystemNotificationStats();

  @GET('/system-notifications/admin/stats')
  Future<dynamic> adminGetSystemNotificationStats();

  @PUT('/messages/{id}/read')
  Future<void> markAsRead(@Path('id') int id);

  @PUT('/messages/read-all')
  Future<void> markAllAsRead();

  @GET('/messages/stats')
  Future<dynamic> getMessageStats();

  // -- Admin Messages --
  @GET('/messages/admin/all')
  Future<PaginatedResponse<Message>> adminGetAllMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @DELETE('/messages/admin/{id}')
  Future<void> adminDeleteMessage(@Path('id') int id);

  @GET('/messages/admin/stats')
  Future<dynamic> adminGetMessageStats();

  // --- Friendships ---
  @POST('/friendships')
  Future<Friendship> sendFriendRequest(@Body() Map<String, dynamic> body);

  @GET('/friendships')
  Future<PaginatedResponse<Friendship>> getFriendships({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('status') String? status,
  });

  @GET('/friendships/requests')
  Future<PaginatedResponse<Friendship>> getFriendRequests({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/friendships/friends')
  Future<PaginatedResponse<User>> getFriends({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/friendships/{id}/accept')
  Future<Friendship> acceptFriendRequest(@Path('id') int id);

  @PUT('/friendships/{id}/reject')
  Future<Friendship> rejectFriendRequest(@Path('id') int id);

  @DELETE('/friendships/{id}')
  Future<void> deleteFriendship(@Path('id') int id);

  @GET('/friendships/admin/all')
  Future<PaginatedResponse<Friendship>> adminGetAllFriendships({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @DELETE('/friendships/admin/{id}')
  Future<void> adminDeleteFriendship(@Path('id') int id);

  // --- Subscriptions ---
  @GET('/subscriptions/types')
  Future<PaginatedResponse<SubscriptionType>> getSubscriptionTypes({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('category') String? category,
    @Query('is_active') bool? isActive,
  });

  @GET('/subscriptions/types/{id}')
  Future<SubscriptionType> getSubscriptionType(@Path('id') int id);

  @POST('/subscriptions/types')
  Future<SubscriptionType> createSubscriptionType(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/subscriptions/types/{id}')
  Future<SubscriptionType> updateSubscriptionType(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/subscriptions/types/{id}')
  Future<void> deleteSubscriptionType(@Path('id') int id);

  @GET('/subscriptions/user')
  Future<PaginatedResponse<UserSubscriptionResponse>> getUserSubscriptions({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @PUT('/subscriptions/user/{subscriptionTypeId}')
  Future<UserSubscriptionResponse> updateUserSubscription(
    @Path('subscriptionTypeId') int subscriptionTypeId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/subscriptions/user/{subscriptionTypeId}')
  Future<void> unsubscribe(@Path('subscriptionTypeId') int subscriptionTypeId);

  @GET('/subscriptions/stats')
  Future<dynamic> getSubscriptionStats();

  @GET('/subscriptions/cosmic/status')
  Future<dynamic> getCosmicMessagingStatus();

  @PUT('/subscriptions/cosmic/settings')
  Future<dynamic> updateCosmicMessagingSettings(
    @Body() Map<String, dynamic> body,
  );

  // --- User Settings ---
  @GET('/users/profile')
  Future<UserProfile> getUserProfile();

  @PUT('/users/profile/settings')
  Future<UserProfile> updateUserProfileSettings(
    @Body() Map<String, dynamic> body,
  );

  @PUT('/users/settings')
  Future<UserProfile> updateUserSettings(@Body() Map<String, dynamic> body);

  @PUT('/users/password')
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @PUT('/users/terms/accept')
  Future<void> acceptTerms(@Body() Map<String, dynamic> body);

  @GET('/users/terms')
  Future<dynamic> getTermsStatus();

  @POST('/users/blocks')
  Future<void> blockUser(@Body() Map<String, dynamic> body);

  @DELETE('/users/blocks/{userId}')
  Future<void> unblockUser(@Path('userId') int userId);

  @GET('/users/blocks')
  Future<PaginatedResponse<BlockedUser>> getBlockedUsers({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/users/privacy')
  Future<PrivacySettings> getPrivacySettings();

  @PUT('/users/privacy')
  Future<PrivacySettings> updatePrivacySettings(
    @Body() Map<String, dynamic> body,
  );

  @GET('/users/subscription-settings')
  Future<SubscriptionSettings> getSubscriptionSettings();

  @PUT('/users/subscription-settings')
  Future<SubscriptionSettings> updateSubscriptionSettings(
    @Body() Map<String, dynamic> body,
  );

  @POST('/messages/export')
  Future<dynamic> exportMessages(@Body() Map<String, dynamic> body);

  // --- Admin Logs ---
  @GET('/admin/logs')
  Future<PaginatedResponse<AdminLog>> getAdminLogs({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
  });

  @GET('/admin/logs/{id}')
  Future<AdminLog> getAdminLog(@Path('id') int id);

  @DELETE('/admin/logs/{id}')
  Future<void> deleteAdminLog(@Path('id') int id);

  @GET('/admin/logs/stats')
  Future<dynamic> getAdminLogStats();

  // --- Health ---
  @GET('/health')
  Future<dynamic> checkHealth();

  @GET('/health/readiness')
  Future<dynamic> checkReadiness();

  @GET('/health/liveness')
  Future<dynamic> checkLiveness();

  // --- Extra Message Methods ---
  @GET('/messages/received')
  Future<PaginatedResponse<Message>> getReceivedMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
  });

  @GET('/messages/sent')
  Future<PaginatedResponse<Message>> getSentMessages({
    @Query('page') int page = 1,
    @Query('size') int size = 20,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
  });
}
