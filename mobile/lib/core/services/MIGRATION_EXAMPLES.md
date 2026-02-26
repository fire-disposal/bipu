# SnackBar 迁移示例

本文档提供了从旧的 SnackBar 实现迁移到新的统一系统的具体示例。

## 示例 1: 简单的成功提示

### 之前（直接使用 ScaffoldMessenger）
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('操作成功')),
);
```

### 之后（使用 SnackBarManager）
```dart
SnackBarManager.showSuccess('操作成功');
```

---

## 示例 2: 错误提示

### 之前（使用 ToastService）
```dart
ToastService().showError('操作失败: ${e.message}');
```

### 之后（使用 SnackBarManager）
```dart
SnackBarManager.showError('操作失败: ${e.message}');
// 或者使用预定义方法
SnackBarManager.showOperationFailed('删除', e.message);
```

---

## 示例 3: 网络错误处理

### 之前
```dart
try {
  await api.fetchData();
} on NetworkException catch (e) {
  ToastService().showError('Network error: ${e.message}');
}
```

### 之后
```dart
try {
  await api.fetchData();
} on NetworkException catch (e) {
  SnackBarManager.showNetworkError(e.message);
}
```

---

## 示例 4: 表单验证

### 之前
```dart
if (email.isEmpty) {
  ToastService().showWarning('邮箱不能为空');
  return;
}
```

### 之后
```dart
if (email.isEmpty) {
  SnackBarManager.showValidationError('邮箱');
  return;
}
```

---

## 示例 5: 登录页面完整迁移

### 之前
```dart
import '../../core/services/toast_service.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _login() async {
    if (username.isEmpty) {
      ToastService().showWarning('请输入用户名');
      return;
    }

    try {
      await AuthService().login(username, password);
      if (mounted) {
        context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ToastService().showError('登录失败: ${e.message}');
      }
    } on NetworkException catch (e) {
      if (mounted) {
        ToastService().showError('网络错误: ${e.message}');
      }
    }
  }
}
```

### 之后
```dart
import '../../core/services/snackbar_manager.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _login() async {
    if (username.isEmpty) {
      SnackBarManager.showValidationError('用户名');
      return;
    }

    try {
      await AuthService().login(username, password);
      if (mounted) {
        context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        SnackBarManager.showError('登录失败: ${e.message}');
      }
    } on NetworkException catch (e) {
      if (mounted) {
        SnackBarManager.showNetworkError(e.message);
      }
    }
  }
}
```

---

## 示例 6: 消息接收通知（自动处理）

### 之前（需要手动处理）
```dart
// 在 ImService 中
if (newMessages.isNotEmpty) {
  // 需要手动显示通知
  // 没有统一的方式
}
```

### 之后（自动处理）
```dart
// ImService 会自动显示消息通知
// 无需手动调用

// 如果需要控制通知显示
final imService = ImService();
imService.setShowMessageNotifications(true);  // 启用
imService.setShowMessageNotifications(false); // 禁用
```

---

## 示例 7: 复杂的错误处理

### 之前
```dart
try {
  await api.updateProfile(data);
  ToastService().showSuccess('更新成功');
} on ValidationException catch (e) {
  String errorMessage = 'Validation failed';
  if (e.errors != null && e.errors!.isNotEmpty) {
    errorMessage = e.errors!.entries
        .map((entry) => entry.value.toString())
        .join(', ');
  }
  ToastService().showError(errorMessage);
} on NetworkException catch (e) {
  ToastService().showError('Network error: ${e.message}');
} on ServerException catch (e) {
  ToastService().showError('Server error: ${e.message}');
} catch (e) {
  ToastService().showError('Update failed: $e');
}
```

### 之后
```dart
try {
  await api.updateProfile(data);
  SnackBarManager.showUpdateSuccess();
} on ValidationException catch (e) {
  String errorMessage = 'Validation failed';
  if (e.errors != null && e.errors!.isNotEmpty) {
    errorMessage = e.errors!.entries
        .map((entry) => entry.value.toString())
        .join(', ');
  }
  SnackBarManager.showError(errorMessage);
} on NetworkException catch (e) {
  SnackBarManager.showNetworkError(e.message);
} on ServerException catch (e) {
  SnackBarManager.showServerError(e.message);
} catch (e) {
  SnackBarManager.showOperationFailed('update', e.toString());
}
```

---

## 示例 8: 自定义时长

### 之前
```dart
ToastService().showSuccess(
  '操作成功',
  duration: const Duration(seconds: 5),
);
```

### 之后
```dart
SnackBarManager.showSuccess(
  '操作成功',
  duration: const Duration(seconds: 5),
);
```

---

## 迁移检查清单

- [ ] 替换所有 `ToastService()` 调用为 `SnackBarManager`
- [ ] 替换所有 `ScaffoldMessenger.of(context).showSnackBar()` 调用
- [ ] 更新导入语句：`import '../../core/services/snackbar_manager.dart'`
- [ ] 使用预定义方法而不是自定义文本
- [ ] 测试所有错误处理路径
- [ ] 验证 SnackBar 显示正确
- [ ] 检查消息通知是否自动显示

---

## 常见问题

### Q: 如何显示自定义样式的 SnackBar？
A: 使用 `SnackBarManager.toastService` 获取 `ToastService` 实例，然后调用 `_showSnackBar()` 方法。

### Q: 如何禁用消息通知？
A: 调用 `ImService().setShowMessageNotifications(false)`

### Q: 如何在 SnackBar 上添加操作按钮？
A: 当前版本不支持，但可以通过扩展 `SnackBarManager` 来实现。

### Q: 为什么 SnackBar 不显示？
A: 确保 `main.dart` 中设置了 `scaffoldMessengerKey`，并且 Widget 树中有 `ScaffoldMessenger`。
