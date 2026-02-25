import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
// 服务层导入
import 'services/auth_service.dart';
import 'services/message_service.dart';
import 'services/contact_service.dart';
import 'services/profile_service.dart';
import 'services/block_service.dart';
import 'services/service_account_service.dart';
import 'services/poster_service.dart';
import 'services/user_service.dart';
import 'services/system_service.dart';
import 'services/token_service.dart';

// 控制器导入
import 'controllers/app_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/message_controller.dart';
import 'controllers/contact_controller.dart';
import 'controllers/home_controller.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'core/theme/shadcn_config.dart';

void main() async {
  // 初始化GetX依赖注入

  // 1. 先注入所有服务层
  final tokenService = TokenService();
  Get.put(tokenService);

  final systemService = SystemService();
  Get.put(systemService);

  final authService = AuthService();
  Get.put(authService);

  final messageService = MessageService();
  Get.put(messageService);

  final contactService = ContactService();
  Get.put(contactService);

  final profileService = ProfileService();
  Get.put(profileService);

  final blockService = BlockService();
  Get.put(blockService);

  final serviceAccountService = ServiceAccountService();
  Get.put(serviceAccountService);

  final posterService = PosterService();
  Get.put(posterService);

  final userService = UserService();
  Get.put(userService);

  // 2. 初始化系统服务
  await systemService.initialize();

  // 3. 初始化认证服务
  await authService.initialize();

  // 4. 注入所有必要的控制器
  Get.put(AppController());
  Get.put(AuthController());
  Get.put(MessageController());
  Get.put(ContactController());
  Get.put(HomeController());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnThemeConfig.createShadAppWithGetX(
      home: App(),
      themeMode: ThemeMode.system,
      pages: [
        GetPage(name: '/', page: () => App()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/settings', page: () => SettingsPage()),
      ],
      initialRoute: '/',
    );
  }
}

// 临时页面定义
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(child: Text('设置页面')),
    );
  }
}
