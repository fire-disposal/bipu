# Shadcn UI 组件用法更新指南

## 📋 Shadcn UI 0.46.1 正确用法

### 1. ShadInput

```dart
// ❌ 旧用法（错误）
ShadInput(
  placeholder: '请输入用户名',  // String 类型
  prefixIcon: const Icon(Icons.person),
)

// ✅ 新用法（正确）
ShadInput(
  placeholder: const Text('请输入用户名'),  // Widget 类型
  prefix: const Icon(Icons.person),  // 使用 prefix 而不是 prefixIcon
)

// 或者使用带图标的变体
ShadInput(
  placeholder: const Text('请输入用户名'),
  prefix: const Padding(
    padding: EdgeInsets.only(left: 8),
    child: Icon(Icons.person, size: 18),
  ),
)
```

### 2. ShadButton

```dart
// ❌ 旧用法（错误）
ShadButton(
  text: const Text('按钮'),  // text 参数不存在
  variant: ShadButtonVariant.outline,  // variant 参数不存在
)

// ✅ 新用法（正确）
// 实心按钮
ShadButton(
  child: const Text('按钮'),
)

// 轮廓按钮（使用命名构造函数）
ShadButton.outlined(
  child: const Text('按钮'),
)

// 幽灵按钮
ShadButton.ghost(
  child: const Text('按钮'),
)

// 带加载状态
ShadButton(
  child: isLoading
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('按钮'),
  disabled: isLoading,
)
```

### 3. ShadToast

```dart
// ❌ 旧用法（错误）
ShadToast.success(  // success 方法不存在
  title: '成功',
  description: '操作完成',
)

ShadToast(
  title: '失败',  // String 类型
  description: '请重试',  // String 类型
  variant: ShadToastVariant.destructive,  // variant 参数不存在
).show(context);

// ✅ 新用法（正确）
// 成功提示
ShadToast(
  title: const Text('成功'),  // Widget 类型
  description: const Text('操作完成'),  // Widget 类型
).show(context);

// 失败提示（使用红色主题）
ShadToast(
  title: const Text('失败'),
  description: const Text('请重试'),
).show(context, theme: ShadToastTheme.destructive);

// 或者使用辅助函数
ShadToast.info(
  title: const Text('提示'),
  description: const Text('这是一条消息'),
).show(context);

ShadToast.warning(
  title: const Text('警告'),
  description: const Text('请注意'),
).show(context);

ShadToast.error(
  title: const Text('错误'),
  description: const Text('发生错误'),
).show(context);
```

### 4. ShadBadge

```dart
// ❌ 旧用法（错误）
ShadBadge(
  variant: ShadBadgeVariant.dot,  // variant 和 dot 不存在
)

// ✅ 新用法（正确）
// 默认徽章
ShadBadge(
  child: const Text('99+'),
)

// 点状徽章（使用条件渲染）
if (hasUnread)
  ShadBadge(
    child: const Text(''),  // 空文本显示为点
  )

// 或者使用容器模拟点
if (hasUnread)
  Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error,
      shape: BoxShape.circle,
    ),
  )
```

### 5. 通用规则

| 组件 | 旧参数 | 新参数 | 说明 |
|------|--------|--------|------|
| ShadInput | `placeholder: String` | `placeholder: Text` | 必须是 Widget |
| ShadInput | `prefixIcon` | `prefix` | 参数名变更 |
| ShadInput | `suffixIcon` | `suffix` | 参数名变更 |
| ShadButton | `text` | `child` | 参数名变更 |
| ShadButton | `variant` | 命名构造函数 | 使用 `ShadButton.outlined()` |
| ShadToast | `title: String` | `title: Text` | 必须是 Widget |
| ShadToast | `variant` | `theme` | 使用 `ShadToastTheme` |
| ShadBadge | `variant: dot` | `child: Text('')` | 空文本显示为点 |

---

## 📝 快速修复脚本

### 批量替换命令（IDE 查找替换）

```
# ShadInput
查找：placeholder: '([^']+)'
替换：placeholder: const Text('$1')

查找：prefixIcon:
替换：prefix:

查找：suffixIcon:
替换：suffix:

# ShadButton
查找：ShadButton\(\s*text:
替换：ShadButton(\n            child:

查找：variant: ShadButtonVariant\.(\w+)
替换：// 使用 ShadButton.$1(

# ShadToast
查找：title: '([^']+)'
替换：title: const Text('$1')

查找：description: '([^']+)'
替换：description: const Text('$1')

查找：variant: ShadToastVariant\.destructive
替换：theme: ShadToastTheme.destructive
```

---

## ✅ 完整示例

### 登录表单

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);

    void handleLogin() async {
      isLoading.value = true;
      // 登录逻辑
      await Future.delayed(const Duration(seconds: 1));
      isLoading.value = false;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ✅ 正确的 ShadInput 用法
            ShadInput(
              controller: usernameController,
              placeholder: const Text('请输入用户名'),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.person_outline, size: 18),
              ),
            ),
            const SizedBox(height: 16),

            ShadInput(
              controller: passwordController,
              placeholder: const Text('请输入密码'),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.lock_outline, size: 18),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // ✅ 正确的 ShadButton 用法
            ShadButton(
              child: isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录'),
              disabled: isLoading.value,
            ),

            const SizedBox(height: 16),

            // ✅ 轮廓按钮
            ShadButton.outlined(
              child: const Text('注册账号'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Toast 提示

```dart
void showSuccessToast(BuildContext context) {
  // ✅ 正确的 ShadToast 用法
  ShadToast(
    title: const Text('操作成功'),
    description: const Text('数据已保存'),
  ).show(context);
}

void showErrorToast(BuildContext context, String message) {
  ShadToast(
    title: const Text('操作失败'),
    description: Text(message),
    theme: ShadToastTheme.destructive,  // 红色主题
  ).show(context);
}

void showInfoToast(BuildContext context) {
  ShadToast(
    title: const Text('提示'),
    description: const Text('这是一条消息'),
  ).show(context);
}
```

---

**更新时间**: 2026-02-23  
**适用版本**: shadcn_ui ^0.46.1
