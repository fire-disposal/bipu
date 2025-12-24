# Core 模块使用说明

## 📋 概述

Core 模块是 Bipupu Flutter 应用的核心功能库，为 `app_user`（用户端）和 `app_admin`（管理端）提供共享的基础功能。采用分层架构设计，确保代码的可维护性、可测试性和可扩展性。

## 🏗️ 架构设计

### 分层架构

```
core/
├── foundation/          # 基础工具层 - 纯工具类，不依赖其他业务模块
├── data/               # 数据访问层 - 数据模型、存储、API客户端
├── domain/            # 业务逻辑层 - 认证、BLE等核心业务服务
├── injection/         # 依赖注入 - 服务定位器配置
├── app_initializer.dart  # 应用初始化器
├── app_theme.dart     # 主题配置
└── core.dart          # 主入口，统一导出所有功能
```

### 依赖关系

```
foundation ← data ← domain
     ↑        ↑       ↑
     └───────┴───────┘
        injection
```

## 🚀 快速开始

### 1. 基础初始化

```dart
import 'package:your_app/core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化核心服务
  await AppInitializer.initialize(
    enableBluetooth: true,    // 是否启用蓝牙功能
    validateAuth: true,       // 是否验证认证状态
    baseUrl: 'http://api.example.com', // 可选：自定义API地址
  );
  
  runApp(const MyApp());
}
```

### 2. 双入口配置

#### 用户端配置（app_user）
```dart
// main.dart
await AppInitializer.initialize(
  enableBluetooth: true,   // 用户端需要蓝牙功能
  validateAuth: true,
);
```

#### 管理端配置（app_admin）
```dart
// main.dart
await AppInitializer.initialize(
  enableBluetooth: false,  // 管理端不需要蓝牙功能
  validateAuth: true,
);
```

### 3. 使用核心服务

```dart
import 'package:your_app/core/core.dart';

// 获取认证服务
final authService = ServiceLocatorConfig.get<AuthService>();

// 用户登录
final result = await authService.login(
  username: 'user@example.com',
  password: 'password123',
);

// 获取蓝牙服务（如果已启用）
if (ServiceLocatorConfig.isRegistered<BleService>()) {
  final bleService = ServiceLocatorConfig.get<BleService>();
  await bleService.startScan();
}
```

## 📦 功能模块

### Foundation（基础工具）

```dart
// 日志记录
Logger.info('应用启动');
Logger.debug('调试信息');
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