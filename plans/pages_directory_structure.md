# Bipupu 应用 Pages 目录结构重构规划

## 一、重构目标

将现有的 `features/` 目录结构重构为 `pages/` 目录结构，以页面和导航为核心组织方式：

- **根目录**：保留 4 个 TabBar 主页面 + TabBar 底栏 + 登录页 + 注册页
- **子目录**：按照导航关系将其他页面和功能收纳进四大文件夹
- **共享资源**：保留 `common/` 和 `core/` 目录用于共享组件和服务
- **数据模型**：直接使用 `core/api/models/` 中自动生成的模型，不在各模块中重复定义

---

## 二、新的目录结构

### 顶层结构

```
mobile/lib/
├── pages/                          # 页面根目录（替代 features）
│   ├── auth/                       # 认证相关
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   │
│   ├── home/                       # TabBar 1: 首页
│   │   ├── home_page.dart          # 主页面
│   │   ├── pages/                  # 子页面
│   │   │   ├── device_detail_page.dart
│   │   │   └── quick_actions/
│   │   │       ├── subscriptions_page.dart
│   │   │       ├── contacts_page.dart
│   │   │       └── voice_test_page.dart
│   │   └── widgets/                # 组件
│   │       ├── device_card.dart
│   │       ├── quick_action_card.dart
│   │       └── welcome_header.dart
│   │
│   ├── pager/                      # TabBar 2: 对讲
│   │   ├── pager_page.dart         # 主页面
│   │   ├── pages/                  # 子页面
│   │   │   └── operator_gallery_page.dart
│   │   └── widgets/                # 组件
│   │       ├── voice_assistant_panel.dart
│   │       ├── waveform_widget.dart
│   │       ├── waveform_controller.dart
│   │       └── waveform_painter.dart
│   │
│   ├── messages/                   # TabBar 3: 消息
│   │   ├── messages_page.dart      # 主页面
│   │   ├── pages/                  # 子页面
│   │   │   ├── message_detail_page.dart
│   │   │   ├── subscription_management_page.dart
│   │   │   ├── favorites_page.dart
│   │   │   └── chat_page.dart
│   │   └── widgets/                # 组件
│   │       ├── message_filter_bar.dart
│   │       ├── message_list_item.dart
│   │       ├── socket_status_indicator.dart
│   │       └── message_bubble.dart
│   │
│   ├── profile/                    # TabBar 4: 我的
│   │   ├── profile_page.dart       # 主页面
│   │   ├── pages/                  # 子页面
│   │   │   ├── profile_edit_page.dart
│   │   │   ├── security_page.dart
│   │   │   ├── settings_page.dart
│   │   │   ├── about_page.dart
│   │   │   ├── language_page.dart
│   │   │   ├── notifications_page.dart
│   │   │   ├── privacy_page.dart
│   │   │   ├── user_detail_page.dart
│   │   │   └── bluetooth/
│   │   │       ├── bluetooth_scan_page.dart
│   │   │       └── device_detail_page.dart
│   │   └── widgets/                # 组件
│   │       ├── profile_header.dart
│   │       ├── setting_section.dart
│   │       ├── theme_selector.dart
│   │       └── device_list_item.dart
│   │
│   ├── layout/                     # 布局相关
│   │   ├── main_layout.dart
│   │   ├── enhanced_bottom_navigation.dart
│   │   └── discover_page.dart
│   │
│   ├── assistant/                  # 语音助手（跨页面共享）
│   │   ├── assistant_controller.dart
│   │   └── assistant_config.dart
│   │
│   └── common/                     # 通用组件和工具
│       └── widgets/
│           ├── app_button.dart
│           ├── setting_tile.dart
│           └── placeholder_page.dart
│
├── core/                           # 核心层（保持不变）
│   ├── api/
│   ├── network/
│   ├── services/
│   ├── state/
│   ├── storage/
│   ├── theme/
│   ├── translations/
│   ├── utils/
│   └── voice/
│
└── models/                         # 全局数据模型（可选）
    └── ...
```

---

## 三、详细页面分类

### 3.1 认证页面（auth/）

```
auth/
├── login_page.dart                 # 登录页
└── register_page.dart              # 注册页
```

**说明**：
- 位于根目录，不属于任何 TabBar
- 在用户未登录时显示
- 登录成功后跳转到 `/home`

---

### 3.2 首页（home/）

