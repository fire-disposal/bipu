import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_core/core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/storage/token_storage_factory.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 使用工厂创建合适的存储实现
  final tokenStorage = TokenStorageFactory.create();

  // Initialize ApiClient
  ApiClient().init(
    baseUrl: 'http://38.147.187.207:8000/api',
    tokenStorage: tokenStorage,
    connectTimeout: 15000,
    receiveTimeout: 15000,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Theme Service
  await ThemeService().loadTheme();

  // Initialize Auth Service
  await AuthService().initialize();

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Bipupu Admin',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          routerConfig: AdminRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
