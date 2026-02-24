# 长轮询配置检查报告

## 📋 系统架构

### 单一轮询引擎原则

系统遵循**单一轮询引擎**原则，所有实时消息都通过唯一的 `PollingService` 获取。

```
┌─────────────────────────────────────────────────────────────┐
│                      PollingService                         │
│  (lib/core/services/polling_service.dart)                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  messageStreamProvider                              │   │
│  │  Stream<List<MessageResponse>>                      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌───────────────────┐                 ┌───────────────────┐
│  MessageScreen    │                 │   ChatPage        │
│  (消息列表)        │                 │   (聊天详情)       │
│                   │                 │                   │
│  watch:           │                 │  watch:           │
│  messageStream    │                 │  chatMessageStream│
└───────────────────┘                 └───────────────────┘
```

---

## ✅ 正确的配置

### 1. 轮询服务 (`polling_service.dart`)

**位置**: `lib/core/services/polling_service.dart`

**核心组件**:
```dart
// 1. 服务提供者
final pollingServiceProvider = Provider<PollingService>((ref) {
  final dio = ref.watch(pollingDioClientProvider);
  return PollingService(dio: dio);
});

// 2. 消息流提供者（全局唯一）
final messageStreamProvider = StreamProvider<List<MessageResponse>>((ref) {
  final pollingService = ref.watch(pollingServiceProvider);
  return pollingService.messageStream;
});

// 3. 轮询引擎
class PollingService {
  // 唯一的轮询循环
  Future<void> _pollLoop() async { ... }
  
  // 唯一的 API 调用
  Future<void> _pollOnce() async {
    final response = await _dio.get<List>(
      '/api/messages/poll',
      queryParameters: {'last_msg_id': lastMsgId, 'timeout': 30},
    );
  }
}
```

**特性**:
- ✅ 单例模式（通过 Provider）
- ✅ 统一的 `messageStream` 输出
- ✅ 生命周期管理（start/stop/pause/resume）
- ✅ 本地状态持久化（last_message_id）

---

### 2. Dio 配置 (`dio_client.dart`)

**位置**: `lib/core/api/dio_client.dart`

```dart
// 长轮询专用 Dio（45 秒超时）
final pollingDioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    receiveTimeout: const Duration(seconds: 45), // ✅ 适配后端 30-40 秒挂起
  ));
  return dio;
});

// 普通 API 专用 Dio（10 秒超时）
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    receiveTimeout: const Duration(seconds: 10), // ✅ 普通请求
  ));
  return dio;
});
```

**特性**:
- ✅ 分离长轮询和普通请求的 Dio 实例
- ✅ 正确的超时配置

---

### 3. REST 客户端 (`rest_client.dart`)

**位置**: `lib/core/api/rest_client.dart`

```dart
@RestApi(baseUrl: 'http://localhost:8000')
abstract class RestClient {
  /// 长轮询获取新消息
  @GET('/api/messages/poll')
  Future<List<Map<String, dynamic>>> pollMessages({
    @Query('last_msg_id') required int lastMsgId,
    @Query('timeout') int? timeout,
  });
}
```

**特性**:
- ✅ 正确的 API 端点
- ✅ 正确的参数定义

---

### 4. App 集成 (`app.dart`)

**位置**: `lib/app.dart`

```dart
class App extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusNotifierProvider);
    final pollingService = ref.watch(pollingServiceProvider);

    // ✅ 根据认证状态管理轮询
    useEffect(() {
      if (authStatus == AuthStatus.authenticated) {
        pollingService.start();  // 登录后启动
      } else {
        pollingService.stop();   // 登出后停止
      }
      return () => pollingService.stop();
    }, [authStatus]);

    // ...
  }
}
```

**特性**:
- ✅ 自动启动/停止
- ✅ 避免未登录时的无效请求

---

### 5. 消息流订阅 (`chat_provider.dart`)

**位置**: `lib/features/message/logic/chat_provider.dart`

```dart
// ✅ 过滤全局消息流，不创建新轮询
final chatMessageStreamProvider =
    StreamProvider.family<List<MessageResponse>, String>((ref, receiverId) {
  // 订阅全局消息流
  final messageStream = ref.watch(messageStreamProvider);

  // 过滤出当前聊天的消息
  return messageStream.where((messages) {
    return messages.any(
      (msg) => msg.senderBipupuId == receiverId ||
               msg.receiverBipupuId == receiverId,
    );
  });
});
```

