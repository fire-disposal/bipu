import '../core/network/api_client.dart';
import '../models/user_settings_model.dart';
import '../models/paginated_response.dart';

class UserSettingsRepository {
  final _client = ApiClient().restClient;

  // Profile
  Future<UserProfile> getUserProfile() {
    return _client.getUserProfile();
  }

  Future<UserProfile> updateUserProfile(Map<String, dynamic> data) {
    return _client.updateUserProfileSettings(data);
  }

  // Settings
  Future<UserProfile> updateUserSettings(Map<String, dynamic> data) {
    return _client.updateUserSettings(data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) {
    return _client.changePassword({
      'old_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // Terms
  Future<void> acceptTerms() {
    return _client.acceptTerms({'accepted': true});
  }

  Future<dynamic> getTermsStatus() {
    return _client.getTermsStatus();
  }

  // Blocks
  Future<void> blockUser(int userId) {
    return _client.blockUser({'user_id': userId});
  }

  Future<void> unblockUser(int userId) {
    return _client.unblockUser(userId);
  }

  Future<PaginatedResponse<BlockedUser>> getBlockedUsers({
    int page = 1,
    int size = 20,
  }) {
    return _client.getBlockedUsers(page: page, size: size);
  }

  // Privacy
  Future<PrivacySettings> getPrivacySettings() {
    return _client.getPrivacySettings();
  }

  Future<PrivacySettings> updatePrivacySettings(Map<String, dynamic> settings) {
    return _client.updatePrivacySettings(settings);
  }

  // Subscription Settings (Cosmic, notification times etc)
  Future<SubscriptionSettings> getSubscriptionSettings() {
    return _client.getSubscriptionSettings();
  }

  Future<SubscriptionSettings> updateSubscriptionSettings(
    Map<String, dynamic> settings,
  ) {
    return _client.updateSubscriptionSettings(settings);
  }

  // Messages Export
  Future<dynamic> exportMessages({String? format}) {
    return _client.exportMessages(format != null ? {'format': format} : {});
  }
}
