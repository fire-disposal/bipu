import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_core/api/api.dart';
import 'package:flutter_core/core/network/api_client.dart';
import '../core/storage/mobile_token_storage.dart';
import '../core/bluetooth/ble_pipeline.dart';
import '../core/protocol/ble_protocol.dart';

final Logger _logger = Logger();

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Initialize BLE Pipeline set-up
  final blePipeline = BlePipeline();

  // Initialize ApiClient in this isolate
  final tokenStorage = MobileTokenStorage();
  ApiClient().init(
    baseUrl: 'https://api.205716.xyz/api',
    tokenStorage: tokenStorage,
    connectTimeout: 15000,
    receiveTimeout: 15000,
  );

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Last seen message ID to avoid duplicates
  final prefs = await SharedPreferences.getInstance();
  int lastMessageId = prefs.getInt('last_processed_message_id') ?? 0;

  // Polling timer for messages
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    final token = await tokenStorage.getAccessToken();
    if (token == null) {
      _logger.d('Background service: No token found, skipping polling');
      return;
    }

    try {
      // Check unread count
      final unreadCount = await bipupuApi.getUnreadCount();
      if (unreadCount > 0) {
        _logger.i('Background service: $unreadCount unread messages found');
        // Fetch new messages (unread)
        final response = await bipupuApi.getMessages(
          isRead: false,
          size: 5,
          page: 1,
        );

        for (final msg in response.items) {
          if (msg.id > lastMessageId) {
            _logger.i('New message: ${msg.content}');

            // 1. Show notification
            await flutterLocalNotificationsPlugin.show(
              id: msg.id,
              title: 'New Message from ${msg.senderId}',
              body: msg.content,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  'chat_messages',
                  'Chat Messages',
                  channelDescription: 'Notifications for new chat messages',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'ticker',
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );

            // 2. Forward to BLE if connected
            if (blePipeline.isConnected) {
              try {
                await blePipeline.sendMessage(
                  text: msg.content,
                  vibration: VibrationType.notification,
                  screenEffect: ScreenEffect.scroll,
                );
                _logger.i('Message forwarded to BLE device');
              } catch (e) {
                _logger.e('Failed to forward message to BLE: $e');
              }
            } else {
              _logger.w('BLE Device not connected, cannot forward message');
            }

            lastMessageId = msg.id;
            await prefs.setInt('last_processed_message_id', lastMessageId);
          }
        }
      }
    } catch (e) {
      _logger.e('Error in background polling: $e');
    }

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Bipupu Service",
          content: "Connected: ${blePipeline.isConnected ? 'YES' : 'NO'}",
        );
      }
    }

    service.invoke('update', {
      "last_check": DateTime.now().toIso8601String(),
      "connected": blePipeline.isConnected,
    });
  });
}

@pragma('vm:entry-point')
class AppBackgroundService {
  static final AppBackgroundService _instance =
      AppBackgroundService._internal();
  factory AppBackgroundService() => _instance;
  AppBackgroundService._internal();

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _logger.w(
        'Background service not supported on ${defaultTargetPlatform.name}',
      );
      return;
    }

    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground',
      'MY FOREGROUND SERVICE',
      description: 'Main service notification',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Bipupu Service',
        initialNotificationContent: 'Connecting...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
}
