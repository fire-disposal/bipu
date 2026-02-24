# Flutter 错误修复进度

## ✅ 已完成的修复

### 1. Riverpod Provider 修复
- ✅ `home_provider.dart` - 移除 `@riverpod`，改用 `StateNotifierProvider`
- ✅ `pager_notifier.dart` - 移除 `@riverpod`，改用 `StateNotifierProvider`
- ✅ `profile_notifier.dart` - 移除 `@riverpod`，改用 `StateNotifierProvider`
- ✅ `chat_provider.dart` - 已使用 `StateNotifierProvider.family`

### 2. Shadcn UI 组件修复
- ✅ `login_page.dart` - 修复 `ShadInput` 和 `ShadButton` 用法
  - `placeholder: String` → `placeholder: const Text()`
  - `prefixIcon` → `prefix: Padding(child: Icon())`
  - `text:` → `child:`
  - `variant:` → 使用命名构造函数或移除

### 3. 长轮询配置
- ✅ 确认单一轮询引擎 (`polling_service.dart`)
- ✅ 正确的 API 端点 (`/api/messages/poll`)
- ✅ 正确的 Dio 超时配置 (45 秒)

---

## 🔧 待修复的文件

### 高优先级（阻塞性）

#### 1. `register_page.dart` - Shadcn UI 用法
```dart
// 需要修复：
ShadInput(placeholder: 'xxx', prefixIcon: Icon()) → ShadInput(placeholder: Text('xxx'), prefix: Padding(child: Icon()))
ShadButton(text: Text('xxx')) → ShadButton(child: Text('xxx'))
```

#### 2. `chat_page.dart` - Shadcn UI 用法
```dart
// 需要修复：
ShadInput(placeholder: 'xxx', suffix: IconButton()) → ShadInput(placeholder: Text('xxx'), suffix: IconButton())
ShadButton(text: Text('xxx')) → ShadButton(child: Text('xxx'))
```

#### 3. `pager_screen.dart` - Shadcn UI 用法
```dart
// 需要修复：
ShadInput(placeholder: 'xxx') → ShadInput(placeholder: Text('xxx'))
ShadButton(text: Text('xxx'), variant: ShadButtonVariant.xxx) → ShadButton(child: Text('xxx'))
```

#### 4. `settings_page.dart` - Shadcn UI 用法
```dart
// 需要修复：
ShadButton(text: Text('xxx'), variant: ShadButtonVariant.xxx) → ShadButton.outlined(child: Text('xxx'))
```

#### 5. `profile_screen.dart` - Shadcn UI 用法
```dart
// 需要修复：
ShadButton(text: Text('xxx'), variant: ShadButtonVariant.xxx) → ShadButton.outlined(child: Text('xxx'))
```

#### 6. `message_screen.dart` - Shadcn UI 用法
```dart
// 需要修复：
ShadBadge(variant: ShadBadgeVariant.dot) → ShadBadge(child: Text(''))
ShadButton(text: Text('xxx')) → ShadButton(child: Text('xxx'))
```

#### 7. `avatar_uploader.dart` - Shadcn UI 用法 + 缺失依赖
```dart
// 需要修复：
ShadButton(text: Text('xxx')) → ShadButton(child: Text('xxx'))
ShadToast.success(...) → ShadToast(title: Text(...), description: Text(...))
ShadToast(..., variant: ShadToastVariant.destructive) → ShadToast(..., theme: ShadToastTheme.destructive)

// 需要安装依赖：
flutter pub add image_picker image_cropper
```

---

### 中优先级（功能完善）

#### 8. `app_theme.dart` - flex_color_scheme API 变化
```dart
// 需要移除不支持的参数：
FlexSubThemesData(
  navigationBarRadius: 12.0,      // ❌ 移除
  navigationRailRadius: 12.0,     // ❌ 移除
  useTextTheme: true,             // ⚠️ 已废弃
)
```

