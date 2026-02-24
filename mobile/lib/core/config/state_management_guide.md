# 状态管理最佳实践指南

## 概述

本指南旨在规范 Bipupu 应用中的状态管理，确保代码的一致性、可维护性和性能优化。基于 Riverpod 2.x 和 Flutter Hooks。

## 核心原则

### 1. 单一数据源
- 每个业务领域的状态应该集中管理
- 避免状态分散在多个地方
- 使用 Provider 暴露状态，而不是直接传递数据

### 2. 不可变状态
- 所有状态类应该是不可变的（使用 `final` 字段）
- 使用 `copyWith` 方法创建新状态
- 避免直接修改状态对象

### 3. 关注点分离
- UI 层只负责显示和用户交互
- 业务逻辑放在 Notifier/Provider 中
- 数据层负责 API 调用和本地存储

## Provider 类型选择指南

### 1. `Provider<T>` - 静态依赖
```dart
// 用于提供不变的依赖项
final dioClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
});
```

### 2. `NotifierProvider<Notifier, State>` - 可变状态
```dart
// 用于管理可变状态
final authStatusNotifierProvider = 
    NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    return AuthStatus.unknown;
  }
  
  Future<void> login(String username, String password) async {
    // 业务逻辑
  }
}
```

### 3. `FutureProvider<T>` - 异步数据
```dart
// 用于加载异步数据
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authStatus = ref.watch(authStatusNotifierProvider);
  if (authStatus != AuthStatus.authenticated) return null;
  
  final restClient = ref.read(restClientProvider);
  final response = await restClient.getCurrentUser();
  return UserModel.fromJson(response.data);
});
```

### 4. `StreamProvider<T>` - 流数据
```dart
// 用于监听数据流
final messageStreamProvider = StreamProvider<List<MessageResponse>>((ref) {
  final pollingService = ref.watch(pollingServiceProvider);
  return pollingService.messageStream;
});
```

## 状态更新最佳实践

### 1. 在 build 方法中初始化
```dart
@override
AuthStatus build() {
  // 使用 addPostFrameCallback 避免在 build 期间执行副作用
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAuth();
  });
  return AuthStatus.unknown;
}
```

### 2. 异步操作中的状态管理
```dart
Future<bool> login(String username, String password) async {
  state = AuthStatus.loggingIn;
  
  try {
    // 执行异步操作
    final response = await restClient.login({...});
    
    // 使用 Future.microtask 确保在下一个事件循环中更新状态
    Future.microtask(() {
      if (state != AuthStatus.loggingIn) {
        debugPrint('状态已变更，跳过更新');
        return;
      }
      state = AuthStatus.authenticated;
    });
    return true;
  } catch (e) {
    Future.microtask(() {
      if (state != AuthStatus.loggingIn) return;
      state = AuthStatus.unauthenticated;
    });
    return false;
  }
}
```

### 3. 避免在异步回调中直接使用 ref
```dart
// ❌ 错误做法
useEffect(() {
  someAsyncOperation().then((result) {
    ref.read(someProvider.notifier).update(result); // 可能已卸载
  });
}, []);

// ✅ 正确做法
useEffect(() {
  final currentRef = ref;
  someAsyncOperation().then((result) {
    if (!mounted) return; // 检查是否已卸载
    currentRef.read(someProvider.notifier).update(result);
  });
}, []);
```

## Widget 生命周期管理

### 1. HookConsumerWidget 中的安全访问
```dart
class LoginPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    
    void handleLogin() async {
      // 保存当前 widget 的引用
      final currentRef = ref;
      final currentContext = context;
      
      isLoading.value = true;
      
      try {
        final result = await someAsyncOperation();
        
        // 检查 widget 是否仍然 mounted
        if (!mounted) {
          debugPrint('Widget 已卸载，跳过后续处理');
          return;
        }
        
        // 安全地使用 ref 和 context
        currentRef.read(authProvider.notifier).login(result);
      } catch (e) {
        if (!mounted) return;
        // 错误处理
      } finally {
        // 检查 widget 是否仍然 mounted
        if (mounted && isLoading.value) {
          isLoading.value = false;
        }
      }
    }
  }
}
```

### 2. useEffect 中的清理
```dart
useEffect(() {
  final subscription = someStream.listen((data) {
    if (!mounted) return;
    // 处理数据
  });
  
  return () {
    subscription.cancel(); // 清理资源
  };
}, []);
```

## 性能优化

### 1. 选择性监听
```dart
// ❌ 监听整个对象（可能导致不必要的重建）
final user = ref.watch(userProvider);

// ✅ 只监听需要的部分
final userName = ref.watch(userProvider.select((user) => user.name));
```

