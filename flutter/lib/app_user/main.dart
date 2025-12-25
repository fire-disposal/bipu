/// 用户端应用入口文件
/// 现代蓝牙寻呼机设备用户端应用
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/core.dart';
import 'routes.dart';
import 'state/user_state.dart';
import 'services/services.dart';

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
    // 使用核心初始化器统一初始化所有核心模块
    await AppInitializer.initialize(enableBluetooth: true, validateAuth: true);

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
    // 优化依赖注入写法，避免未注册异常
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserDataCubit>(
          create: (context) =>
              ServiceLocatorConfig.isRegistered<UserDataCubit>()
              ? ServiceLocatorConfig.get<UserDataCubit>()
              : UserDataCubit(),
        ),
        BlocProvider<DeviceControlCubit>(
          create: (context) =>
              ServiceLocatorConfig.isRegistered<DeviceControlCubit>()
              ? ServiceLocatorConfig.get<DeviceControlCubit>()
              : DeviceControlCubit(),
        ),
        BlocProvider<HomeCubit>(
          create: (context) => HomeCubit(
            deviceControlCubit: context.read<DeviceControlCubit>(),
            userDataCubit: context.read<UserDataCubit>(),
          ),
        ),
        BlocProvider<CallCubit>(
          create: (context) =>
              CallCubit(deviceControlCubit: context.read<DeviceControlCubit>()),
        ),
        BlocProvider<MessageCubit>(
          create: (context) =>
              MessageCubit(userDataCubit: context.read<UserDataCubit>()),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            authService: ServiceLocatorConfig.get<AuthService>(),
            userDataCubit: context.read<UserDataCubit>(),
          ),
        ),
      ],
      child: _UserAppWithServices(
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
      ),
    );
  }
}

/// 包含服务的用户应用包装器
class _UserAppWithServices extends StatefulWidget {
  final Widget child;

  const _UserAppWithServices({required this.child});

  @override
  State<_UserAppWithServices> createState() => _UserAppWithServicesState();
}

class _UserAppWithServicesState extends State<_UserAppWithServices> {
  late final LocalBleService _localBleService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // 获取必要的服务
      final deviceControlService =
          ServiceLocatorConfig.get<DeviceControlService>();
      final userDataCubit = context.read<UserDataCubit>();

      // 创建本地蓝牙服务
      _localBleService = LocalBleService(
        deviceControlService: deviceControlService,
        userDataCubit: userDataCubit,
      );

      // 初始化本地蓝牙服务
      await _localBleService.initialize();

      Logger.info('用户端服务初始化完成');
    } catch (e) {
      Logger.error('用户端服务初始化失败: $e');
      // 不阻止应用启动，蓝牙功能将在需要时初始化
    }
  }

  @override
  void dispose() {
    _localBleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
