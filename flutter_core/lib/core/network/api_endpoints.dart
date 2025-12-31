class ApiEndpoints {
  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String refreshToken = '/users/refresh';
  static const String users = '/users';
  static const String adminLogs = '/admin-logs';

  static const String messages = '/messages';
  static const String friendships = '/friendships';
  static const String friendRequests = '/friendships/requests';

  static const String userProfile = '/user-settings/profile';
  static const String userSettings = '/user-settings/settings';
  static const String changePassword = '/user-settings/password';

  static const String systemNotifications = '/system-notifications';

  static const String messageFavorites =
      '/message-management/messages/favorites';
  static const String messageSent = '/message-management/messages/sent';
  static const String messageReceived = '/message-management/messages/received';

  static const String subscriptionTypes = '/subscriptions/subscription-types';
  static const String userSubscriptions = '/subscriptions/user-subscriptions';

  // Helper to get user details path
  static String userDetails(int id) => '/users/$id';
}
