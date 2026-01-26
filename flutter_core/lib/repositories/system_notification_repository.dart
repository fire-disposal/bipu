import '../core/network/api_client.dart';
import '../models/system_notification_create_model.dart';
import '../models/message_model.dart';
import '../models/paginated_response.dart';

class SystemNotificationRepository {
  final _client = ApiClient().restClient;

  // Create (Admin)
  Future<Message> createSystemNotification(
    SystemNotificationCreate notification,
  ) {
    return _client.createSystemNotification(notification.toJson());
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
  }) {
    return _client.getSystemNotifications(
      page: page,
      size: size,
      status: status,
      priorityMin: priorityMin,
      priorityMax: priorityMax,
      dateFrom: dateFrom?.toIso8601String(),
      dateTo: dateTo?.toIso8601String(),
    );
  }

  // Details
  Future<Message> getSystemNotification(int id) {
    return _client.getSystemNotification(id);
  }

  Future<void> markAsRead(int id) {
    return _client.markSystemNotificationAsRead(id);
  }

  Future<void> markAllAsRead() {
    return _client.markAllSystemNotificationsAsRead();
  }

  Future<void> deleteSystemNotification(int id) {
    return _client.deleteSystemNotification(id);
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
  }) {
    return _client.adminGetAllSystemNotifications(
      page: page,
      size: size,
      status: status,
      priorityMin: priorityMin,
      priorityMax: priorityMax,
      dateFrom: dateFrom?.toIso8601String(),
      dateTo: dateTo?.toIso8601String(),
    );
  }

  Future<void> adminDeleteSystemNotification(int id) {
    return _client.adminDeleteSystemNotification(id);
  }

  Future<dynamic> getStats() {
    return _client.getSystemNotificationStats();
  }

  Future<dynamic> adminGetStats() {
    return _client.adminGetSystemNotificationStats();
  }
}
