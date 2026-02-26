# Features 目录结构规划

## 概述

本文档详细说明 Bipupu 应用的 `features` 目录结构，按照 TabBar 分页规划进行组织。

## 完整目录结构

```
mobile/lib/features/
│
├── layout/                          # 应用布局和导航
│   ├── main_layout.dart             # 主布局（包含 TabBar）
│   ├── enhanced_bottom_navigation.dart  # 底部导航栏
│   └── discover_page.dart           # 发现页面
│
├── home/                            # A. 首页
│   ├── pages/
│   │   └── home_page.dart           # 首页主体
│   └── widgets/
│       ├── device_card.dart         # 设备连接卡片
│       ├── quick_action_card.dart   # 快速操作卡片
│       └── welcome_header.dart      # 欢迎头部
│
├── pager/                           # B. 对讲机
│   ├── pages/
│   │   └── pager_page.dart          # 对讲主页面
│   ├── widgets/
│   │   ├── operator_gallery.dart    # 接线员库选择
│   │   ├── voice_assistant_panel.dart  # 语音助手面板
│   │   ├── waveform_widget.dart     # 波形显示
│   │   ├── waveform_controller.dart # 波形控制器
│   │   └── waveform_painter.dart    # 波形绘制
│   └── models/
│       └── pager_models.dart        # 对讲相关模型
│
├── messages/                        # C. 消息中心
│   ├── pages/
│   │   ├── messages_page.dart       # 消息列表主页
│   │   ├── message_detail_page.dart # 消息详情页
│   │   └── subscription_management_page.dart  # 订阅管理页
│   ├── widgets/
│   │   ├── message_filter_bar.dart  # 消息过滤栏
│   │   ├── message_list_item.dart   # 消息列表项
│   │   └── socket_status_indicator.dart  # Socket 状态指示
│   └── models/
│       └── message_models.dart      # 消息相关模型
│
├── profile/                         # D. 个人中心
│   ├── pages/
│   │   ├── profile_page.dart        # 个人中心主页
│   │   ├── profile_edit_page.dart   # 个人信息编辑
│   │   ├── security_page.dart       # 账号与安全
│   │   ├── settings_page.dart       # 应用设置
│   │   ├── about_page.dart          # 关于应用
│   │   ├── language_page.dart       # 语言选择
│   │   ├── notifications_page.dart  # 通知设置
│   │   └── privacy_page.dart        # 隐私设置
│   ├── widgets/
│   │   ├── profile_header.dart      # 个人信息头部
│   │   ├── setting_section.dart     # 设置分组
│   │   └── theme_selector.dart      # 主题选择器
│   └── models/
│       └── profile_models.dart      # 个人中心模型
│
├── contacts/                        # 联系人管理
│   ├── pages/
│   │   ├── contacts_page.dart       # 联系人列表
│   │   └── user_search_page.dart    # 用户搜索
│   └── widgets/
│       └── contact_list_item.dart   # 联系人列表项
│
├── bluetooth/                       # 蓝牙设备管理
│   ├── pages/
│   │   ├── bluetooth_scan_page.dart # 蓝牙扫描
│   │   └── device_detail_page.dart  # 设备详情
│   └── widgets/
│       └── device_list_item.dart    # 设备列表项
│
├── assistant/                       # 语音助手
│   ├── assistant_controller.dart    # 助手控制器
│   └── assistant_config.dart        # 助手配置
│
├── common/                          # 通用组件和工具
│   ├── widgets/
│   │   ├── app_button.dart          # 应用按钮
│   │   └── setting_tile.dart        # 设置项
│   └── placeholder_page.dart        # 占位页面
│
├── voice_test/                      # 语音测试
│   └── voice_test_page.dart         # 语音测试页面
│
└── auth/                            # 认证相关
    ├── pages/
    │   ├── login_page.dart          # 登录页
    │   └── register_page.dart       # 注册页
    └── widgets/
        └── auth_form.dart           # 认证表单
```

## 各模块详细说明

### 1. Layout 模块（应用布局）

**职责：** 管理应用的整体布局和导航结构

**文件说明：**
- `main_layout.dart` - 主布局容器，包含 TabBar 和页面切换逻辑
- `enhanced_bottom_navigation.dart` - 底部导航栏组件
- `discover_page.dart` - 发现页面（可选）

**依赖：** 所有 TabBar 页面

---

### 2. Home 模块（首页）

**职责：** 展示应用首页，提供快速操作入口

**页面：**
- `home_page.dart` - 首页主体

**组件：**
- `device_card.dart` - 蓝牙设备连接状态卡片
- `quick_action_card.dart` - 快速操作卡片（订阅、好友、语音测试）
- `welcome_header.dart` - 欢迎信息头部

