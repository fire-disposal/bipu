# 新一代网络接口封装

## 概述

这是一套围绕自动生成的 `RestClient` 构建的新一代网络接口封装，提供统一的异常处理、Token 管理、日志输出和简单方便的请求接口。

## 架构设计

### 核心组件

#### 1. [`api_exception.dart`](api_exception.dart) - 异常处理
定义了统一的异常体系：
- `ApiException` - 基类
- `NetworkException` - 网络异常（超时、连接错误等）
- `AuthException` - 认证异常（401、403、Token 过期等）
- `ServerException` - 服务器异常（5xx 错误）
- `ValidationException` - 验证异常（400 错误）
- `ParseException` - 解析异常

#### 2. [`api_interceptor.dart`](api_interceptor.dart) - 拦截器
处理以下功能：
- **Token 管理**：自动附加 Bearer Token 到请求头
- **公开端点白名单**：跳过不需要认证的接口
- **错误处理**：捕获 401 错误并清除本地认证信息
- **日志输出**：使用 `logger` 包输出详细的请求/响应日志

#### 3. [`api_client.dart`](api_client.dart) - API 客户端
围绕生成的 `RestClient` 的封装：
- **单例模式**：全局唯一实例
- **Dio 初始化**：配置基础 URL、超时时间、拦截器
- **异常转换**：将 `DioException` 转换为 `ApiException`
- **请求执行**：提供 `execute()` 方法统一处理请求

#### 4. [`api_service.dart`](api_service.dart) - API 服务
提供便捷的 API 调用方法：
- **认证相关**：登录、注册、刷新 Token、登出、验证 Token
- **用户资料**：获取用户信息、更新密码、更新时区
- **消息相关**：获取消息、发送消息、轮询消息
- **联系人相关**：获取、创建、更新、删除联系人
- **黑名单相关**：获取黑名单、屏蔽/取消屏蔽用户
- **用户搜索**：搜索用户、获取用户信息
- **收藏相关**：获取、添加、移除收藏
- **系统相关**：获取系统状态（健康、就绪、活跃）
- **海报相关**：获取海报列表
- **服务账户相关**：获取、订阅、取消订阅、管理设置

## 使用指南

### 基础使用

#### 1. 登录

```dart
import 'package:bipupu/core/network/network.dart';

try {
  final token = await ApiService.instance.login(
    username: 'user@example.com',
    password: 'password123',
  );
  print('登录成功: ${token.accessToken}');
} on AuthException catch (e) {
  print('认证失败: ${e.message}');
} on NetworkException catch (e) {
  print('网络错误: ${e.message}');
}
```

#### 2. 获取当前用户信息

```dart
try {
  final user = await ApiService.instance.getCurrentUser();
  print('用户名: ${user.username}');
} on AuthException catch (e) {
  // Token 过期或无效，需要重新登录
  print('需要重新登录: ${e.message}');
}
```

#### 3. 发送消息

```dart
try {
  final message = await ApiService.instance.sendMessage(
    content: 'Hello, World!',
    recipientId: 'user_id_123',
  );
  print('消息已发送: ${message.id}');
} on ValidationException catch (e) {
  print('验证失败: ${e.message}');
  if (e.errors != null) {
    print('错误详情: ${e.errors}');
  }
}
```

#### 4. 搜索用户

```dart
try {
  final users = await ApiService.instance.searchUsers(query: 'john');
  for (final user in users) {
    print('${user.username} - ${user.bipupuId}');
  }
} on ServerException catch (e) {
  print('服务器错误: ${e.message}');
}
```

### 高级使用

#### 1. 直接使用 RestClient

如果 `ApiService` 中没有提供的方法，可以直接使用 `RestClient`：

```dart
final apiClient = ApiClient.instance;
final restClient = apiClient.api;

// 直接调用生成的 API 方法
final result = await restClient.users.getUser(userId: 'user_id_123');
```

#### 2. 自定义请求执行

