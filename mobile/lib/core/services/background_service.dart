import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import 'notification_service.dart';

// ── 共享常量 ──────────────────────────────────────────────────────────────────
/// FlutterSecureStorage 中用于前后台同步消息游标的键
const String kBgLastMsgIdKey = 'bipupu_bg_last_msg_id';

/// 后台服务保活通知 ID（与频道配置对应）
const int kBgServiceNotificationId = 888;

// ── 后台 Isolate 入口（必须是 top-level 函数）────────────────────────────────

/// iOS 后台任务处理器（iOS 后台执行时间极短，仅返回 true 以满足 API 要求）
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

/// Android / iOS 后台服务主入口
/// 此函数在独立 Dart Isolate 中执行，与主 UI Isolate 共享代码但内存独立
@pragma('vm:entry-point')
void onBackgroundStart(ServiceInstance service) async {
  // ① 注册所有 Flutter 插件（background isolate 必须显式注册）
  DartPluginRegistrant.ensureInitialized();

  // ② 初始化本地通知插件（独立 isolate 需要单独初始化）
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  // 确保消息频道存在
  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          kMsgNotificationChannelId,
          kMsgNotificationChannelName,
          description: '接收来自其他用户的新消息通知',
          importance: Importance.high,
          playSound: true,
        ),
      );

  // ③ 安全存储（与主 App 使用完全相同的 Android 配置，读取同一批数据）
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      sharedPreferencesName: 'bipupu_secure_prefs',
      preferencesKeyPrefix: 'bipupu_',
    ),
  );

  // ④ 专用 Dio 实例（不依赖主 App 的 ApiClient）
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 10),
      validateStatus: (status) =>
          status != null && ((status >= 200 && status < 300) || status == 408),
    ),
  );

  // ⑤ 监听来自前台的停止指令
  service.on('stopService').listen((_) {
    log('[BG] 收到前台停止指令，退出后台服务');
    service.stopSelf();
  });

  log('[BG] 后台消息轮询服务已启动 → ${AppConfig.apiBaseUrl}');
  log('[BG] 注意：后台服务仅负责通知，消息转发由前台主引擎负责');

  int consecutiveErrors = 0;
  const maxConsecutiveErrors = 5;

  // 最后通知时间戳，用于去重（避免短时间重复通知）
  int lastNotificationTimestamp = 0;
  const minNotificationIntervalMs = 3000; // 最短通知间隔 3 秒

  // ── 主轮询循环 ──────────────────────────────────────────────────────────────
  while (true) {
    try {
      // 读取前后台同步的消息游标
      final lastMsgIdStr = await secureStorage.read(key: kBgLastMsgIdKey);
      final lastMsgId = int.tryParse(lastMsgIdStr ?? '0') ?? 0;

      // 读取访问 Token（与主 App 共用 secure storage）
      final token = await secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        log('[BG] 无有效 Token，60 秒后重试');
        await Future.delayed(const Duration(minutes: 1));
        continue;
      }

      // 发起长轮询请求（timeout=30 秒，由后端控制等待窗口）
      final response = await dio.get<Map<String, dynamic>>(
        '/api/messages/poll',
        queryParameters: {'last_msg_id': lastMsgId, 'timeout': 30},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      consecutiveErrors = 0; // 成功则重置错误计数

      if (response.statusCode == 200) {
        final data = response.data ?? {};
        final messages = (data['messages'] as List<dynamic>?) ?? [];

        if (messages.isNotEmpty) {
          // 更新游标
          int maxId = lastMsgId;
          for (final raw in messages) {
            final id = (raw as Map<String, dynamic>)['id'] as int? ?? 0;
            if (id > maxId) maxId = id;
          }
          if (maxId > lastMsgId) {
            await secureStorage.write(
              key: kBgLastMsgIdKey,
              value: maxId.toString(),
            );
          }

          // 取第一条消息信息用于通知文本
          final first = messages.first as Map<String, dynamic>;
          final senderName = _extractSenderName(first);
          final content =
              (first['content'] as String?)?.trim().isNotEmpty == true
              ? first['content'] as String
              : '新消息';

          // 通知去重：检查时间间隔（避免 3 秒内重复通知）
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastNotificationTimestamp > minNotificationIntervalMs) {
            // 展示通知
            await notifications.show(
              id: maxId % 9999, // 通知 ID 取模，避免无限增长
              title: messages.length == 1
                  ? '来自 $senderName 的新消息'
                  : '您有 ${messages.length} 条新消息',
              body: messages.length == 1 ? content : '来自 $senderName 等人',
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
            lastNotificationTimestamp = now;
            log('[BG] 收到 ${messages.length} 条新消息，已发送通知 (maxId=$maxId)');
          } else {
            log(
              '[BG] 收到 ${messages.length} 条新消息，但距离上次通知 < 3 秒，跳过通知 (maxId=$maxId)',
            );
          }

          // 通知主引擎：
          // 1. 告知消息数量（计数）
          // 2. 把完整消息列表传回 → 主引擎 BluetoothForwardService 可即时转发到 BLE 设备
          //    （主引擎事件循环在 App 后台时仍在运行，BLE 连接依然有效）
          service.invoke('onNewMessages', {'count': messages.length});
          service.invoke('btForwardMessages', {
            'messages': messages, // List<Map<String,dynamic>> 原始 JSON
          });
        } else {
          log('[BG] 长轮询超时（无新消息），继续下一轮');
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token 失效，无需重试，停止服务
        log('[BG] Token 已失效（401），停止后台轮询');
        service.stopSelf();
        return;
      }

      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        // 超时属于正常长轮询现象，不计入错误
        log('[BG] 请求超时（正常长轮询行为），立即继续');
        continue;
      }

      consecutiveErrors++;
      log('[BG] 网络错误 ($consecutiveErrors/$maxConsecutiveErrors): ${e.message}');

      if (consecutiveErrors >= maxConsecutiveErrors) {
        log('[BG] 连续错误次数过多，等待 60 秒后重试');
        await Future.delayed(const Duration(minutes: 1));
        consecutiveErrors = 0;
      } else {
        await Future.delayed(Duration(seconds: consecutiveErrors * 5));
      }
    } catch (e) {
      consecutiveErrors++;
      log('[BG] 未知错误 ($consecutiveErrors/$maxConsecutiveErrors): $e');
      if (consecutiveErrors >= maxConsecutiveErrors) {
        await Future.delayed(const Duration(minutes: 1));
        consecutiveErrors = 0;
      } else {
        await Future.delayed(Duration(seconds: consecutiveErrors * 3));
      }
    }
  }
}