**依赖服务：**
- `BluetoothDeviceService` - 蓝牙设备管理
- `ImService` - 消息服务

**导航入口：**
- 设备控制 → `/bluetooth/scan` 或 `/bluetooth/device`
- 订阅管理 → `/messages/subscriptions`
- 好友 → `/contacts`
- 语音测试 → `/voice_test`

---

### 3. Pager 模块（对讲机）

**职责：** 提供语音对讲和文本消息发送功能

**页面：**
- `pager_page.dart` - 对讲主页面

**组件：**
- `operator_gallery.dart` - 接线员库选择（Modal）
- `voice_assistant_panel.dart` - 语音助手面板
- `waveform_widget.dart` - 波形显示组件
- `waveform_controller.dart` - 波形控制逻辑
- `waveform_painter.dart` - 波形绘制

**模型：**
- `pager_models.dart` - 对讲相关数据模型

**依赖服务：**
- `AssistantController` - 语音助手
- `ImService` - 消息服务
- `VoiceService` - 语音服务

**特性：**
- 长按对讲机按钮启动语音录制
- 双模式切换（语音/直接）
- 接线员库管理
- 消息缓冲和强制发送

---

### 4. Messages 模块（消息中心）

**职责：** 管理消息列表、过滤和详情展示

**页面：**
- `messages_page.dart` - 消息列表主页
- `message_detail_page.dart` - 消息详情页
- `subscription_management_page.dart` - 订阅管理页

**组件：**
- `message_filter_bar.dart` - 消息过滤栏（已接收/已发送/订阅/管理）
- `message_list_item.dart` - 消息列表项
- `socket_status_indicator.dart` - Socket 连接状态指示

**模型：**
- `message_models.dart` - 消息相关数据模型

**依赖服务：**
- `ImService` - 消息服务
- `AuthService` - 认证服务

**特性：**
- 四层消息过滤
- Socket 连接状态显示
- 消息刷新和缓存管理
- 消息详情查看
- 订阅设置管理

---

### 5. Profile 模块（个人中心）

**职责：** 管理用户信息、账号安全和应用设置

**页面：**
- `profile_page.dart` - 个人中心主页
- `profile_edit_page.dart` - 个人信息编辑
- `security_page.dart` - 账号与安全
- `settings_page.dart` - 应用设置
- `about_page.dart` - 关于应用
- `language_page.dart` - 语言选择
- `notifications_page.dart` - 通知设置
- `privacy_page.dart` - 隐私设置

**组件：**
- `profile_header.dart` - 用户信息头部
- `setting_section.dart` - 设置分组
- `theme_selector.dart` - 主题选择器

**模型：**
- `profile_models.dart` - 个人中心数据模型

**依赖服务：**
- `AuthService` - 认证服务
- `ThemeService` - 主题服务
- `BluetoothDeviceService` - 蓝牙设备管理

**特性：**
- 用户头像和基本信息
- Bipupu ID 复制功能
- 蓝牙设备管理入口
- 账号安全设置
- 语言和主题选择
- 缓存清理和退出登录

---

### 6. Contacts 模块（联系人）

**职责：** 管理联系人列表和搜索

**页面：**
- `contacts_page.dart` - 联系人列表
- `user_search_page.dart` - 用户搜索

**组件：**
- `contact_list_item.dart` - 联系人列表项

**依赖服务：**
- `AuthService` - 认证服务
- `ImService` - 消息服务

**导航入口：**
- 来自 Home 页面的"好友"快速入口
- 来自 Messages 页面的发送者信息

---

### 7. Bluetooth 模块（蓝牙设备）

**职责：** 管理蓝牙设备扫描和连接

**页面：**
- `bluetooth_scan_page.dart` - 蓝牙设备扫描
- `device_detail_page.dart` - 设备详情和控制

**组件：**
- `device_list_item.dart` - 设备列表项

**依赖服务：**
- `BluetoothDeviceService` - 蓝牙设备管理

**导航入口：**
- 来自 Home 页面的"设备控制"
- 来自 Profile 页面的"蓝牙设备"

---

### 8. Assistant 模块（语音助手）

**职责：** 管理语音识别和合成

**文件：**
- `assistant_controller.dart` - 助手控制器
- `assistant_config.dart` - 助手配置

**依赖服务：**
- `ASREngine` - 语音识别
- `TTSEngine` - 语音合成
- `VoiceService` - 语音服务

**使用场景：**
- Pager 页面的语音对讲
- 语音测试页面

---

### 9. Common 模块（通用组件）

**职责：** 提供应用级别的通用组件

