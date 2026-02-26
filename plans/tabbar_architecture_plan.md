# Bipupu 应用 TabBar 架构规划

## 一、各页面功能规划

### A. Home（首页）- 首页
**核心功能：**
- 设备连接状态展示（蓝牙连接状态）
- 快速操作入口（订阅管理、好友、语音测试）
- 欢迎信息和品牌展示
- 设备控制导航

**主要特性：**
- 实时蓝牙连接状态指示
- 设备连接/控制按钮
- 快速操作卡片网格
- 动画欢迎界面

**关键页面：**
- `/home` - 首页主体

---

### B. Pager（传呼机）- 对讲
**核心功能：**
- 语音交互模式（长按对讲机按钮录音）
- 直接发送模式（文本消息发送）
- 接线员选择和管理
- 消息历史记录

**主要特性：**
- 双模式切换（语音/直接）
- 长按对讲机按钮启动语音录制
- 呼吸动画反馈
- 接线员库管理
- 消息缓冲和强制发送

**关键页面：**
- `/pager` - 对讲主页面
- `/pager/operators` - 接线员库（通过 OperatorGallery）

---

### C. Message（消息）- 消息中心
**核心功能：**
- 消息列表展示（已接收、已发送、订阅、管理）
- 消息过滤和分类
- 消息详情查看
- 订阅管理

**主要特性：**
- 四层消息过滤（已接收/已发送/订阅/管理）
- Socket 连接状态指示
- 消息刷新和本地缓存管理
- 消息详情页面
- 订阅设置管理

**关键页面：**
- `/messages` - 消息列表主页
- `/messages/detail` - 消息详情
- `/messages/subscriptions` - 订阅管理

---

### D. Me（我的）- 个人中心
**核心功能：**
- 用户信息展示和编辑
- 账号与安全管理
- 设置和偏好配置
- 设备管理

**主要特性：**
- 用户头像和基本信息
- Bipupu ID 复制功能
- 蓝牙设备管理入口
- 账号安全设置
- 语言和主题选择
- 缓存清理和退出登录

**关键页面：**
- `/profile` - 个人中心主页
- `/profile/personal_info` - 个人信息编辑
- `/profile/security` - 账号与安全
- `/profile/settings` - 设置
- `/profile/about` - 关于
- `/profile/language` - 语言选择
- `/profile/notifications` - 通知设置
- `/profile/privacy` - 隐私设置

---

## 二、页面导航入口关系

### 导航层级结构

```
MainLayout (底部 TabBar)
├── Home (/home)
│   ├── 设备控制 → /bluetooth/scan 或 /bluetooth/device
│   ├── 订阅管理 → /messages/subscriptions
│   ├── 好友 → /contacts
│   └── 语音测试 → /voice_test
│
├── Pager (/pager)
│   ├── 接线员库 → OperatorGallery (Modal)
│   └── 长按对讲 → 语音录制
│
├── Messages (/messages)
│   ├── 消息详情 → /messages/detail
│   ├── 订阅管理 → /messages/subscriptions
│   └── 管理功能 → 刷新/清除缓存/删除
│
└── Profile (/profile)
    ├── 个人信息 → /profile/personal_info
    ├── 账号与安全 → /profile/security
    ├── 设置 → /profile/settings
    ├── 蓝牙设备 → /bluetooth/scan
    ├── 关于 → /profile/about
    ├── 语言 → /profile/language
    ├── 通知 → /profile/notifications
    └── 隐私 → /profile/privacy
```

### 跨 TabBar 导航关系

| 来源页面 | 目标页面 | 导航方式 | 说明 |
|---------|---------|--------|------|
| Home | Messages/Subscriptions | push | 订阅管理快速入口 |
| Home | Contacts | push | 好友列表 |
| Home | Bluetooth | push | 设备连接/控制 |
| Pager | Operators | Modal | 接线员选择 |
| Messages | Message Detail | push | 查看消息详情 |
| Messages | Subscriptions | push | 订阅管理 |
| Profile | Personal Info | push | 编辑个人信息 |
| Profile | Security | push | 账号安全设置 |
| Profile | Settings | push | 应用设置 |
| Profile | Bluetooth | push | 设备管理 |

---

## 三、目录结构规划

### 当前结构分析

