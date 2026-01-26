import '../core/network/api_client.dart';
import '../models/paginated_response.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final _client = ApiClient().restClient;

  // Types (Catalog)
  Future<PaginatedResponse<SubscriptionType>> getSubscriptionTypes({
    int page = 1,
    int size = 20,
    String? category,
    bool? isActive,
  }) {
    return _client.getSubscriptionTypes(
      page: page,
      size: size,
      category: category,
      isActive: isActive,
    );
  }

  Future<SubscriptionType> getSubscriptionType(int id) {
    return _client.getSubscriptionType(id);
  }

  // Admin Types
  Future<SubscriptionType> createSubscriptionType(Map<String, dynamic> data) {
    return _client.createSubscriptionType(data);
  }

  Future<SubscriptionType> updateSubscriptionType(
    int id,
    Map<String, dynamic> data,
  ) {
    return _client.updateSubscriptionType(id, data);
  }

  Future<void> deleteSubscriptionType(int id) {
    return _client.deleteSubscriptionType(id);
  }

  // User Subscriptions
  Future<PaginatedResponse<UserSubscriptionResponse>> getUserSubscriptions({
    int page = 1,
    int size = 20,
  }) {
    return _client.getUserSubscriptions(page: page, size: size);
  }

  Future<UserSubscriptionResponse> updateUserSubscription(
    int subscriptionTypeId,
    Map<String, dynamic> data,
  ) {
    return _client.updateUserSubscription(subscriptionTypeId, data);
  }

  Future<void> unsubscribe(int subscriptionTypeId) {
    return _client.unsubscribe(subscriptionTypeId);
  }

  // Stats
  Future<dynamic> getSubscriptionStats() {
    return _client.getSubscriptionStats();
  }

  // Cosmic
  Future<dynamic> getCosmicMessagingStatus() {
    return _client.getCosmicMessagingStatus();
  }

  Future<dynamic> updateCosmicMessagingSettings(Map<String, dynamic> settings) {
    return _client.updateCosmicMessagingSettings(settings);
  }
}
