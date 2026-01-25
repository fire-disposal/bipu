import 'dart:async';
// import 'package:flutter_background_service/flutter_background_service.dart'; // 暂时注释后台服务
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 暂时注释通知服务
import 'package:logger/logger.dart';
// import 'ble/ble_service.dart'; // 暂时注释BLE服务

final Logger _logger = Logger();

// 暂时注释后台服务入口点
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   // Only available for flutter 3.0.0 and later
//   DartPluginRegistrant.ensureInitialized();

//   // For flutter prior to 3.0.0
//   // We have to register the plugin manually

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   // Initialize BLE Service in this isolate
//   try {
//     await BleService().initialize();
//     _logger.i('BLE Service initialized in background');
//   } catch (e) {
//     _logger.e('Failed to initialize BLE in background: $e');
//   }

//   // bring to foreground
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if (await service.isForegroundService()) {
//         /// OPTIONAL for use custom notification
//         /// the notification id must be equals with AndroidConfiguration when you call configure()
//         // flutterLocalNotificationsPlugin.show(
//         //   888,
//         //   'COOL SERVICE',
//         //   'Awesome ${DateTime.now()}',
//         //   const NotificationDetails(
//         //     android: AndroidNotificationDetails(
//         //       'my_foreground',
//         //       'MY FOREGROUND SERVICE',
//         //       icon: 'ic_bg_service_small',
//         //       ongoing: true,
//         //     ),
//         //   ),
//         // );

//         // Update notification content if needed
//         service.setForegroundNotificationInfo(
//           title: "Bipupu Service",
//           content: "Running in background... ${DateTime.now().second}",
//         );
//       }
//     }

//     // Perform background tasks here
//     // e.g. Check BLE connection status
//     _logger.d('Background service heartbeat');

//     service.invoke('update', {
//       "current_date": DateTime.now().toIso8601String(),
//       "device": "device",
//     });
//   });
// }

// 暂时注释后台服务类
// @pragma('vm:entry-point')
// class AppBackgroundService {
//   static final AppBackgroundService _instance =
//       AppBackgroundService._internal();
//   factory AppBackgroundService() => _instance;
//   AppBackgroundService._internal();

//   Future<void> initialize() async {
//     if (kIsWeb ||
//         (defaultTargetPlatform != TargetPlatform.android &&
//             defaultTargetPlatform != TargetPlatform.iOS)) {
//       _logger.w(
//         'Background service is not supported on ${defaultTargetPlatform.name}',
//       );
//       return;
//     }

//     final service = FlutterBackgroundService();

//     /// OPTIONAL, using custom notification channel id
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'my_foreground', // id
//       'MY FOREGROUND SERVICE', // title
//       description:
//           'This channel is used for important notifications.', // description
//       importance: Importance.low, // importance must be at low or higher level
//     );

//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         // this will be executed when app is in foreground or background in separated isolate
//         onStart: onStart,

//         // auto start service
//         autoStart: true,
//         isForegroundMode: true,

//         notificationChannelId: 'my_foreground',
//         initialNotificationTitle: 'Bipupu Service',
//         initialNotificationContent: 'Initializing',
//         foregroundServiceNotificationId: 888,
//       ),
//       iosConfiguration: IosConfiguration(
//         // auto start service
//         autoStart: true,

//         // this will be executed when app in foreground in separated isolate
//         onForeground: onStart,

//         // you have to enable background fetch capability on xcode project
//         onBackground: onIosBackground,
//       ),
//     );
//   }

//   @pragma('vm:entry-point')
//   static Future<bool> onIosBackground(ServiceInstance service) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     DartPluginRegistrant.ensureInitialized();
//     return true;
//   }
// }

// 临时空实现，保持接口兼容
class AppBackgroundService {
  static final AppBackgroundService _instance =
      AppBackgroundService._internal();
  factory AppBackgroundService() => _instance;
  AppBackgroundService._internal();

  Future<void> initialize() async {
    _logger.i('Background service is temporarily disabled');
    // 空实现，后台服务已暂时禁用
  }
}