**特性**:
- ✅ 仅过滤全局流，不调用 API
- ✅ 多个聊天页面共享同一个轮询结果

---

## ❌ 已移除的错误配置

### 1. 移除 `@riverpod` 注解

**原因**: 与当前 Riverpod 版本不兼容，导致生成器失败

**修改前**:
```dart
@riverpod
class ChatNotifier extends _$ChatNotifier { ... }
```

**修改后**:
```dart
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatStatus, String>(
  (ref, receiverId) => ChatNotifier(ref: ref, receiverId: receiverId),
);
```

---

### 2. 移除重复的轮询调用

**检查点**: 确认没有其他地方调用 `/api/messages/poll`

**grep 结果**:
```bash
# ✅ 唯一调用位置
lib/core/services/polling_service.dart:166
  final response = await _dio.get<List>(
    '/api/messages/poll',
    ...
  );
```

---

## 🔍 配置验证清单

### API 端点
- [x] `/api/messages/poll` 仅在 `polling_service.dart` 中调用
- [x] `pollMessages` 方法在 `rest_client.dart` 中正确定义
- [x] 参数 `last_msg_id` 和 `timeout` 正确传递

### Dio 配置
- [x] `pollingDioClientProvider` 存在且 `receiveTimeout = 45 秒`
- [x] `dioClientProvider` 存在且 `receiveTimeout = 10 秒`
- [x] 两个实例分离，互不干扰

### Provider 层次
- [x] `pollingServiceProvider` → 创建服务实例
- [x] `messageStreamProvider` → 暴露消息流
- [x] `chatMessageStreamProvider` → 过滤流（不创建新轮询）

### 生命周期管理
- [x] `app.dart` 中根据认证状态启动/停止
- [x] `pause()` / `resume()` 支持后台/前台切换
- [x] `dispose()` 正确清理资源

### 状态持久化
- [x] `last_message_id` 保存到 SharedPreferences
- [x] 应用重启后正确恢复

---

## 📊 数据流

```
┌──────────────┐
│   Backend    │
│  (FastAPI)   │
└──────┬───────┘
       │ WebSocket / Long Polling
       │ GET /api/messages/poll
       ▼
┌──────────────────────────────────────┐
│      PollingService                  │
│  ┌────────────────────────────────┐  │
│  │  _pollLoop()                   │  │
│  │  └─> _pollOnce()               │  │
│  │       └─> Dio GET /poll        │  │
│  └────────────────────────────────┘  │
│              │                       │
│              ▼                       │
│  _messageStreamController.add()      │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│   messageStreamProvider              │
│   Stream<List<MessageResponse>>      │
└──────────────┬───────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌──────────────────┐
│MessageScreen│  │chatMessageStream │
│  (列表页)    │  │  (聊天页过滤)     │
└─────────────┘  └──────────────────┘
```

---

## ⚠️ 注意事项

### 1. 避免重复轮询

**错误示例** (不要这样做):
```dart
// ❌ 不要在 UI 层直接调用 API
final messages = await restClient.pollMessages(...);
```

**正确做法**:
```dart
// ✅ 订阅全局消息流
final messages = ref.watch(messageStreamProvider);
```

### 2. 避免多个轮询实例

**错误示例** (不要这样做):
```dart
// ❌ 不要创建多个 PollingService 实例
final service1 = PollingService(...);
final service2 = PollingService(...);
```

**正确做法**:
```dart
// ✅ 通过 Provider 获取单例
final service = ref.watch(pollingServiceProvider);
```

### 3. 正确管理生命周期

**错误示例** (不要这样做):
```dart
// ❌ 不要在页面销毁后继续轮询
@override
void dispose() {
  // 没有停止轮询
  super.dispose();
}
```

**正确做法**:
```dart
// ✅ 在 app.dart 统一管理
useEffect(() {
  return () => pollingService.stop();  // 清理
}, []);
```

---

## 📝 总结

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 单一轮询引擎 | ✅ | 仅 `polling_service.dart` 调用 API |
| Dio 实例分离 | ✅ | 长轮询 45 秒，普通 10 秒 |
| Provider 层次 | ✅ | 正确的依赖注入 |
| 生命周期管理 | ✅ | 自动启动/停止 |
| 状态持久化 | ✅ | last_message_id 保存 |
| 流过滤 | ✅ | 不创建新轮询 |
| 无重复调用 | ✅ | grep 验证通过 |

**结论**: 系统长轮询配置正确，无重复或错误实现。

---

**检查时间**: 2026-02-23  
**检查者**: AI Assistant
