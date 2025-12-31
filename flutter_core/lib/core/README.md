# Core 模块

Core 模块是 Bipupu Flutter 应用的核心基础设施库，为 `apps/user_app`（用户端）和 `apps/admin_app`（管理端）提供共享的基础功能。

## 🏗️ 架构设计

采用扁平化、无依赖注入（No-DI）的架构设计，强调简单、直观和可控。

### 目录结构

```
core/
├── config/          # 环境配置与常量
│   └── app_config.dart
├── network/         # 网络层
│   ├── api_client.dart      # Dio 封装单例
│   ├── auth_interceptor.dart # JWT 自动注入与刷新
│   └── api_endpoints.dart   # API 路径常量
├── services/        # 全局业务服务
│   ├── auth_service.dart    # 认证状态管理
│   └── ble/                 # 蓝牙服务模块
├── storage/         # 本地存储
│   └── token_storage.dart   # Token 安全存储
├── utils/           # 工具类
│   ├── logger.dart
│   ├── validators.dart
│   └── constants.dart
└── widgets/         # 核心共享组件
    └── auth_wrapper.dart    # 认证状态路由守卫
```

## 🚀 核心原则

1.  **单例模式 (Singleton)**: 核心服务如 `ApiClient`, `AuthService` 使用单例模式，无需复杂的依赖注入框架。
2.  **手动模型 (Manual Models)**: 数据模型在 `lib/models/` 下手动维护，不依赖自动生成代码，更灵活可控。
3.  **统一入口**: `main.dart` 统一初始化核心服务（如 Hive），然后根据环境参数启动不同的 App。

## 📦 关键模块说明

### Network (网络层)

*   **ApiClient**: 封装了 `Dio` 实例，配置了 BaseURL 和超时时间。
*   **AuthInterceptor**: 
    *   请求时自动从 `TokenStorage` 读取 Access Token 并添加到 Header。
    *   响应 401 时自动触发登出（未来可扩展 Token 刷新逻辑）。

### Services (服务层)

*   **AuthService**: 
    *   管理登录 (`login`)、登出 (`logout`)。
    *   暴露 `authState` (ValueNotifier) 供 UI 监听认证状态变化。
    *   维护 `currentUser` 信息。

### Storage (存储层)

*   **TokenStorage**: 使用 `flutter_secure_storage` 安全存储 JWT Token。

## 📱 使用示例

### 监听认证状态

```dart
ValueListenableBuilder<AuthStatus>(
  valueListenable: AuthService().authState,
  builder: (context, status, child) {
    if (status == AuthStatus.authenticated) {
      return HomePage();
    } else {
      return LoginPage();
    }
  },
);
```

### 发起网络请求

```dart
// 在 Repository 中
final response = await ApiClient().dio.get(ApiEndpoints.users);
```
Logger.warning('警告信息');
Logger.error('错误信息', error, stackTrace);

// 常量使用
final baseUrl = ApiConstants.defaultBaseUrl;
final timeout = ApiConstants.defaultConnectionTimeout;

// 输入验证
final emailError = EmailValidator.validate('invalid-email');
final passwordError = PasswordValidator.validate('123');
```

### Data（数据访问）

```dart
// JWT令牌管理
final jwtStorage = ServiceLocatorConfig.get<JwtStorage>();
await jwtStorage.saveToken(jwtToken);
final token = await jwtStorage.getToken();

// API客户端
final apiClient = ServiceLocatorConfig.get<ApiClient>();
apiClient.setAuthToken('your-jwt-token');

// 应用配置
final config = AppConfig.user(); // 用户端配置
final adminConfig = AppConfig.admin(); // 管理端配置
```

### Domain（业务逻辑）

```dart
// 认证服务
final authService = ServiceLocatorConfig.get<AuthService>();
final authResult = await authService.login(username: 'user', password: 'pass');
final isAuthenticated = authService.isAuthenticated();
final userInfo = await authService.getCurrentUser();

// BLE服务（如果启用）
final bleService = ServiceLocatorConfig.get<BleService>();
await bleService.initialize();
await bleService.startScan();
final devices = bleService.getConnectedDevices();

// 设备控制服务
final deviceControl = ServiceLocatorConfig.get<DeviceControlService>();
await deviceControl.connectToDevice('device-id');
await deviceControl.sendSimpleNotification(text: 'Hello!');
```

### Presentation（UI组件）

```dart
// 按钮组件
CoreButton.primary(
  text: '登录',
  onPressed: () => handleLogin(),
  isLoading: isLoading,
)