```
mobile/lib/features/
├── home/
│   └── home_page.dart
├── pager/
│   ├── pages/
│   │   └── pager_page.dart
│   └── widgets/
│       ├── operator_gallery.dart
│       ├── voice_assistant_panel.dart
│       ├── waveform_widget.dart
│       ├── waveform_controller.dart
│       └── waveform_painter.dart
├── chat/
│   └── pages/
│       ├── conversation_list_page.dart (MessagesPage)
│       ├── message_detail_page.dart
│       ├── favorites_page.dart
│       ├── subscription_management_page.dart
│       └── chat_page.dart
├── profile/
│   └── pages/
│       ├── profile_page.dart
│       ├── profile_edit_page.dart
│       ├── security_page.dart
│       ├── settings_page.dart
│       ├── about_page.dart
│       ├── language_page.dart
│       ├── notifications_page.dart
│       ├── privacy_page.dart
│       └── user_detail_page.dart
├── contacts/
│   └── pages/
│       ├── contacts_page.dart
│       └── user_search_page.dart
├── bluetooth/
│   └── pages/
│       ├── bluetooth_scan_page.dart
│       └── device_detail_page.dart
├── layout/
│   ├── main_layout.dart
│   ├── enhanced_bottom_navigation.dart
│   └── discover_page.dart
├── assistant/
│   ├── assistant_controller.dart
│   └── assistant_config.dart
├── common/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   └── setting_tile.dart
│   └── placeholder_page.dart
└── voice_test/
    └── voice_test_page.dart
```

### 推荐优化结构

```
mobile/lib/features/
├── home/
│   ├── pages/
│   │   └── home_page.dart
│   └── widgets/
│       ├── device_card.dart
│       ├── quick_action_card.dart
│       └── welcome_header.dart
│
├── pager/
│   ├── pages/
│   │   └── pager_page.dart
│   ├── widgets/
│   │   ├── operator_gallery.dart
│   │   ├── voice_assistant_panel.dart
│   │   ├── waveform_widget.dart
│   │   ├── waveform_controller.dart
│   │   └── waveform_painter.dart
│   └── models/
│       └── pager_models.dart
│
├── messages/
│   ├── pages/
│   │   ├── messages_page.dart (conversation_list_page)
│   │   ├── message_detail_page.dart
│   │   └── subscription_management_page.dart
│   ├── widgets/
│   │   ├── message_filter_bar.dart
│   │   ├── message_list_item.dart
│   │   └── socket_status_indicator.dart
│   └── models/
│       └── message_models.dart
│
├── profile/
│   ├── pages/
│   │   ├── profile_page.dart
│   │   ├── profile_edit_page.dart
│   │   ├── security_page.dart
│   │   ├── settings_page.dart
│   │   ├── about_page.dart
│   │   ├── language_page.dart
│   │   ├── notifications_page.dart
│   │   └── privacy_page.dart
│   ├── widgets/
│   │   ├── profile_header.dart
│   │   ├── setting_section.dart
│   │   └── theme_selector.dart
│   └── models/
│       └── profile_models.dart
│
├── contacts/
│   ├── pages/
│   │   ├── contacts_page.dart
│   │   └── user_search_page.dart
│   └── widgets/
│       └── contact_list_item.dart
│
├── bluetooth/
│   ├── pages/
│   │   ├── bluetooth_scan_page.dart
│   │   └── device_detail_page.dart
│   └── widgets/
│       └── device_list_item.dart
│
├── layout/
│   ├── main_layout.dart
│   ├── enhanced_bottom_navigation.dart
│   └── discover_page.dart
│
├── assistant/
│   ├── assistant_controller.dart
│   └── assistant_config.dart
│
├── common/
│   ├── widgets/
│   │   ├── app_button.dart
│   │   └── setting_tile.dart
│   └── placeholder_page.dart
│
└── voice_test/
    └── voice_test_page.dart
```

---

## 四、各页面依赖关系

### 核心依赖关系图

```
┌─────────────────────────────────────────────────────────────┐
│                    Core Services Layer                       │
├─────────────────────────────────────────────────────────────┤
│ • AuthService (认证)                                         │
│ • ImService (即时消息)                                       │
│ • BluetoothDeviceService (蓝牙)                              │
│ • ThemeService (主题)                                        │
│ • ToastService (提示)                                        │
│ • AssistantController (语音助手)                             │
└─────────────────────────────────────────────────────────────┘
         ↑                    ↑                    ↑
         │                    │                    │
    ┌────┴────┐          ┌────┴────┐         ┌────┴────┐
    │   Home   │          │  Pager  │         │ Messages │
    └────┬────┘          └────┬────┘         └────┬────┘
         │                    │                    │
    ┌────┴────────────────────┴────────────────────┴────┐
    │              MainLayout (TabBar)                   │
    └────┬────────────────────┬────────────────────┬────┘
         │                    │                    │
    ┌────┴────┐          ┌────┴────┐         ┌────┴────┐
    │ Contacts │          │ Bluetooth│        │ Profile  │
    └──────────┘          └──────────┘        └──────────┘
```

