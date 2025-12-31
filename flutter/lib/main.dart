import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'apps/admin_app.dart';
import 'apps/user_app.dart';
import 'core/services/auth_service.dart';
// import 'core/services/background_service.dart'; // 暂时注释后台服务
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Theme Service
  await ThemeService().loadTheme();

  // Initialize Auth Service
  await AuthService().initialize();

  // Determine which app to run based on environment variable
  // Run with: flutter run --dart-define=APP_TYPE=admin
  const String appType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'user',
  );

  // 暂时注释后台服务初始化
  // Initialize background service only for user app
  // if (appType == 'user') {
  //   if (defaultTargetPlatform == TargetPlatform.android) {
  //     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //     await flutterLocalNotificationsPlugin
  //         .resolvePlatformSpecificImplementation<
  //           AndroidFlutterLocalNotificationsPlugin
  //         >()
  //         ?.requestNotificationsPermission();
  //   }
  //   await AppBackgroundService().initialize();
  // }

  if (appType == 'admin') {
    runApp(const AdminApp());
  } else {
    runApp(const UserApp());
  }
}