CoreButton.outlined(
  text: '取消',
  onPressed: () => Navigator.pop(context),
)

// 卡片组件
CoreCard.elevated(
  child: Column(
    children: [/* 内容 */],
  ),
)

// 统计面板
CoreStatPanel(
  title: '设备统计',
  stats: [
    StatCard(title: '总数', value: '100'),
    StatCard(title: '在线', value: '85'),
  ],
)

// 状态组件
UnifiedLoadingIndicator(message: '加载中...')
UnifiedErrorWidget(
  message: '网络连接失败',
  onRetry: () => retry(),
)
UnifiedEmptyWidget(
  message: '暂无数据',
  buttonText: '添加设备',
  onButtonPressed: () => addDevice(),
)
```

### Injection（依赖注入）

```dart
// 获取服务
final authService = ServiceLocatorConfig.get<AuthService>();
final apiClient = ServiceLocatorConfig.get<ApiClient>();

// 检查服务是否注册
if (ServiceLocatorConfig.isRegistered<BleService>()) {
  final bleService = ServiceLocatorConfig.get<BleService>();
}

// 重置所有服务
ServiceLocatorConfig.reset();
```

## 🎨 主题配置

```dart
// 使用预定义主题
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)

// 主题特性
// - Material 3 设计
// - 响应式颜色方案
// - 统一的组件样式
// - 支持亮色/暗色模式
```

## 🔧 高级配置

### 自定义应用配置

```dart
// 创建自定义配置
final customConfig = AppConfig(
  baseUrl: 'https://api.custom.com',
  connectionTimeout: 60,
  appType: AppType.user,
  enabledFeatures: {
    AppFeature.auth,
    AppFeature.ble,
    AppFeature.messaging,
  },
);

// 使用自定义配置初始化
await ServiceLocatorConfig.initialize(appConfig: customConfig);
```

### 功能开关

```dart
final config = ServiceLocatorConfig.get<AppConfig>();

// 检查功能是否启用
if (config.isFeatureEnabled(AppFeature.ble)) {
  // BLE功能可用
}

if (config.isFeatureEnabled(AppFeature.userManagement)) {
  // 用户管理功能可用（管理端）
}
```

## 🚨 错误处理

```dart
try {
  await authService.login(username: 'user', password: 'pass');
} on AuthException catch (e) {
  // 认证相关错误
  Logger.error('认证失败: ${e.message}');
} on BleException catch (e) {
  // BLE相关错误
  Logger.error('蓝牙错误: ${e.message}');
} catch (e) {
  // 其他错误
  Logger.error('未知错误', e);
}
```

## 📋 最佳实践

### 1. 服务获取
- 使用 `ServiceLocatorConfig.get<T>()` 获取服务实例
- 避免直接实例化服务类
- 在需要时检查服务是否已注册

### 2. 错误处理
- 使用 try-catch 包裹异步操作
- 利用专门的异常类（如 `AuthException`, `BleException`）
- 记录详细的错误信息

### 3. 状态管理
- 认证状态通过 `AuthService` 统一管理
- 使用 `AppInitializer.getStatus()` 获取应用整体状态
- 避免直接操作底层存储

### 4. 双入口适配
- 用户端启用蓝牙功能 (`enableBluetooth: true`)
- 管理端禁用蓝牙功能 (`enableBluetooth: false`)
- 通过 `AppConfig` 控制功能集合

## 🔍 调试支持

```dart
// 设置日志级别
Logger.setLogLevel(LogLevel.debug);

// 获取应用状态
final status = await AppInitializer.getStatus();
print('认证状态: ${status.isAuthenticated}');
print('令牌有效: ${status.hasValidToken}');
print('应用健康: ${status.isHealthy}');
```

## 📚 相关文档

- [Flutter 官方文档](https://flutter.dev/docs)
- [GetIt 依赖注入](https://pub.dev/packages/get_it)
- [Dio HTTP 客户端](https://pub.dev/packages/dio)
- [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus)

## 🤝 贡献指南

1. 遵循分层架构原则
2. 为新功能添加相应的测试
3. 更新文档和示例代码
4. 保持向后兼容性

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](../../LICENSE) 文件