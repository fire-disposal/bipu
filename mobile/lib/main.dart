import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/message_controller.dart';
import 'controllers/contact_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/block_controller.dart';
import 'controllers/home_controller.dart';
import 'repos/auth_repo.dart';
import 'repos/message_repo.dart';
import 'repos/contact_repo.dart';
import 'repos/profile_repo.dart';
import 'repos/block_repo.dart';
import 'repos/poster_repo.dart';
import 'core/theme/app_theme.dart';

void main() {
  // 初始化GetX依赖注入
  Get.put(AppController());
  Get.put(AuthRepo());
  Get.put(MessageRepo());
  Get.put(ContactRepo());
  Get.put(ProfileRepo());
  Get.put(BlockRepo());
  Get.put(PosterRepo());
  Get.put(AuthController());
  Get.put(MessageController());
  Get.put(ContactController());
  Get.put(ProfileController());
  Get.put(BlockController());
  Get.put(HomeController());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bipupu - 宇宙传讯',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const App()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/register', page: () => const RegisterPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/messages', page: () => const MessagesPage()),
        GetPage(name: '/profile', page: () => const ProfilePage()),
        GetPage(name: '/contacts', page: () => const ContactsPage()),
        GetPage(name: '/pager', page: () => const PagerPage()),
        GetPage(name: '/bluetooth', page: () => const BluetoothPage()),
        GetPage(name: '/settings', page: () => const SettingsPage()),
      ],
      home: const App(),
    );
  }
}

// 临时页面定义（实际页面需要从现有UI迁移）
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: const Center(child: Text('登录页面')),
    );
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: const Center(child: Text('注册页面')),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: const Center(child: Text('首页 - 使用新的HomePage实现')),
    );
  }
}

// 临时页面定义
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('联系人')),
      body: const Center(child: Text('联系人页面 - 使用ContactController')),
    );
  }
}

class PagerPage extends StatelessWidget {
  const PagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('传唤台')),
      body: const Center(child: Text('传唤台页面')),
    );
  }
}

class BluetoothPage extends StatelessWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('蓝牙')),
      body: const Center(child: Text('蓝牙页面 - 保持原有实现')),
    );
  }
}

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

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: const Center(child: Text('消息页面 - 使用MessageController')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: const Center(child: Text('个人资料页面 - 使用ProfileController')),
    );
  }
}