#### 9. `notification_service.dart` - flutter_local_notifications API 变化
```dart
// 需要修复：
_notificationsPlugin.initialize(initSettings, onDidReceive...)
  → _notificationsPlugin.initialize(settings: initSettings, onDidReceiveNotificationResponse: ...)

// 移除不支持的参数：
AndroidNotificationChannel(description: 'xxx') → 移除 description
```

#### 10. `rest_client.g.dart` - 代码生成文件
```dart
// 需要重新生成：
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 低优先级（优化）

#### 11. 路径引用错误
- `chat_page.dart` - `../../logic/chat_provider.dart` → `../logic/chat_provider.dart`
- `msg_bubble.dart` - `../../../shared/models/message_model.dart` → 检查路径
- `waveform_view.dart` - `waveform_view.dart` → 文件不存在

#### 12. 缺失依赖
```yaml
# pubspec.yaml
dependencies:
  image_picker: ^1.1.2      # 头像上传
  image_cropper: ^8.0.2     # 图片裁剪
```

---

## 📋 修复步骤

### 步骤 1: 安装缺失依赖
```bash
cd D:\code\WORKING\bipupu\mobile
flutter pub add image_picker image_cropper
```

### 步骤 2: 修复 Shadcn UI 组件用法
批量替换（IDE 查找替换）：
```
# ShadInput
查找：placeholder: '([^']+)'
替换：placeholder: const Text('$1')

查找：prefixIcon:
替换：prefix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(

查找：suffixIcon:
替换：suffix:

# ShadButton
查找：text:
替换：child:

查找：variant: ShadButtonVariant\.(\w+),
替换：// 使用 ShadButton.$1( 或直接移除

# ShadToast
查找：ShadToast\.success\(
替换：ShadToast(

查找：title: '([^']+)'
替换：title: const Text('$1')

查找：description: '([^']+)'
替换：description: const Text('$1')

查找：variant: ShadToastVariant\.destructive
替换：theme: ShadToastTheme.destructive
```

### 步骤 3: 修复 flex_color_scheme
移除不支持的参数：
```dart
// lib/core/theme/app_theme.dart
FlexSubThemesData(
  // 移除这些行：
  navigationBarRadius: 12.0,
  navigationRailRadius: 12.0,
  useTextTheme: true,  // 或保留但忽略警告
)
```

### 步骤 4: 修复 flutter_local_notifications
```dart
// lib/core/services/notification_service.dart
await _notificationsPlugin.initialize(
  settings: initSettings,  // 添加 settings:
  onDidReceiveNotificationResponse: _onNotificationTapped,
  onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
);
```

### 步骤 5: 重新运行代码生成器
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤 6: 运行分析
```bash
flutter analyze
```

---

## 🎯 当前状态

| 模块 | 状态 | 备注 |
|------|------|------|
| Riverpod Provider | ✅ 已修复 | 4 个文件已转换 |
| Shadcn UI - Auth | ✅ 已修复 | login_page.dart |
| Shadcn UI - Register | 🔧 待修复 | register_page.dart |
| Shadcn UI - Message | 🔧 待修复 | chat_page.dart, message_screen.dart, msg_bubble.dart |
| Shadcn UI - Pager | 🔧 待修复 | pager_screen.dart |
| Shadcn UI - Profile | 🔧 待修复 | profile_screen.dart, settings_page.dart |
| Shadcn UI - Avatar | 🔧 待修复 | avatar_uploader.dart |
| flex_color_scheme | 🔧 待修复 | app_theme.dart |
| flutter_local_notifications | 🔧 待修复 | notification_service.dart |
| 依赖安装 | 🔧 待修复 | image_picker, image_cropper |
| 代码生成 | ⚠️ 部分成功 | 3 个警告已处理 |

---

**更新时间**: 2026-02-23  
**下一步**: 继续修复 Shadcn UI 组件用法
