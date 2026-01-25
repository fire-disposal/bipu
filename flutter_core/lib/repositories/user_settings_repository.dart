import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_settings_model.dart';
import '../models/paginated_response.dart';

class UserSettingsRepository {
  final ApiClient _apiClient = ApiClient();

  // Profile
  Future<UserProfile> getUserProfile() async {
    final response = await _apiClient.dio.get(ApiEndpoints.userSettingsProfile);
    return UserProfile.fromJson(response.data);
  }

  Future<UserProfile> updateUserProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.userSettingsProfile,
      data: data,
    );
    return UserProfile.fromJson(response.data);
  }

  // Settings
  Future<UserProfile> updateUserSettings(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.userSettings,
      data: data,
    );
    return UserProfile.fromJson(response.data);
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _apiClient.dio.put(
      ApiEndpoints.changePassword,
      data: {'old_password': currentPassword, 'new_password': newPassword},
    );
  }

  // Terms
  Future<void> acceptTerms() async {
    await _apiClient.dio.put(
      ApiEndpoints.acceptTerms,
      data: {'accepted': true},
    );
  }

  Future<Map<String, dynamic>> getTermsStatus() async {
    final response = await _apiClient.dio.get(ApiEndpoints.termsStatus);
    return response.data;
  }

  // Blocks
  Future<void> blockUser(int userId) async {
    await _apiClient.dio.post(ApiEndpoints.blocks, data: {'user_id': userId});
  }

  Future<void> unblockUser(int userId) async {
    await _apiClient.dio.delete(ApiEndpoints.unblockUser(userId));
  }

  Future<PaginatedResponse<BlockedUser>> getBlockedUsers({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.blocks,
      queryParameters: {'page': page, 'size': size},
    );
    // API returns UserBlockList which has PaginatedResponse structure with items type BlockedUserResponse
    return PaginatedResponse.fromJson(
      response.data,
      (json) => BlockedUser.fromJson(json),
    );
  }

  // Privacy
  Future<PrivacySettings> getPrivacySettings() async {
    final response = await _apiClient.dio.get(ApiEndpoints.privacySettings);
    return PrivacySettings.fromJson(response.data);
  }

  Future<PrivacySettings> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.privacySettings,
      data: settings,
    );
    return PrivacySettings.fromJson(response.data);
  }

  // Subscription Settings (Cosmic, notification times etc)
  Future<SubscriptionSettings> getSubscriptionSettings() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.subscriptionSettings,
    );
    return SubscriptionSettings.fromJson(response.data);
  }

  Future<SubscriptionSettings> updateSubscriptionSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.subscriptionSettings,
      data: settings,
    );
    return SubscriptionSettings.fromJson(response.data);
  }

  // Messages Export
  Future<Map<String, dynamic>> exportMessages({String? format}) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.exportMessages,
      data: format != null ? {'format': format} : {},
    );
    return response.data;
  }
}
