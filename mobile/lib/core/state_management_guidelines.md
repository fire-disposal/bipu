# Flutter Riverpod 状态管理指南

## 概述

本文档旨在为 Bipupu 移动应用提供一致的状态管理最佳实践，特别是针对 Riverpod 的使用。通过遵循这些指南，可以避免常见的状态管理错误，如构建过程中修改 provider 状态。

## 核心原则

### 1. 不可变性原则
- 状态应该是不可变的
- 使用 `copyWith` 或创建新实例来更新状态
- 避免直接修改现有状态对象

### 2. 单向数据流
- 数据应该从父组件流向子组件
- 状态更新应该通过明确的事件触发
- 避免双向绑定导致的复杂状态同步

### 3. 关注点分离
- UI 组件只负责渲染
- 业务逻辑放在 provider 或 service 中
- 状态管理逻辑与 UI 逻辑分离

## 最佳实践

### 1. Provider 使用规范

#### 1.1 Provider 类型选择
```dart
// 静态数据：使用 Provider
final configProvider = Provider<AppConfig>((ref) => AppConfig());

// 可变状态：使用 StateNotifierProvider 或 NotifierProvider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// 异步数据：使用 FutureProvider 或 StreamProvider
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final auth = ref.watch(authStateProvider);
  return await fetchUserProfile(auth.userId);
});

// 派生状态：使用 Provider.family 或 Provider.autoDispose
final userAvatarProvider = Provider.family<String, String>((ref, userId) {
  final baseUrl = ref.watch(configProvider).baseUrl;
  return '$baseUrl/api/avatar/$userId';
});
```

#### 1.2 Provider 命名规范
- 状态 provider：`[功能]StateProvider` (如 `authStateProvider`)
- 服务 provider：`[服务]Provider` (如 `avatarServiceProvider`)
- 工具 provider：`[工具]Provider` (如 `loggerProvider`)
- 配置 provider：`[配置]Provider` (如 `appConfigProvider`)

### 2. Widget 构建规范

#### 2.1 禁止在 build 方法中修改状态
```dart
// ❌ 错误：在 build 中修改 provider 状态
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.read(someProvider.notifier).updateState(); // 禁止！
  return Container();
}

// ✅ 正确：使用事件触发状态更新
@override
Widget build(BuildContext context, WidgetRef ref) {
  return ElevatedButton(
    onPressed: () {
      // 在事件回调中修改状态
      ref.read(someProvider.notifier).updateState();
    },
    child: Text('更新'),
  );
}
```

