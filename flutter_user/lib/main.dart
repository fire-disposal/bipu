import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_core/core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/storage/mobile_token_storage.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiClient
  ApiClient().init(
    baseUrl: 'http://localhost:8848/api',
    tokenStorage: MobileTokenStorage(),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Theme Service
  await ThemeService().loadTheme();

  // Initialize Auth Service
  await AuthService().initialize();

  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Bipupu User',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          routerConfig: UserRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
