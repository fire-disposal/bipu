import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'apps/admin_app.dart';
import 'apps/user_app.dart';
import 'core/services/background_service.dart';
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Theme Service
  await ThemeService().loadTheme();

  // Determine which app to run based on environment variable
  // Run with: flutter run --dart-define=APP_TYPE=admin
  const String appType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'user',
  );

  // Initialize background service only for user app
  if (appType == 'user') {
    await AppBackgroundService().initialize();
  }

  if (appType == 'admin') {
    runApp(const AdminApp());
  } else {
    runApp(const UserApp());
  }
}