```dart
final apiClient = ApiClient.instance;

try {
  final result = await apiClient.execute(
    () => apiClient.api.customEndpoint.someMethod(),
    operationName: 'CustomOperation',
  );
} on ApiException catch (e) {
  print('API 错误: ${e.message}');
}
```

#### 3. 异常处理

```dart
try {
  await ApiService.instance.login(username: 'user', password: 'pass');
} catch (e) {
  ApiService.instance.handleException(e);
  
  // 或者获取异常消息
  final message = ApiService.instance.getExceptionMessage(e);
  print('错误: $message');
}
```

#### 4. 添加自定义拦截器

```dart
final apiClient = ApiClient.instance;

// 添加自定义拦截器
apiClient.addInterceptor(MyCustomInterceptor());

// 移除拦截器
apiClient.removeInterceptor(myInterceptor);

// 清除所有拦截器
apiClient.clearInterceptors();

// 重置 Dio 实例
apiClient.reset();
```

## 特性

### ✅ Token 管理
- 自动从 `FlutterSecureStorage` 读取 Token
- 自动附加到请求头
- 支持公开端点白名单
- 401 错误时自动清除本地 Token

### ✅ 错误处理
- 统一的异常体系
- 详细的错误信息
- 自动异常转换
- 支持自定义错误处理

### ✅ 日志输出
- 使用 `logger` 包输出彩色日志
- 请求/响应详细信息
- 错误堆栈跟踪
- 仅在 Debug 模式下输出

### ✅ 简单方便
- 单例模式，全局访问
- 预定义的常用 API 方法
- 自动异常处理
- 支持直接访问 RestClient

## 配置

### 基础 URL

基础 URL 通过环境变量配置：

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

默认值：`https://api.205716.xyz`

### 超时时间

在 [`api_client.dart`](api_client.dart) 中修改：

```dart
connectTimeout: const Duration(seconds: 15),
receiveTimeout: const Duration(seconds: 15),
sendTimeout: const Duration(seconds: 15),
```

### 日志级别

在 [`api_interceptor.dart`](api_interceptor.dart) 中修改 `Logger` 配置。

## 迁移指南

### 从旧网络层迁移

#### 旧代码
```dart
import 'package:bipupu/core/network/network_service.dart';

final networkService = NetworkService.instance;
final user = await networkService.api.userProfile.getMe();
```

#### 新代码
```dart
import 'package:bipupu/core/network/network.dart';

final user = await ApiService.instance.getCurrentUser();
```

## 常见问题

### Q: 如何处理 Token 过期？
A: 当收到 `AuthException` 时，应该清除本地数据并重定向到登录页。拦截器会自动清除 Token。

### Q: 如何添加自定义请求头？
A: 在 `ApiClient._initializeDio()` 中修改 `BaseOptions.headers`。

### Q: 如何处理文件上传？
A: 使用生成的 API 方法，例如 `api.userProfile.postApiProfileAvatar(file: file)`。

### Q: 如何调试网络请求？
A: 启用 Debug 模式，日志会自动输出到控制台。

## 相关文件

- [`api_exception.dart`](api_exception.dart) - 异常定义
- [`api_interceptor.dart`](api_interceptor.dart) - 拦截器实现
- [`api_client.dart`](api_client.dart) - API 客户端
- [`api_service.dart`](api_service.dart) - API 服务
- [`network.dart`](network.dart) - 导出文件
- `package:bipupu/generated/api/export.dart` - 生成的 API 导出

## 最佳实践

1. **使用 ApiService**：优先使用 `ApiService` 中的预定义方法
2. **异常处理**：始终使用 try-catch 处理 API 调用
3. **Token 管理**：不要手动管理 Token，由拦截器自动处理
4. **日志输出**：使用 `logger` 包而不是 `print()`
5. **错误消息**：使用 `getExceptionMessage()` 获取用户友好的错误消息

## 支持

如有问题或建议，请联系开发团队。
