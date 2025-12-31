import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_settings_model.dart';

class UserSettingsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.userProfile);
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.userProfile,
        data: data,
      );
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> updateUserSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.userSettings,
        data: data,
      );
      return UserProfile.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