### 页面级依赖表

| 页面 | 依赖服务 | 依赖组件 | 依赖页面 |
|------|---------|---------|---------|
| **Home** | BluetoothDeviceService | - | Bluetooth, Messages, Contacts, VoiceTest |
| **Pager** | AssistantController, ImService | OperatorGallery, WaveformWidget | - |
| **Messages** | ImService, AuthService | MessageFilterBar, SocketStatusIndicator | MessageDetail, Subscriptions |
| **Profile** | AuthService, ThemeService | ProfileHeader, SettingSection | PersonalInfo, Security, Settings, Bluetooth |
| **Contacts** | AuthService, ImService | ContactListItem | UserSearch, UserDetail |
| **Bluetooth** | BluetoothDeviceService | DeviceListItem | DeviceDetail |

### 服务依赖关系

```
AuthService
├── 用户认证和授权
├── 被依赖：Profile, Messages, Contacts, Home
└── 依赖：TokenManager, StorageManager

ImService
├── 消息收发和管理
├── 被依赖：Messages, Pager, Contacts, Home
└── 依赖：MessageClient, WebSocket

BluetoothDeviceService
├── 蓝牙设备连接和控制
├── 被依赖：Home, Profile, Bluetooth
└── 依赖：FlutterBluePlus

AssistantController
├── 语音识别和合成
├── 被依赖：Pager, MainLayout
└── 依赖：ASREngine, TTSEngine, VoiceService

ThemeService
├── 主题和外观管理
├── 被依赖：Profile, MainLayout
└── 依赖：StorageManager
```

---

## 五、路由配置总结

### 完整路由表

```dart
// TabBar 主路由
'/home' → HomePage
'/pager' → PagerPage
'/messages' → MessagesPage
'/profile' → ProfilePage

// 消息相关
'/messages/detail' → MessageDetailPage
'/messages/subscriptions' → SubscriptionManagementPage

// 个人中心相关
'/profile/personal_info' → ProfileEditPage
'/profile/security' → SecurityPage
'/profile/settings' → SettingsPage
'/profile/about' → AboutPage
'/profile/language' → LanguagePage
'/profile/notifications' → NotificationsPage
'/profile/privacy' → PrivacyPage

// 蓝牙相关
'/bluetooth/scan' → BluetoothScanPage
'/bluetooth/device' → DeviceDetailPage

// 其他
'/contacts' → ContactsPage
'/contacts/search' → UserSearchPage
'/contacts/detail' → UserDetailPage
'/voice_test' → VoiceTestPage
```

---

## 六、架构设计要点

### 1. 分层设计
- **UI 层**：各 TabBar 页面和子页面
- **业务逻辑层**：Controllers 和 Services
- **数据层**：API Clients 和 Local Storage
- **核心层**：Core Services 和 Utilities

### 2. 状态管理
- **简单状态**：使用 flutter_hooks
- **复杂状态**：使用 Cubit
- **全局状态**：使用 StateProviders

### 3. 导航策略
- **TabBar 切换**：使用 go_router 的 go() 方法
- **页面跳转**：使用 push() 方法
- **模态对话**：使用 showDialog() 或 showModalBottomSheet()
- **返回**：使用 pop() 或 go() 返回

### 4. 错误处理
- **API 错误**：捕获 ApiException 子类
- **认证错误**：自动跳转登录页
- **用户提示**：使用 ToastService

### 5. 性能优化
- **图片缓存**：使用 CachedNetworkImage
- **列表优化**：使用 ListView.builder
- **动画优化**：使用 AnimationController 和 Tween
- **资源管理**：及时释放音频资源

---

## 七、开发建议

### 命名规范
- 页面文件：`*_page.dart`
- 组件文件：`*_widget.dart` 或 `*_card.dart`
- 模型文件：`*_model.dart` 或 `*_models.dart`
- 服务文件：`*_service.dart`

### 代码组织
- 每个 TabBar 页面独立目录
- 共享组件放在 common/widgets
- 服务放在 core/services
- 模型放在各功能目录的 models 子目录

### 测试策略
- 单元测试：Services 和 Models
- Widget 测试：Components 和 Pages
- 集成测试：完整用户流程

---

## 八、后续扩展方向

1. **新增页面**：遵循现有目录结构
2. **新增功能**：在对应 TabBar 页面下扩展
3. **新增服务**：在 core/services 下添加
4. **新增模型**：在各功能目录的 models 下添加
