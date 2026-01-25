import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_core/core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/storage/admin_token_storage.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiClient
  ApiClient().init(
    baseUrl: 'https://firedisposal.fun/api',
    tokenStorage: AdminTokenStorage(),
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
