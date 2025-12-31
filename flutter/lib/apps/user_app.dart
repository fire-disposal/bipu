import 'package:flutter/material.dart';
import '../core/router/user_router.dart';
import '../core/services/theme_service.dart';
import '../core/theme/app_theme.dart';

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
