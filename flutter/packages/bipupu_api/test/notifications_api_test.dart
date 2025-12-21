import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for NotificationsApi
void main() {
  final instance = Openapi().getNotificationsApi();

  group(NotificationsApi, () {
    // Cancel Notification
    //
    // 取消通知
    //
    //Future<JsonObject> cancelNotificationApiNotificationsNotificationIdCancelPost(int notificationId) async
    test('test cancelNotificationApiNotificationsNotificationIdCancelPost',
        () async {
      // TODO
    });

    // Create Email Notification
    //
    // 创建邮件通知
    //
    //Future<NotificationResponse> createEmailNotificationApiNotificationsEmailPost(EmailNotification emailNotification) async
    test('test createEmailNotificationApiNotificationsEmailPost', () async {
      // TODO
    });

    // Create Notification
    //
    // 创建通知
    //
    //Future<NotificationResponse> createNotificationApiNotificationsPost(NotificationCreate notificationCreate) async
    test('test createNotificationApiNotificationsPost', () async {
      // TODO
    });

    // Create Push Notification
    //
    // 创建推送通知
    //
    //Future<NotificationResponse> createPushNotificationApiNotificationsPushPost(PushNotification pushNotification) async
    test('test createPushNotificationApiNotificationsPushPost', () async {
      // TODO
    });

    // Delete Notification
    //
    // 删除通知
    //
    //Future<JsonObject> deleteNotificationApiNotificationsNotificationIdDelete(int notificationId) async
    test('test deleteNotificationApiNotificationsNotificationIdDelete',
        () async {
      // TODO
    });

    // Get Notification
    //
    // 获取指定通知
    //
    //Future<NotificationResponse> getNotificationApiNotificationsNotificationIdGet(int notificationId) async
    test('test getNotificationApiNotificationsNotificationIdGet', () async {
      // TODO
    });

    // Get Notification Stats
    //
    // 获取通知统计信息
    //
    //Future<NotificationStats> getNotificationStatsApiNotificationsStatsGet() async
    test('test getNotificationStatsApiNotificationsStatsGet', () async {
      // TODO
    });

    // Get Notifications
    //
    // 获取通知列表
    //
    //Future<NotificationList> getNotificationsApiNotificationsGet({ int skip, int limit, AppSchemasNotificationNotificationType notificationType, AppSchemasNotificationNotificationStatus status }) async
    test('test getNotificationsApiNotificationsGet', () async {
      // TODO
    });

    // Send Notification
    //
    // 发送通知
    //
    //Future<JsonObject> sendNotificationApiNotificationsNotificationIdSendPost(int notificationId) async
    test('test sendNotificationApiNotificationsNotificationIdSendPost',
        () async {
      // TODO
    });

    // Send Pending Notifications
    //
    // 批量发送待处理通知（需要超级用户权限）
    //
    //Future<JsonObject> sendPendingNotificationsApiNotificationsBatchSendPost() async
    test('test sendPendingNotificationsApiNotificationsBatchSendPost',
        () async {
      // TODO
    });

    // Update Notification
    //
    // 更新通知
    //
    //Future<NotificationResponse> updateNotificationApiNotificationsNotificationIdPut(int notificationId, NotificationUpdate notificationUpdate) async
    test('test updateNotificationApiNotificationsNotificationIdPut', () async {
      // TODO
    });
  });
}
