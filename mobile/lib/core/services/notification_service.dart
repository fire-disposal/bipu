import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 本地通知服务提供者
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init();
  return service;
});

/// 本地通知服务
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初始化通知插件
  Future<void> init() async {
    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初始化通知插件
    await _notificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建 Android 通知渠道
    await _createNotificationChannel();

    debugPrint('[NotificationService] 初始化完成');
  }

  /// 创建 Android 通知渠道
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'messages',
        '消息通知',
        description: '新消息提醒',
        importance: Importance.high,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// 请求通知权限
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await androidImpl?.areNotificationsEnabled();
      return enabled ?? true;
    }
    return true;
  }

  /// 显示新消息通知
  Future<void> showMessageNotification({
    required int messageId,
    required String senderName,
    required String messageContent,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages',
      '消息通知',
      channelDescription: '新消息提醒',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      showWhen: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: messageId,
      title: '来自 $senderName 的消息',
      body: messageContent,
      notificationDetails: details,
    );
  }

  /// 显示一般通知
  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      '一般通知',
      channelDescription: '系统通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] 通知点击：${response.payload}');
    // TODO: 处理通知点击，跳转到相应页面
  }

  /// 检查是否有通知权限
  Future<bool> checkPermissions() async {
    if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await androidImpl?.areNotificationsEnabled();
      return enabled ?? true;
    }
    return true;
  }
}
