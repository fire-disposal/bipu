# SnackBar 统一管理指南

## 概述

本应用使用统一的 SnackBar 管理系统，包括 `ToastService` 和 `SnackBarManager` 两个核心组件。

## 核心组件

### 1. ToastService（底层服务）
- **位置**: `lib/core/services/toast_service.dart`
- **职责**: 提供基础的 SnackBar 显示功能
- **特点**: 
  - 支持多种类型（success, error, info, warning, message）
  - 自动管理 ScaffoldMessengerState
  - 提供统一的样式和动画

### 2. SnackBarManager（高层管理器）
- **位置**: `lib/core/services/snackbar_manager.dart`
- **职责**: 提供便捷的静态方法，简化 SnackBar 调用
- **特点**:
  - 静态方法调用，无需实例化
  - 预定义常见场景的提示文本
  - 减少代码重复

### 3. ImService（IM 服务集成）
- **位置**: `lib/core/services/im_service.dart`
- **职责**: 在接收新消息时自动显示通知
- **特点**:
  - 自动检测新消息
  - 显示发送者名称和消息预览
  - 支持启用/禁用通知

## 使用方法

### 基础用法

#### 显示成功提示
```dart
import 'package:bipupu/core/services/services.dart';

// 方式1: 使用 SnackBarManager（推荐）
SnackBarManager.showSuccess('操作成功');

// 方式2: 使用 ToastService
ToastService().showSuccess('操作成功');
```

#### 显示错误提示
```dart
SnackBarManager.showError('操作失败');
SnackBarManager.showNetworkError('网络连接失败');
SnackBarManager.showServerError('服务器错误');
```

#### 显示信息提示
```dart
SnackBarManager.showInfo('正在加载...');
SnackBarManager.showLoading('加载中');
SnackBarManager.showProcessing('保存');
```

#### 显示警告提示
```dart
SnackBarManager.showWarning('请注意');
SnackBarManager.showPermissionWarning('位置');
SnackBarManager.showInputWarning('请输入有效的邮箱地址');
```

### 高级用法

#### 自定义时长
```dart
SnackBarManager.showSuccess(
  '操作成功',
  duration: const Duration(seconds: 5),
);
```

#### 显示新消息通知
```dart
SnackBarManager.showNewMessage('新消息来了');
SnackBarManager.showMessageReceived('张三', '你好，今天怎么样？');
SnackBarManager.showMultipleMessages(5);
```

#### 清除当前 SnackBar
```dart
SnackBarManager.dismiss();
```

## 常见场景

### 1. 表单验证
```dart
if (username.isEmpty) {
  SnackBarManager.showValidationError('用户名');
  return;
}
```

### 2. API 调用
```dart
try {
  await api.updateProfile(data);
  SnackBarManager.showUpdateSuccess();
} on NetworkException catch (e) {
  SnackBarManager.showNetworkError(e.message);
} on ServerException catch (e) {
  SnackBarManager.showServerError(e.message);
}
```

### 3. 删除操作
```dart
try {
  await api.deleteItem(id);
  SnackBarManager.showDeleteSuccess();
} catch (e) {
  SnackBarManager.showOperationFailed('删除', e.toString());
}
```

### 4. 消息接收（自动处理）
```dart
// ImService 会自动显示消息通知
// 无需手动调用，但可以控制是否显示

final imService = ImService();
imService.setShowMessageNotifications(true);  // 启用通知
imService.setShowMessageNotifications(false); // 禁用通知
```

## SnackBar 类型

| 类型 | 颜色 | 图标 | 用途 |
|------|------|------|------|
| success | 绿色 | ✓ | 成功操作 |
| error | 红色 | ✗ | 错误信息 |
| info | 蓝色 | ℹ | 信息提示 |
| warning | 橙色 | ⚠ | 警告信息 |
| message | 蓝色 | ✉ | 新消息通知 |

## 样式特点

- **浮动显示**: 使用 `SnackBarBehavior.floating`
- **圆角设计**: 8px 圆角
- **边距**: 四周 16px 边距
- **动画**: 自动淡入淡出
- **最大行数**: 2 行（超长文本自动省略）

## 迁移指南

### 从直接使用 ScaffoldMessenger 迁移

**之前**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('操作成功')),
);
```

**之后**:
```dart
SnackBarManager.showSuccess('操作成功');
```

### 从 ToastService 迁移到 SnackBarManager

**之前**:
```dart
ToastService().showSuccess('操作成功');
```

**之后**:
```dart
SnackBarManager.showSuccess('操作成功');
```

## 最佳实践

1. **优先使用 SnackBarManager**: 提供更好的代码可读性
2. **使用预定义方法**: 而不是自定义文本
3. **避免过度通知**: 不要在短时间内显示多个 SnackBar
4. **提供有意义的信息**: 让用户清楚地了解发生了什么
5. **考虑用户体验**: 选择合适的显示时长

## 故障排除

### SnackBar 不显示

**原因**: ScaffoldMessengerState 为 null

**解决方案**:
1. 确保 `main.dart` 中设置了 `scaffoldMessengerKey`
2. 检查 Widget 树中是否有 `ScaffoldMessenger`

### 文本被截断

**原因**: 文本过长

**解决方案**:
- SnackBar 最多显示 2 行
- 使用 `_getMessagePreview()` 方法截断长文本

### 多个 SnackBar 同时显示

**原因**: 快速连续调用多个方法

**解决方案**:
- 使用 `SnackBarManager.dismiss()` 清除前一个
- 或者使用 `Future.delayed()` 延迟调用

## 相关文件

- `lib/core/services/toast_service.dart` - ToastService 实现
- `lib/core/services/snackbar_manager.dart` - SnackBarManager 实现
- `lib/core/services/im_service.dart` - ImService 集成
- `lib/main.dart` - 应用入口配置
