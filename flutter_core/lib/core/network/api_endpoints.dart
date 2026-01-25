class ApiEndpoints {
  // Health
  static const String health = '/health';
  static const String healthReady = '/health/ready';
  static const String healthLive = '/health/live';

  // Auth & Users
  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String refreshToken = '/users/refresh';
  static const String logout = '/users/logout';
  static const String me = '/users/me';
  static const String users = '/users'; // Admin get users
  static String userDetails(int id) => '/users/$id';
  static const String usersProfile = '/users/profile';
  static const String onlineStatus = '/users/online-status';

  // Admin Users
  static const String adminUsersAll = '/users/admin/all';
  static String adminUserStatus(int id) => '/users/admin/$id/status';
  static const String adminUserStats = '/users/admin/stats';

  // Messages
  static const String messages = '/messages'; // Create, Get list
  static String conversationMessages(int userId) =>
      '/messages/conversations/$userId';
  static const String unreadCount = '/messages/unread/count';
  static const String unreadMessages = '/messages/unread';
  static const String recentMessages = '/messages/recent';
  static const String messageStats = '/messages/stats';
  static String messageDetails(int id) => '/messages/$id';
  static String messageRead(int id) => '/messages/$id/read';
  static const String readAllMessages = '/messages/read-all';

  // Admin Messages
  static const String adminMessagesAll = '/messages/admin/all';
  static String adminMessageDetails(int id) => '/messages/admin/$id';
  static const String adminMessageStats = '/messages/admin/stats';

  // Message Acks
  static const String messageAck = '/message-ack';
  static String messageAcks(int messageId) => '/message-ack/message/$messageId';
  static const String adminMessageAcksAll = '/message-ack/admin/all';
  static const String adminMessageAckStats = '/message-ack/admin/stats';

  // Message Management
  static String favoriteMessage(int id) =>
      '/message-management/messages/$id/favorite';
  static const String favorites = '/message-management/messages/favorites';
  static const String sentMessages = '/message-management/messages/sent';
  static const String receivedMessages =
      '/message-management/messages/received';
  static const String batchDeleteMessages =
      '/message-management/messages/batch';
  static String archiveMessage(int id) =>
      '/message-management/messages/$id/archive';
  static const String messageManagementStats =
      '/message-management/messages/stats';
  static const String exportMessagesAdvanced =
      '/message-management/messages/export';
  static const String searchMessages = '/message-management/messages/search';

  // System Notifications
  static const String systemNotifications = '/system-notifications';
  static const String adminSystemNotificationsAll =
      '/system-notifications/admin/all';
  static const String systemNotificationStats = '/system-notifications/stats';
  static const String adminSystemNotificationStats =
      '/system-notifications/admin/stats';
  static String systemNotificationDetails(int id) =>
      '/system-notifications/$id';
  static String systemNotificationRead(int id) =>
      '/system-notifications/$id/read';
  static const String systemNotificationReadAll =
      '/system-notifications/read-all';
  static String adminSystemNotificationDetails(int id) =>
      '/system-notifications/admin/$id';

  // Users Settings
  static const String userSettingsProfile = '/user-settings/profile';
  static const String userSettings = '/user-settings/settings';
  static const String changePassword = '/user-settings/password';
  static const String acceptTerms = '/user-settings/terms/accept';
  static const String termsStatus = '/user-settings/terms/status';
  static const String exportMessages = '/user-settings/messages/export';
  static const String userSettingsMessageStats =
      '/user-settings/messages/stats';
  static const String userSettingsSubscriptions =
      '/user-settings/subscriptions'; // Get user subscriptions
  static String userSettingsSubscriptionDetails(int id) =>
      '/user-settings/subscriptions/$id';
  static const String privacySettings = '/user-settings/privacy-settings';
  static const String subscriptionSettings =
      '/user-settings/subscription-settings';

  // Blocks
  static const String blocks = '/user-settings/blocks';
  static String unblockUser(int id) => '/user-settings/blocks/$id';

  // Friendships
  static const String friendships = '/friendships'; // Create Request, Get List
  static const String friendRequests = '/friendships/requests';
  static const String friends = '/friendships/friends';
  static String acceptFriendRequest(int id) => '/friendships/$id/accept';
  static String rejectFriendRequest(int id) => '/friendships/$id/reject';
  static String friendshipDetails(int id) => '/friendships/$id'; // Delete
  static const String adminFriendshipsAll = '/friendships/admin/all';
  static String adminFriendshipDetails(int id) => '/friendships/admin/$id';

  // Admin Logs
  static const String adminLogs = '/admin-logs';
  static const String adminLogStats = '/admin-logs/stats';
  static String adminLogDetails(int id) => '/admin-logs/$id';

  // Subscriptions
  static const String subscriptionTypes = '/subscriptions/subscription-types';
  static String subscriptionTypeDetails(int id) =>
      '/subscriptions/subscription-types/$id';
  static const String userSubscriptionsList =
      '/subscriptions/user-subscriptions';
  static String userSubscriptionDetails(int id) =>
      '/subscriptions/user-subscriptions/$id';
  static const String subscriptionStats = '/subscriptions/subscription-stats';
  static const String cosmicMessagingStatus =
      '/subscriptions/cosmic-messaging/status';
  static const String cosmicMessagingSettings =
      '/subscriptions/cosmic-messaging/settings';
}
