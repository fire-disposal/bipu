/// 管理端应用入口文件
/// 加载 admin_app 模块，提供管理功能
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/core.dart';
import 'core/utils/injected_dependencies.dart';
import 'admin_app/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化核心服务
  await _initializeCoreServices();

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AdminApp());
}

/// 初始化核心服务
Future<void> _initializeCoreServices() async {
  try {
    // 初始化依赖注入
    await initDependencies();

    // 初始化API客户端
    await ApiClient.instance.initialize();

    Logger.info('管理端核心服务初始化完成');
  } catch (e) {
    Logger.error('管理端核心服务初始化失败: $e');
    rethrow;
  }
}

/// 管理端应用主类
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bipupu 管理端',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: adminRouter,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