/// 从消息 Map 中提取发送者显示名称
String _extractSenderName(Map<String, dynamic> msg) {
  final nickname = msg['sender_nickname'] as String?;
  if (nickname != null && nickname.isNotEmpty) return nickname;
  final bipupuId = msg['sender_bipupu_id'] as String?;
  if (bipupuId != null && bipupuId.isNotEmpty) return bipupuId;
  return '未知用户';
}

// ── 前台管理类 ─────────────────────────────────────────────────────────────

/// 后台消息服务管理器（在主 Isolate / 前台运行）
///
/// 负责：
/// - 配置 flutter_background_service（注册入口点、频道等）
/// - 在用户登录后启动后台服务
/// - 在用户登出后停止后台服务
/// - 提供前后台消息游标同步接口
class BackgroundMessageService {
  static final BackgroundMessageService _instance =
      BackgroundMessageService._internal();
  factory BackgroundMessageService() => _instance;
  BackgroundMessageService._internal();

  /// 是否已配置（防止重复 configure）
  bool _configured = false;

  /// 配置后台服务（应在 main() 中、[runApp] 之前调用）
  /// 注意：仅配置，不自动启动——需等待用户登录后调用 [start]
  Future<void> configure() async {
    if (_configured) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: false, // 不自动启动，由登录逻辑控制
        isForegroundMode: true,
        notificationChannelId: kBgServiceNotificationChannelId,
        initialNotificationTitle: 'Bipupu',
        initialNotificationContent: '正在监听新消息...',
        foregroundServiceNotificationId: kBgServiceNotificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundStart,
        onBackground: onIosBackground,
      ),
    );

    _configured = true;
    log('[BackgroundMessageService] 配置完成');
  }

  /// 启动后台服务（登录成功后调用）
  Future<bool> start() async {
    if (!_configured) {
      log('[BackgroundMessageService] 尚未配置，请先调用 configure()');
      return false;
    }
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      log('[BackgroundMessageService] 后台服务已在运行');
      return true;
    }
    final started = await service.startService();
    log('[BackgroundMessageService] 启动后台服务: $started');
    return started;
  }

  /// 停止后台服务（登出时调用）
  Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
      log('[BackgroundMessageService] 已发送停止指令');
    }
  }

  /// 检查后台服务是否正在运行
  Future<bool> isRunning() => FlutterBackgroundService().isRunning();

  /// 同步消息游标到 FlutterSecureStorage
  ///
  /// 由前台 [ImService] 在收到新消息时调用，确保后台服务不重复推送通知
  static Future<void> syncLastMessageId(int messageId) async {
    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          sharedPreferencesName: 'bipupu_secure_prefs',
          preferencesKeyPrefix: 'bipupu_',
        ),
      );
      final currentStr = await secureStorage.read(key: kBgLastMsgIdKey);
      final current = int.tryParse(currentStr ?? '0') ?? 0;
      if (messageId > current) {
        await secureStorage.write(
          key: kBgLastMsgIdKey,
          value: messageId.toString(),
        );
      }
    } catch (e) {
      log('[BackgroundMessageService] syncLastMessageId 失败: $e');
    }
  }
}
