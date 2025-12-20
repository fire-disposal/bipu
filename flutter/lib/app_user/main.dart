/// 用户端应用入口文件
/// 现代蓝牙寻呼机设备用户端应用
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/core.dart';
import '../core/utils/injected_dependencies.dart';
import 'routes.dart';
import 'state/user_data_cubit.dart' as user_data;
import 'state/device_control_state.dart';

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

  runApp(const UserApp());
}

/// 初始化核心服务
Future<void> _initializeCoreServices() async {
  try {
    // 初始化依赖注入
    await initDependencies();

    // 初始化蓝牙服务（可选，失败不影响应用启动）
    try {
      await BluetoothService.instance.initialize();
    } catch (e) {
      Logger.warning('蓝牙服务初始化失败，将在需要时重试: $e');
      // 蓝牙初始化失败不影响应用主要功能
    }

    // 初始化API客户端
    await ApiClient.instance.initialize();

    Logger.info('用户端核心服务初始化完成');
  } catch (e) {
    Logger.error('用户端核心服务初始化失败: $e');
    // 只有核心服务初始化失败才抛出异常
    if (e is! UnsupportedError) {
      rethrow;
    }
  }
}

/// 用户端应用主类
class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => user_data.UserDataCubit()),
        BlocProvider(create: (context) => DeviceControlCubit()),
      ],
      child: MaterialApp.router(
        title: 'Bipupu 寻呼机',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, child) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
