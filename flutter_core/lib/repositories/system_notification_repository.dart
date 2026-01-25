import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/system_notification_create_model.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class SystemNotificationRepository {
  final ApiClient _apiClient = ApiClient();

  // Create (Admin)
  Future<Message> createSystemNotification(
    SystemNotificationCreate notification,
  ) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.systemNotifications,
      data: notification.toJson(),
    );
    return Message.fromJson(response.data);
  }

  // Get (User)
  Future<PaginatedResponse<Message>> getSystemNotifications({
    int page = 1,
    int size = 20,
    String? status,
    int? priorityMin,
    int? priorityMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'size': size};
    if (status != null) queryParams['status'] = status;
    if (priorityMin != null) queryParams['priority_min'] = priorityMin;
    if (priorityMax != null) queryParams['priority_max'] = priorityMax;
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final response = await _apiClient.dio.get(
      ApiEndpoints.systemNotifications,
      queryParameters: queryParams,
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  // Details
  Future<Message> getSystemNotification(int id) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.systemNotificationDetails(id),
    );
    return Message.fromJson(response.data);
  }

  Future<void> markAsRead(int id) async {
    await _apiClient.dio.put(ApiEndpoints.systemNotificationRead(id));
  }

  Future<void> markAllAsRead() async {
    await _apiClient.dio.put(ApiEndpoints.systemNotificationReadAll);
  }

  Future<void> deleteSystemNotification(int id) async {
    await _apiClient.dio.delete(ApiEndpoints.systemNotificationDetails(id));
  }

  // Admin Get All
  Future<PaginatedResponse<Message>> adminGetAllSystemNotifications({
    int page = 1,
    int size = 20,
    String? status,
    int? priorityMin,
    int? priorityMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'size': size};
    if (status != null) queryParams['status'] = status;
    if (priorityMin != null) queryParams['priority_min'] = priorityMin;
    if (priorityMax != null) queryParams['priority_max'] = priorityMax;
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final response = await _apiClient.dio.get(
      ApiEndpoints.adminSystemNotificationsAll,
      queryParameters: queryParams,
    );
    return PaginatedResponse.fromJson(
      response.data,
      (json) => Message.fromJson(json),
    );
  }

  Future<void> adminDeleteSystemNotification(int id) async {
    await _apiClient.dio.delete(
      ApiEndpoints.adminSystemNotificationDetails(id),
    );
  }

  // Alias for Admin Stats
  Future<Map<String, dynamic>> getAdminSystemNotificationStats() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminSystemNotificationStats,
    );
    return response.data;
  }

  // Alias for Admin Get All
  Future<PaginatedResponse<Message>> getAllSystemNotifications({
    int page = 1,
    int size = 20,
    String? status,
    int? priorityMin,
    int? priorityMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return adminGetAllSystemNotifications(
      page: page,
      size: size,
      status: status,
      priorityMin: priorityMin,
      priorityMax: priorityMax,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  // Stats
  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.systemNotificationStats,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> adminGetStats() async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.adminSystemNotificationStats,
    );
    return response.data;
  }
}