```
home/
├── home_page.dart                  # 首页主体
├── pages/
│   ├── device_detail_page.dart     # 设备详情（从 bluetooth/device_detail_page 移动）
│   └── quick_actions/
│       ├── subscriptions_page.dart  # 订阅管理（从 messages/subscription_management_page 移动）
│       ├── contacts_page.dart       # 好友列表（从 contacts/contacts_page 移动）
│       └── voice_test_page.dart     # 语音测试（从 voice_test/voice_test_page 移动）
└── widgets/
    ├── device_card.dart
    ├── quick_action_card.dart
    └── welcome_header.dart
```

**导航关系**：
- `/home` → 首页主体
- `/home/device` → 设备详情
- `/home/subscriptions` → 订阅管理
- `/home/contacts` → 好友列表
- `/home/voice_test` → 语音测试

**说明**：
- 首页作为应用入口，展示设备状态和快速操作
- 快速操作入口集中在 `quick_actions/` 子目录
- 设备详情页面从 bluetooth 移动到 home

---

### 3.3 对讲（pager/）

```
pager/
├── pager_page.dart                 # 对讲主页面
├── pages/
│   └── operator_gallery_page.dart   # 接线员库
└── widgets/
    ├── voice_assistant_panel.dart
    ├── waveform_widget.dart
    ├── waveform_controller.dart
    └── waveform_painter.dart
```

**数据模型**：
- 使用 `core/api/models/message_response.dart` 等自动生成的模型
- 不需要在 pager 模块中定义额外的模型

**导航关系**：
- `/pager` → 对讲主页面
- `/pager/operators` → 接线员库（Modal）

**说明**：
- 对讲是独立的功能模块
- 接线员库通过 Modal 打开，不改变路由
- 语音交互和直接发送模式在主页面中切换

---

### 3.4 消息（messages/）

```
messages/
├── messages_page.dart              # 消息列表主页面
├── pages/
│   ├── message_detail_page.dart    # 消息详情
│   ├── subscription_management_page.dart  # 订阅管理
│   ├── favorites_page.dart         # 收藏消息
│   └── chat_page.dart              # 聊天页面
└── widgets/
    ├── message_filter_bar.dart
    ├── message_list_item.dart
    ├── socket_status_indicator.dart
    └── message_bubble.dart
```

**数据模型**：
- 使用 `core/api/models/message_response.dart` 等自动生成的模型
- 使用 `core/api/models/favorite_response.dart` 处理收藏消息

**导航关系**：
- `/messages` → 消息列表
- `/messages/detail` → 消息详情
- `/messages/subscriptions` → 订阅管理
- `/messages/favorites` → 收藏消息
- `/messages/chat` → 聊天页面

**说明**：
- 消息中心集中管理所有消息相关功能
- 订阅管理既可从 home 快速入口访问，也可从 messages 访问
- 支持多种消息过滤和分类

---

### 3.5 个人中心（profile/）

```
profile/
├── profile_page.dart               # 个人中心主页面
├── pages/
│   ├── profile_edit_page.dart      # 个人信息编辑
│   ├── security_page.dart          # 账号与安全
│   ├── settings_page.dart          # 设置
│   ├── about_page.dart             # 关于
│   ├── language_page.dart          # 语言选择
│   ├── notifications_page.dart     # 通知设置
│   ├── privacy_page.dart           # 隐私设置
│   ├── user_detail_page.dart       # 用户详情
│   └── bluetooth/
│       ├── bluetooth_scan_page.dart # 蓝牙扫描
│       └── device_detail_page.dart  # 设备详情
├── widgets/
│   ├── profile_header.dart
│   ├── setting_section.dart
│   ├── theme_selector.dart
│   └── device_list_item.dart
└── models/
    └── profile_models.dart
```

**导航关系**：
- `/profile` → 个人中心
- `/profile/personal_info` → 个人信息编辑
- `/profile/security` → 账号与安全
- `/profile/settings` → 设置
- `/profile/about` → 关于
- `/profile/language` → 语言选择
- `/profile/notifications` → 通知设置
- `/profile/privacy` → 隐私设置
- `/profile/user_detail` → 用户详情
- `/profile/bluetooth/scan` → 蓝牙扫描
- `/profile/bluetooth/device` → 设备详情

**说明**：
- 个人中心集中管理用户相关的所有功能
- 蓝牙设备管理作为 profile 的子功能
- 设置相关页面（语言、通知、隐私等）集中在 profile 下

---

### 3.6 布局（layout/）

```
layout/
├── main_layout.dart                # 主布局（包含 TabBar）
├── enhanced_bottom_navigation.dart  # 增强的底部导航栏
└── discover_page.dart              # 发现页面（可选）
```

**说明**：
- 主布局包含 TabBar 导航栏
- 所有 TabBar 页面都在 MainLayout 中显示
- 底部导航栏管理 TabBar 的切换和状态