### 2. 使用 read 而不是 watch
```dart
// 在事件处理中，使用 read 而不是 watch
void handleButtonClick() {
  final service = ref.read(someServiceProvider); // 不会触发重建
  service.doSomething();
}

// 在 build 方法中，使用 watch 响应状态变化
Widget build(BuildContext context, WidgetRef ref) {
  final isLoading = ref.watch(isLoadingProvider); // 会响应状态变化
  // ...
}
```

### 3. 避免在 build 方法中创建新对象
```dart
// ❌ 错误做法 - 每次 build 都创建新列表
Widget build(BuildContext context, WidgetRef ref) {
  final items = [Item1(), Item2(), Item3()]; // 新对象
  return ListView(children: items);
}

// ✅ 正确做法 - 使用常量或状态管理
final itemsProvider = Provider<List<Item>>((ref) => [
  Item1(),
  Item2(),
  Item3(),
]);

Widget build(BuildContext context, WidgetRef ref) {
  final items = ref.watch(itemsProvider); // 复用对象
  return ListView(children: items);
}
```

## 错误处理

### 1. 统一的错误处理模式
```dart
class ApiService {
  Future<ApiResponse<T>> handleApiCall<T>(
    Future<T> apiCall, {
    String? errorMessage,
  }) async {
    try {
      final data = await apiCall;
      return ApiResponse.success(data);
    } on DioException catch (e) {
      final error = _parseDioError(e);
      return ApiResponse.error(error, statusCode: e.response?.statusCode);
    } catch (e) {
      return ApiResponse.error(errorMessage ?? '未知错误: $e');
    }
  }
}
```

### 2. 用户友好的错误提示
```dart
void showErrorToast(WidgetRef ref, dynamic error) {
  final errorMsg = error.toString();
  
  if (errorMsg.contains('Connection refused')) {
    ToastUtils.showError(ref, '无法连接到服务器，请检查网络连接');
  } else if (errorMsg.contains('timeout')) {
    ToastUtils.showError(ref, '连接超时，请稍后重试');
  } else {
    ToastUtils.showError(ref, '操作失败：${error.toString().split(':').last.trim()}');
  }
}
```

## 测试策略

### 1. Provider 测试
```dart
test('auth notifier login success', () async {
  final container = ProviderContainer();
  final notifier = container.read(authStatusNotifierProvider.notifier);
  
  await notifier.login('test', 'password');
  
  expect(
    container.read(authStatusNotifierProvider),
    AuthStatus.authenticated,
  );
});
```

### 2. Widget 测试
```dart
testWidgets('LoginPage shows error on failed login', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStatusNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
      ],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
  
  await tester.tap(find.text('登录'));
  await tester.pump();
  
  expect(find.text('登录失败'), findsOneWidget);
});
```

## 常见陷阱和解决方案

### 1. Provider 循环依赖
```dart
// ❌ 错误 - 循环依赖
final providerA = Provider((ref) {
  final b = ref.watch(providerB); // 依赖 B
  return A(b);
});

final providerB = Provider((ref) {
  final a = ref.watch(providerA); // 依赖 A
  return B(a);
});

// ✅ 解决方案 - 使用 read 或重构设计
final providerA = Provider((ref) {
  return A();
});

final providerB = Provider((ref) {
  final a = ref.read(providerA); // 使用 read 而不是 watch
  return B(a);
});
```

### 2. 异步状态竞争条件
```dart
// 使用状态检查避免竞争条件
Future<void> someAsyncOperation() async {
  final currentState = state;
  if (currentState != ExpectedState) return;
  
  final result = await apiCall();
  
  if (state != currentState) {
    debugPrint('状态已变更，跳过更新');
    return;
  }
  
  state = NewState(result);
}
```

## 代码审查清单

- [ ] 是否使用了正确的 Provider 类型？
- [ ] 状态类是否是不可变的？
- [ ] 异步操作中是否有 mounted 检查？
- [ ] 是否有适当的错误处理？
- [ ] 是否避免了不必要的重建？
- [ ] 是否有资源清理（useEffect 返回函数）？
- [ ] 是否遵循了关注点分离？
- [ ] 是否有适当的日志记录？

## 总结

良好的状态管理是 Flutter 应用成功的关键。遵循这些最佳实践可以确保：
1. 代码可维护性和可读性
2. 应用性能和响应速度
3. 错误处理和用户体验
4. 团队协作的一致性

定期回顾和更新这些实践，以适应项目的发展和 Flutter 生态的变化。