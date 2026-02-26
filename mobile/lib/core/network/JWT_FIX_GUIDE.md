# JWT 401 错误修复指南

## 问题描述

应用在登录成功后，后续 API 请求仍然返回 401 错误，表示 Token 未被正确保存或附加到请求头。

错误日志示例：
```
[E]  ❌ ERROR: 401 https://api.205716.xyz/api/service_accounts/?skip=0&limit=100
[W]  🔒 Token失效或未授权，清除本地认证信息
```

## 根本原因分析

JWT 处理流程中存在以下可能的问题：

1. **Token 保存问题**：`TokenManager.saveTokens()` 未正确保存 Token 到 `StorageManager`
2. **Token 读取问题**：`ApiInterceptor` 未能正确从存储中读取 Token
3. **Token 附加问题**：Token 未被正确附加到请求头
4. **存储问题**：`StorageManager.setSecureData()` 或 `getSecureData()` 失败

## 修复方案

### 1. 增强 Token 保存日志 (`token_manager.dart`)

```dart
static Future<void> saveTokens({
  required String accessToken,
  String? refreshToken,
}) async {
  try {
    if (accessToken.isEmpty) {
      throw Exception('Access token cannot be empty');
    }
    
    await StorageManager.setSecureData(_accessTokenKey, accessToken);
    debugPrint('✅ Access token saved: ${accessToken.substring(0, 20)}...');
    
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await StorageManager.setSecureData(_refreshTokenKey, refreshToken);
      debugPrint('✅ Refresh token saved: ${refreshToken.substring(0, 20)}...');
    }
    
    debugPrint('✅ All tokens saved successfully');
  } catch (e) {
    debugPrint('❌ Error saving tokens: $e');
    rethrow;
  }
}
```

**改进点**：
- 验证 Token 不为空
- 打印 Token 前缀用于调试
- 分别记录 Access Token 和 Refresh Token 的保存状态

### 2. 增强 Token 读取日志 (`token_manager.dart`)

```dart
static Future<String?> getAccessToken() async {
  try {
    final token = await StorageManager.getSecureData(_accessTokenKey);
    if (token != null && token.isNotEmpty) {
      debugPrint('✅ Access token retrieved: ${token.substring(0, 20)}...');
    } else {
      debugPrint('⚠️ Access token is null or empty');
    }
    return token;
  } catch (e) {
    debugPrint('❌ Error reading access token: $e');
    return null;
  }
}
```

**改进点**：
- 检查 Token 是否为 null 或空
- 打印 Token 前缀用于调试
- 记录读取失败的原因

### 3. 增强拦截器日志 (`api_interceptor.dart`)

```dart
@override
Future<void> onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  _logger.i('📤 REQUEST: ${options.method} ${options.uri}');

  if (!_shouldSkipAuth(options.uri.path)) {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      _logger.i('✅ Token attached to request: ${token.substring(0, 20)}...');
    } else {
      _logger.w('⚠️ No token available for authenticated endpoint: ${options.uri.path}');
    }
  } else {
    _logger.i('⏭️ Skipping auth for public endpoint: ${options.uri.path}');
  }

  handler.next(options);
}
```

**改进点**：
- 记录 Token 是否被附加
- 记录公开端点的跳过情况
- 记录缺少 Token 的警告

### 4. 增强 Token 读取方法 (`api_interceptor.dart`)

```dart
Future<String?> _getToken() async {
  try {
    final token = await StorageManager.getSecureData(_tokenKey);
    if (token == null || token.isEmpty) {
      _logger.w('⚠️ Token is null or empty in storage');
      return null;
    }
    _logger.i('✅ Token retrieved from storage: ${token.substring(0, 20)}...');
    return token;
  } catch (e) {
    _logger.e('❌ Error reading token from storage', error: e);
    return null;
  }
}
```

**改进点**：
- 检查 Token 是否为 null 或空
- 记录存储读取失败
- 打印 Token 前缀用于调试

### 5. JWT 调试助手 (`jwt_debug_helper.dart`)

新增 `JwtDebugHelper` 类，提供以下诊断方法：

```dart
// 打印完整的 JWT 诊断信息
await JwtDebugHelper.printJwtDiagnostics();

// 验证 Token 是否有效
final isValid = await JwtDebugHelper.validateTokenStorage();

// 清除所有 Token 并验证
await JwtDebugHelper.clearAndVerify();

// 测试 Token 保存和读取
await JwtDebugHelper.testTokenSaveAndRead(testToken);
```

