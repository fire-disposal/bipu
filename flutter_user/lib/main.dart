import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_core/core/network/api_client.dart';
import 'package:flutter_user/features/friendship/bloc/friendship_bloc.dart';
import 'core/services/auth_service.dart';
import 'core/storage/mobile_token_storage.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/background_service.dart';

import 'core/services/toast_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiClient
  ApiClient().init(
    baseUrl: 'https://api.205716.xyz/api',
    tokenStorage: MobileTokenStorage(),
    connectTimeout: 15000,
    receiveTimeout: 15000,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Theme Service
  await ThemeService().loadTheme();

  // Initialize Auth Service
  await AuthService().initialize();

  // Initialize Background Service
  try {
    await AppBackgroundService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize background service: $e');
  }

  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<FriendshipBloc>(
              create: (context) {
                // We can trigger Initial Load here if we want global access immediately
                // or just let pages trigger it. Let's lazily load.
                return FriendshipBloc();
              },
            ),
          ],
          child: MaterialApp.router(
            scaffoldMessengerKey: ToastService().scaffoldMessengerKey,
            title: 'Bipupu User',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeService().themeMode,
            routerConfig: UserRouter.router,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
