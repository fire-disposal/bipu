import 'package:flutter/material.dart';
import '../core/router/admin_router.dart';
import '../core/services/theme_service.dart';
import '../core/theme/app_theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Bipupu Admin',
          theme: AppTheme.adminLightTheme,
          darkTheme: AppTheme.adminDarkTheme,
          themeMode: ThemeService().themeMode,
          routerConfig: AdminRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
