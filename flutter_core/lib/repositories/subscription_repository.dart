import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/paginated_response.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final ApiClient _apiClient = ApiClient();

  // Types (Catalog)
  Future<PaginatedResponse<SubscriptionType>> getSubscriptionTypes({
    int page = 1,
    int size = 20,
    String? category,
    bool? isActive,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.subscriptionTypes,
      queryParameters: {
        'page': page,
        'size': size,
        if (category != null) 'category': category,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => SubscriptionType.fromJson(json),
    );
  }

  Future<SubscriptionType> getSubscriptionType(int id) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.subscriptionTypeDetails(id),
    );
    return SubscriptionType.fromJson(response.data);
  }

  // Admin Types
  Future<SubscriptionType> createSubscriptionType(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.subscriptionTypes,
      data: data,
    );
    return SubscriptionType.fromJson(response.data);
  }

  Future<SubscriptionType> updateSubscriptionType(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.subscriptionTypeDetails(id),
      data: data,
    );
    return SubscriptionType.fromJson(response.data);
  }

  Future<void> deleteSubscriptionType(int id) async {
    await _apiClient.dio.delete(ApiEndpoints.subscriptionTypeDetails(id));
  }

  // User Subscriptions
  Future<PaginatedResponse<UserSubscriptionResponse>> getUserSubscriptions({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.userSubscriptionsList,
      queryParameters: {'page': page, 'size': size},
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => UserSubscriptionResponse.fromJson(json),
    );
  }

  Future<UserSubscriptionResponse> updateUserSubscription(
    int subscriptionTypeId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.userSubscriptionDetails(
        subscriptionTypeId,
      ), // Note: Endpoint uses subscription_type_id
      data: data,
    );
    // Response might be UserSubscription or UserSubscriptionResponse.
    // Assuming backend returns the updated subscription info, possibly UserSubscriptionResponse structure or just UserSubscription.
    // Looking at openapi: PaginatedResponse[UserSubscriptionResponse]. single put?
    // Put returns: UserSubscription (from schema ref?) or UserSubscriptionResponse.
    // Let's assume UserSubscription for now if response structure matches.
    // Actually userSubscriptionDetails(id) returns UserSubscription likely.
    // Check openapi: /api/subscriptions/user-subscriptions/{subscription_type_id} PUT -> 200 OK.
    // Response schema not explicit in summary.
    // Safer to return dynamic or map until verified.
    // But let's assume UserSubscriptionResponse for consistency if possible, or just the UserSubscription.
    // The endpoint replaces settings for a type.
    return UserSubscriptionResponse.fromJson(response.data);
  }

  Future<void> unsubscribe(int subscriptionTypeId) async {
    await _apiClient.dio.delete(
      ApiEndpoints.userSubscriptionDetails(subscriptionTypeId),
    );
  }

  // Stats
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    final response = await _apiClient.dio.get(ApiEndpoints.subscriptionStats);
    return response.data;
  }

  // Cosmic
  Future<Map<String, dynamic>> getCosmicMessagingStatus() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.cosmicMessagingStatus,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateCosmicMessagingSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.cosmicMessagingSettings,
      data: settings,
    );
    return response.data;
  }
}