---

### 3.7 语音助手（assistant/）

```
assistant/
├── assistant_controller.dart       # 语音助手控制器
└── assistant_config.dart           # 语音助手配置
```

**说明**：
- 跨页面共享的语音助手功能
- 主要被 pager 和 main_layout 使用
- 可以从任何页面调用

---

### 3.8 通用组件（common/）

```
common/
├── widgets/
│   ├── app_button.dart
│   ├── setting_tile.dart
│   └── placeholder_page.dart
└── models/
    └── common_models.dart
```

**说明**：
- 存放所有页面都可能使用的通用组件
- 不属于任何特定功能模块
- 可以被任何页面导入使用

---

## 四、路由配置映射

### 完整路由表

```dart
// 认证路由
'/login' → pages/auth/login_page.dart
'/register' → pages/auth/register_page.dart

// TabBar 主路由
'/home' → pages/home/home_page.dart
'/pager' → pages/pager/pager_page.dart
'/messages' → pages/messages/messages_page.dart
'/profile' → pages/profile/profile_page.dart

// 首页子路由
'/home/device' → pages/home/pages/device_detail_page.dart
'/home/subscriptions' → pages/home/pages/quick_actions/subscriptions_page.dart
'/home/contacts' → pages/home/pages/quick_actions/contacts_page.dart
'/home/voice_test' → pages/home/pages/quick_actions/voice_test_page.dart

// 对讲子路由
'/pager/operators' → pages/pager/pages/operator_gallery_page.dart (Modal)

// 消息子路由
'/messages/detail' → pages/messages/pages/message_detail_page.dart
'/messages/subscriptions' → pages/messages/pages/subscription_management_page.dart
'/messages/favorites' → pages/messages/pages/favorites_page.dart
'/messages/chat' → pages/messages/pages/chat_page.dart

// 个人中心子路由
'/profile/personal_info' → pages/profile/pages/profile_edit_page.dart
'/profile/security' → pages/profile/pages/security_page.dart
'/profile/settings' → pages/profile/pages/settings_page.dart
'/profile/about' → pages/profile/pages/about_page.dart
'/profile/language' → pages/profile/pages/language_page.dart
'/profile/notifications' → pages/profile/pages/notifications_page.dart
'/profile/privacy' → pages/profile/pages/privacy_page.dart
'/profile/user_detail' → pages/profile/pages/user_detail_page.dart
'/profile/bluetooth/scan' → pages/profile/pages/bluetooth/bluetooth_scan_page.dart
'/profile/bluetooth/device' → pages/profile/pages/bluetooth/device_detail_page.dart
```

---

## 五、文件迁移清单

### 需要移动的文件

| 原位置 | 新位置 | 说明 |
|--------|--------|------|
| `features/auth/login_page.dart` | `pages/auth/login_page.dart` | 登录页 |
| `features/auth/register_page.dart` | `pages/auth/register_page.dart` | 注册页 |
| `features/home/home_page.dart` | `pages/home/home_page.dart` | 首页 |
| `features/pager/pages/pager_page.dart` | `pages/pager/pager_page.dart` | 对讲页 |
| `features/pager/pages/operator_gallery.dart` | `pages/pager/pages/operator_gallery_page.dart` | 接线员库 |
| `features/pager/widgets/*` | `pages/pager/widgets/*` | 对讲组件 |
| `features/chat/pages/conversation_list_page.dart` | `pages/messages/messages_page.dart` | 消息列表 |
| `features/chat/pages/message_detail_page.dart` | `pages/messages/pages/message_detail_page.dart` | 消息详情 |
| `features/chat/pages/subscription_management_page.dart` | `pages/messages/pages/subscription_management_page.dart` | 订阅管理 |
| `features/chat/pages/favorites_page.dart` | `pages/messages/pages/favorites_page.dart` | 收藏消息 |
| `features/chat/pages/chat_page.dart` | `pages/messages/pages/chat_page.dart` | 聊天页面 |
| `features/profile/pages/profile_page.dart` | `pages/profile/profile_page.dart` | 个人中心 |
| `features/profile/pages/profile_edit_page.dart` | `pages/profile/pages/profile_edit_page.dart` | 个人信息编辑 |
| `features/profile/pages/security_page.dart` | `pages/profile/pages/security_page.dart` | 账号与安全 |
| `features/profile/pages/settings_page.dart` | `pages/profile/pages/settings_page.dart` | 设置 |
| `features/profile/pages/about_page.dart` | `pages/profile/pages/about_page.dart` | 关于 |
| `features/profile/pages/language_page.dart` | `pages/profile/pages/language_page.dart` | 语言选择 |
| `features/profile/pages/notifications_page.dart` | `pages/profile/pages/notifications_page.dart` | 通知设置 |
| `features/profile/pages/privacy_page.dart` | `pages/profile/pages/privacy_page.dart` | 隐私设置 |
| `features/profile/pages/user_detail_page.dart` | `pages/profile/pages/user_detail_page.dart` | 用户详情 |
| `features/bluetooth/bluetooth_scan_page.dart` | `pages/profile/pages/bluetooth/bluetooth_scan_page.dart` | 蓝牙扫描 |
| `features/bluetooth/device_detail_page.dart` | `pages/profile/pages/bluetooth/device_detail_page.dart` | 设备详情 |
| `features/contacts/pages/contacts_page.dart` | `pages/home/pages/quick_actions/contacts_page.dart` | 好友列表 |
| `features/contacts/pages/user_search_page.dart` | `pages/home/pages/quick_actions/user_search_page.dart` | 用户搜索 |
| `features/voice_test/voice_test_page.dart` | `pages/home/pages/quick_actions/voice_test_page.dart` | 语音测试 |
| `features/layout/main_layout.dart` | `pages/layout/main_layout.dart` | 主布局 |
| `features/layout/enhanced_bottom_navigation.dart` | `pages/layout/enhanced_bottom_navigation.dart` | 底部导航 |
| `features/layout/discover_page.dart` | `pages/layout/discover_page.dart` | 发现页面 |
| `features/assistant/assistant_controller.dart` | `pages/assistant/assistant_controller.dart` | 语音助手控制器 |
| `features/assistant/assistant_config.dart` | `pages/assistant/assistant_config.dart` | 语音助手配置 |
| `features/common/widgets/*` | `pages/common/widgets/*` | 通用组件 |