## 使用调试工具

### 在登录后立即诊断

```dart
// 在 AuthService.login() 成功后调用
await JwtDebugHelper.printJwtDiagnostics();
```

### 在 API 请求前诊断

```dart
// 在发送 API 请求前调用
await JwtDebugHelper.printJwtDiagnostics();
final response = await ApiClient.instance.api.serviceAccounts.getApiServiceAccounts();
```

### 在 401 错误时诊断

```dart
try {
  final response = await ApiClient.instance.api.serviceAccounts.getApiServiceAccounts();
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    await JwtDebugHelper.printJwtDiagnostics();
  }
}
```

## 诊断输出示例

### 正常情况

```
═══════════════════════════════════════════════════════════
🔍 JWT 诊断信息
═══════════════════════════════════════════════════════════
📌 Access Token 状态:
   ✅ Access Token 存在
   📊 长度: 256
   🔤 前缀: eyJhbGciOiJIUzI1NiIs...
   🔤 后缀: ...kZXJpZCI6IjEyMzQ1Njc4OTAifQ==
   📋 Token 结构:
      Header: eyJhbGciOiJIUzI1NiIs...
      Payload: eyJzdWIiOiIxMjM0NTY3...
      Signature: kZXJpZCI6IjEyMzQ1Njc4OTAifQ==

📌 Refresh Token 状态:
   ✅ Refresh Token 存在
   📊 长度: 256
   🔤 前缀: eyJhbGciOiJIUzI1NiIs...

📌 TokenManager 状态:
   hasToken(): true
   tokenExpired.value: false

📌 StorageManager 统计:
   缓存项: 5
   用户数据项: 2
   设置项: 3
   临时项: 0
   总项数: 10
═══════════════════════════════════════════════════════════
```

### 异常情况

```
═══════════════════════════════════════════════════════════
🔍 JWT 诊断信息
═══════════════════════════════════════════════════════════
📌 Access Token 状态:
   ❌ Access Token 为 null

📌 Refresh Token 状态:
   ❌ Refresh Token 为空字符串

📌 TokenManager 状态:
   hasToken(): false
   tokenExpired.value: true
═══════════════════════════════════════════════════════════
```

## 常见问题排查

### 问题 1：Token 为 null

**原因**：
- `TokenManager.saveTokens()` 未被调用
- `StorageManager.setSecureData()` 失败
- 存储权限问题

**解决方案**：
1. 检查登录流程是否正确调用 `TokenManager.saveTokens()`
2. 检查 `StorageManager` 是否正确初始化
3. 检查应用权限设置

### 问题 2：Token 为空字符串

**原因**：
- Token 被清除但未重新保存
- 登录失败但未抛出异常

**解决方案**：
1. 检查登录是否真的成功
2. 检查是否有其他代码清除了 Token
3. 检查 Token 值是否为空

### 问题 3：Token 格式不正确

**原因**：
- 服务器返回的 Token 格式不是 JWT
- Token 被截断或损坏

**解决方案**：
1. 检查服务器返回的 Token 格式
2. 检查 Token 是否被正确保存
3. 检查存储是否有大小限制

### 问题 4：Token 未被附加到请求头

**原因**：
- 拦截器未被正确添加
- 端点被错误地标记为公开
- Token 读取失败

**解决方案**：
1. 检查 `ApiInterceptor` 是否被添加到 Dio
2. 检查 `_publicEndpoints` 白名单
3. 检查 Token 读取是否成功

## 最佳实践

1. **始终验证 Token**：在保存前验证 Token 不为空
2. **记录详细日志**：使用增强的日志记录 Token 操作
3. **定期诊断**：在关键操作后调用诊断工具
4. **处理 401 错误**：收到 401 时自动清除 Token 并重定向到登录
5. **测试 Token 流程**：在开发过程中定期测试 Token 保存和读取

## 相关文件

- [`token_manager.dart`](token_manager.dart) - Token 管理
- [`api_interceptor.dart`](api_interceptor.dart) - 请求拦截
- [`jwt_debug_helper.dart`](jwt_debug_helper.dart) - 调试工具
- [`api_client.dart`](api_client.dart) - API 客户端
- [`storage_manager.dart`](../storage/storage_manager.dart) - 存储管理

## 支持

如有问题或建议，请联系开发团队。
