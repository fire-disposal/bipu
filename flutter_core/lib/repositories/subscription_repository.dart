import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/paginated_response.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final ApiClient _apiClient = ApiClient();

  Future<PaginatedResponse<SubscriptionType>> getSubscriptionTypes({
    int page = 1,
    int size = 20,
    String? category,
    bool? isActive,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<PaginatedResponse<UserSubscriptionResponse>> getUserSubscriptions({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.userSubscriptions,
        queryParameters: {'page': page, 'size': size},
      );

      return PaginatedResponse.fromJson(
        response.data,
        (json) => UserSubscriptionResponse.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
}
