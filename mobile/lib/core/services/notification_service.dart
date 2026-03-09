import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── 通知频道常量（前台 / 后台均使用相同频道 ID）────────────────────────────
const String kMsgNotificationChannelId = 'bipupu_messages';
const String kMsgNotificationChannelName = '新消息通知';

const String kBgServiceNotificationChannelId = 'bipupu_bg_service';
const String kBgServiceNotificationChannelName = 'Bipupu 后台服务';

/// 本地通知服务
///
/// 负责：
/// - 初始化 flutter_local_notifications
/// - 创建 Android 通知频道
/// - 请求通知权限（Android 13+）
/// - 展示新消息通知
/// - 处理通知点击回调
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 通知点击回调（在 main.dart 中设置，用于导航到消息页）
  void Function(int id, String? payload)? onNotificationTap;

  // ── 公开 API ──────────────────────────────────────────────────────────────

  /// 初始化通知服务
  /// 应在 [WidgetsFlutterBinding.ensureInitialized] 之后、[runApp] 之前调用
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        log(
          '[NotificationService] 通知被点击: id=${details.id}, payload=${details.payload}',
        );
        onNotificationTap?.call(details.id ?? 0, details.payload);
      },
      // 后台时收到通知点击也触发（Android only）
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    await _ensureAndroidChannels();

    _initialized = true;
    log('[NotificationService] 初始化完成');
  }

  /// 请求通知权限（Android 13+ 需要运行时申请）
  /// 返回是否已获得权限
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      log('[NotificationService] 通知权限: ${granted == true ? "已授予" : "已拒绝"}');
      return granted ?? false;
    }

    return false;
  }

  /// 展示单条新消息通知
  /// 首次调用时会自动请求通知权限（按需请求，提升用户体验）
  Future<void> showNewMessageNotification({
    required int notificationId,
    required String senderName,
    required String messagePreview,
    String payload = 'messages',
  }) async {
    if (!_initialized) return;

    // 首次显示通知时请求权限（按需请求）
    await requestPermission();

    await _plugin.show(
      id: notificationId,
      title: '来自 $senderName 的消息',
      body: messagePreview,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kMsgNotificationChannelId,
          kMsgNotificationChannelName,
          channelDescription: '接收来自其他用户的新消息通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  /// 展示多条未读汇总通知
  Future<void> showUnreadSummaryNotification(int count) async {
    if (!_initialized) return;

    await _plugin.show(
      id: 0,
      title: '新消息',
      body: '您有 $count 条未读消息',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kMsgNotificationChannelId,
          kMsgNotificationChannelName,
          channelDescription: '接收来自其他用户的新消息通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'messages',
    );
  }

  /// 取消指定通知
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// 取消所有通知
  Future<void> cancelAll() => _plugin.cancelAll();

  bool get isInitialized => _initialized;

  // ── 私有方法 ──────────────────────────────────────────────────────────────

  /// 确保 Android 通知频道已创建
  Future<void> _ensureAndroidChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    // 消息频道（高重要性）
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kMsgNotificationChannelId,
        kMsgNotificationChannelName,
        description: '接收来自其他用户的新消息通知',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // 后台服务保活频道（低重要性，不会打扰用户）
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kBgServiceNotificationChannelId,
        kBgServiceNotificationChannelName,
        description: 'Bipupu 后台消息监听服务保活通知',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
  }
}

/// 后台通知点击响应（top-level，flutter_local_notifications 要求）
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse details) {
  // 后台点击暂只记录日志，不做导航（导航需在 isolate 激活后处理）
  log(
    '[NotificationService] 后台通知点击: id=${details.id}, payload=${details.payload}',
  );
}