---

## 六、导入路径更新规则

### 导入路径变更示例

**原导入路径**：
```dart
import 'package:bipupu/features/home/home_page.dart';
import 'package:bipupu/features/pager/pages/pager_page.dart';
import 'package:bipupu/features/chat/pages/conversation_list_page.dart';
```

**新导入路径**：
```dart
import 'package:bipupu/pages/home/home_page.dart';
import 'package:bipupu/pages/pager/pager_page.dart';
import 'package:bipupu/pages/messages/messages_page.dart';
```

### 更新规则

1. 将所有 `features/` 替换为 `pages/`
2. 调整子目录结构以匹配新的组织方式
3. 更新相对导入路径

---

## 七、实施步骤

### 第一阶段：准备
- [ ] 创建新的 `pages/` 目录结构
- [ ] 备份现有 `features/` 目录

### 第二阶段：迁移
- [ ] 迁移认证页面（auth/）
- [ ] 迁移首页及其子页面（home/）
- [ ] 迁移对讲页面（pager/）
- [ ] 迁移消息页面（messages/）
- [ ] 迁移个人中心页面（profile/）
- [ ] 迁移布局和通用组件（layout/, common/）

### 第三阶段：更新导入
- [ ] 更新所有导入路径
- [ ] 更新路由配置
- [ ] 更新 pubspec.yaml（如需要）

### 第四阶段：测试
- [ ] 编译检查
- [ ] 功能测试
- [ ] 导航测试

### 第五阶段：清理
- [ ] 删除旧的 `features/` 目录
- [ ] 验证所有功能正常

---

## 八、优势总结

### 相比原有结构的改进

1. **更清晰的导航关系**
   - 页面按照导航层级组织
   - 子页面明确归属于父页面

2. **更好的代码组织**
   - 相关页面和组件集中在一起
   - 易于查找和维护

3. **更灵活的扩展**
   - 新增页面直接放在对应目录
   - 无需创建新的功能模块

4. **更简洁的根目录**
   - 只保留 4 个 TabBar 页面 + 认证页面
   - 其他页面都在子目录中

5. **更好的模块独立性**
   - 每个 TabBar 页面是独立的模块
   - 模块间依赖清晰

---

## 九、注意事项

1. **导入路径更新**
   - 需要全局搜索替换 `features/` → `pages/`
   - 检查所有相对导入路径

2. **路由配置**
   - 更新 go_router 的路由定义
   - 确保所有路由都能正确映射

3. **包导入**
   - 检查 pubspec.yaml 中的包导入
   - 确保没有遗漏的导入

4. **测试覆盖**
   - 测试所有导航路径
   - 确保页面间跳转正常

5. **文档更新**
   - 更新项目文档中的目录结构说明
   - 更新开发指南中的导入路径示例
