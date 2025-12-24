import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for NotificationsApi
void main() {
  final instance = Openapi().getNotificationsApi();

  group(NotificationsApi, () {
    // Create Notification
    //
    // 创建站内信
    //
    //Future<NotificationResponse> createNotificationApiNotificationsPost(NotificationCreate notificationCreate) async
    test('test createNotificationApiNotificationsPost', () async {
      // TODO
    });

    // Delete Notification
    //
    // 删除站内信（软删除）
    //
    //Future<JsonObject> deleteNotificationApiNotificationsNotificationIdDelete(int notificationId) async
    test('test deleteNotificationApiNotificationsNotificationIdDelete', () async {
      // TODO
    });

    // Get Notification
    //
    // 获取指定站内信
    //
    //Future<NotificationResponse> getNotificationApiNotificationsNotificationIdGet(int notificationId) async
    test('test getNotificationApiNotificationsNotificationIdGet', () async {
      // TODO
    });

    // Get Notification Stats
    //
    // 获取站内信统计信息
    //
    //Future<NotificationStats> getNotificationStatsApiNotificationsStatsGet() async
    test('test getNotificationStatsApiNotificationsStatsGet', () async {
      // TODO
    });

    // Get Notifications
    //
    // 获取站内信列表
    //
    //Future<NotificationList> getNotificationsApiNotificationsGet({ int skip, int limit, AppSchemasNotificationNotificationStatus status }) async
    test('test getNotificationsApiNotificationsGet', () async {
      // TODO
    });

    // Mark All Notifications As Read
    //
    // 标记所有站内信为已读
    //
    //Future<JsonObject> markAllNotificationsAsReadApiNotificationsReadAllPut() async
    test('test markAllNotificationsAsReadApiNotificationsReadAllPut', () async {
      // TODO
    });

    // Mark Notification As Read
    //
    // 标记站内信为已读
    //
    //Future<JsonObject> markNotificationAsReadApiNotificationsNotificationIdReadPut(int notificationId) async
    test('test markNotificationAsReadApiNotificationsNotificationIdReadPut', () async {
      // TODO
    });

    // Update Notification
    //
    // 更新站内信
    //
    //Future<NotificationResponse> updateNotificationApiNotificationsNotificationIdPut(int notificationId, NotificationUpdate notificationUpdate) async
    test('test updateNotificationApiNotificationsNotificationIdPut', () async {
      // TODO
    });

  });
}