#### 2.2 使用 Consumer 和 HookConsumerWidget
```dart
// 简单场景：使用 Consumer
Consumer(
  builder: (context, ref, child) {
    final state = ref.watch(someProvider);
    return Text('状态: $state');
  },
)

// 复杂场景：使用 HookConsumerWidget
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(someProvider);
    final notifier = ref.read(someProvider.notifier);
    
    return Scaffold(
      body: Center(child: Text('状态: $state')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => notifier.increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### 3. 状态更新模式

#### 3.1 安全的状态更新
```dart
class SafeNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    return {};
  }

  void safeUpdate(String key, String value) {
    // 检查是否在构建过程中
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // 延迟到下一帧执行
      Future.delayed(Duration.zero, () {
        if (ref.mounted) {
          state = {...state, key: value};
        }
      });
    } else {
      state = {...state, key: value};
    }
  }
}
```

#### 3.2 异步状态更新
```dart
class AsyncNotifier extends AsyncNotifier<UserProfile> {
  @override
  FutureOr<UserProfile> build() {
    return _fetchProfile();
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    state = const AsyncLoading();
    try {
      final updated = await _api.updateProfile(newProfile);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

### 4. 缓存策略

#### 4.1 内存缓存
```dart
final cachedProvider = Provider.family<Data, String>((ref, key) {
  final cache = ref.read(cacheProvider);
  final cached = cache[key];
  
  if (cached != null) return cached;
  
  final data = _fetchData(key);
  
  // 延迟缓存，避免在 build 中修改状态
  Future.delayed(Duration.zero, () {
    if (ref.mounted) {
      ref.read(cacheProvider.notifier).cache(key, data);
    }
  });
  
  return data;
});
```

#### 4.2 自动清理
```dart
// 使用 autoDispose 自动清理不再使用的 provider
final temporaryProvider = Provider.autoDispose((ref) {
  // 当最后一个监听者移除时自动清理
  return TemporaryData();
});
```

## 常见问题与解决方案

### 问题 1: "Tried to modify a provider while the widget tree was building"
**原因**: 在 `build`、`initState`、`dispose` 等生命周期方法中修改了 provider 状态。

**解决方案**:
1. 将状态更新移到事件回调中（如 `onPressed`、`onTap`）
2. 使用 `Future.delayed(Duration.zero, () { ... })` 延迟执行
3. 使用 `WidgetsBinding.instance.addPostFrameCallback`

### 问题 2: Provider 依赖循环
**原因**: Provider A 依赖 Provider B，Provider B 又依赖 Provider A。

**解决方案**:
1. 重构代码，打破循环依赖
2. 使用 `ProviderScope.overrides` 提供测试值
3. 将共享逻辑提取到独立的 service 中

### 问题 3: 不必要的重建
**原因**: Widget 监听了不需要的 provider 变化。

**解决方案**:
1. 使用 `select` 只监听需要的部分状态
2. 将大 widget 拆分为多个小 widget
3. 使用 `Consumer` 包裹最小范围

## 代码审查清单

### Provider 定义
- [ ] 是否选择了正确的 provider 类型？
- [ ] 命名是否符合规范？
- [ ] 是否使用了适当的生命周期管理（autoDispose）？
- [ ] 错误处理是否完善？

### Widget 使用
- [ ] 是否在 build 方法中修改了 provider 状态？
- [ ] 是否使用了适当的 Consumer 组件？
- [ ] 是否监听了最小范围的状态？
- [ ] 异步状态是否正确处理了加载和错误？

### 状态更新
- [ ] 状态更新是否是不可变的？
- [ ] 异步操作是否有适当的加载状态？
- [ ] 错误状态是否被正确处理？
- [ ] 状态更新是否在正确的时机执行？

## 性能优化建议

### 1. 减少不必要的重建
```dart
// ❌ 错误：整个 widget 重建
ref.watch(userProvider);

// ✅ 正确：只监听需要的部分
ref.watch(userProvider.select((user) => user.name));
```

### 2. 使用 const 构造函数
```dart
// 尽可能使用 const widget
const SizedBox(height: 16);
const Text('标题');
```

### 3. 延迟加载
```dart
// 使用 FutureProvider 或 StreamProvider 的 lazy 加载
final heavyDataProvider = FutureProvider<HeavyData>((ref) {
  // 只有被监听时才执行
  return _fetchHeavyData();
});
```

## 测试策略

### 1. Provider 测试
```dart
test('auth provider updates state correctly', () {
  final container = ProviderContainer();
  
  // 测试初始状态
  expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
  
  // 测试状态更新
  container.read(authStateProvider.notifier).login('user', 'pass');
  expect(container.read(authStateProvider), isA<AuthAuthenticated>());
});
```

### 2. Widget 测试
```dart
testWidgets('login button triggers auth', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: LoginPage()),
    ),
  );
  
  // 点击登录按钮
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  // 验证状态更新
  expect(find.text('登录成功'), findsOneWidget);
});
```

## 总结

遵循这些指南可以确保：
1. 状态管理代码的一致性和可维护性
2. 避免常见的状态管理错误
3. 提高应用性能和用户体验
4. 简化测试和调试过程

记住：状态管理应该是简单的、可预测的和可测试的。如果状态管理变得复杂，可能是设计需要重新考虑的信号。