**组件：**
- `app_button.dart` - 应用按钮
- `setting_tile.dart` - 设置项
- `placeholder_page.dart` - 占位页面

**使用场景：**
- 所有页面的按钮
- Profile 页面的设置项
- 开发中的占位页面

---

### 10. Voice Test 模块（语音测试）

**职责：** 提供语音功能测试页面

**页面：**
- `voice_test_page.dart` - 语音测试页面

**依赖服务：**
- `VoiceService` - 语音服务
- `ASREngine` - 语音识别
- `TTSEngine` - 语音合成

**特性：**
- TTS 测试（文本转语音）
- ASR 测试（语音转文本）
- 音量显示
- 波形显示

---

### 11. Auth 模块（认证）

**职责：** 管理用户登录和注册

**页面：**
- `login_page.dart` - 登录页
- `register_page.dart` - 注册页

**组件：**
- `auth_form.dart` - 认证表单

**依赖服务：**
- `AuthService` - 认证服务

**特性：**
- 用户名/密码登录
- 用户注册
- 表单验证
- 错误提示

---

## 导航路由映射

| 路由 | 页面 | 模块 |
|------|------|------|
| `/home` | HomePage | home |
| `/pager` | PagerPage | pager |
| `/messages` | MessagesPage | messages |
| `/profile` | ProfilePage | profile |
| `/messages/detail` | MessageDetailPage | messages |
| `/messages/subscriptions` | SubscriptionManagementPage | messages |
| `/profile/personal_info` | ProfileEditPage | profile |
| `/profile/security` | SecurityPage | profile |
| `/profile/settings` | SettingsPage | profile |
| `/profile/about` | AboutPage | profile |
| `/profile/language` | LanguagePage | profile |
| `/profile/notifications` | NotificationsPage | profile |
| `/profile/privacy` | PrivacyPage | profile |
| `/bluetooth/scan` | BluetoothScanPage | bluetooth |
| `/bluetooth/device` | DeviceDetailPage | bluetooth |
| `/contacts` | ContactsPage | contacts |
| `/contacts/search` | UserSearchPage | contacts |
| `/voice_test` | VoiceTestPage | voice_test |
| `/login` | UserLoginPage | auth |
| `/register` | UserRegisterPage | auth |

---

## 文件命名规范

### 页面文件
```
*_page.dart
例如：home_page.dart, pager_page.dart
```

### 组件文件
```
*_widget.dart 或 *_card.dart 或 *_item.dart
例如：device_card.dart, message_list_item.dart
```

### 模型文件
```
*_model.dart 或 *_models.dart
例如：pager_models.dart, message_models.dart
```

### 控制器文件
```
*_controller.dart
例如：assistant_controller.dart
```

### 配置文件
```
*_config.dart
例如：assistant_config.dart
```

---

## 导入规范

### 页面导入
```dart
// 导入同模块的组件
import 'widgets/device_card.dart';

// 导入通用组件
import '../common/widgets/app_button.dart';

// 导入服务
import '../../core/services/bluetooth_device_service.dart';

// 导入模型
import 'models/pager_models.dart';
```

### 避免循环导入
- 页面不应导入其他页面
- 组件不应导入页面
- 模型不应导入页面或组件

---

## 开发流程

### 1. 新增页面
```
1. 在对应模块的 pages/ 目录下创建 *_page.dart
2. 在 lib/main.dart 中添加路由
3. 在 layout/main_layout.dart 中添加导航入口（如需要）
```

### 2. 新增组件
```
1. 在对应模块的 widgets/ 目录下创建 *_widget.dart
2. 在页面中导入并使用
3. 如果是通用组件，放在 common/widgets/
```

### 3. 新增模型
```
1. 在对应模块的 models/ 目录下创建 *_models.dart
2. 在页面或组件中导入并使用
```

### 4. 新增服务
```
1. 在 core/services/ 目录下创建 *_service.dart
2. 在需要的页面或组件中导入并使用
3. 在 main.dart 中初始化（如需要）
```

---

## 最佳实践

### 1. 模块独立性
- 每个模块应该尽可能独立
- 避免模块间的直接依赖
- 通过服务层进行通信

### 2. 代码复用
- 通用组件放在 common/widgets/
- 通用模型放在 core/models/
- 通用服务放在 core/services/

### 3. 性能优化
- 使用 ListView.builder 处理长列表
- 使用 CachedNetworkImage 缓存图片
- 及时释放资源（音频、蓝牙等）

### 4. 错误处理
- 捕获 API 异常
- 显示用户友好的错误提示
- 记录详细的错误日志

### 5. 测试
- 为 Services 编写单元测试
- 为 Pages 编写 Widget 测试
- 为完整流程编写集成测试
