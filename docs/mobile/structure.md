mobile/lib/
├── main.dart                      # 程序入口，初始化 ProviderScope 及 Shadcn UI
├── app.dart                       # 根 Widget，管理 Tab 切换与全局服务生命周期
│
├── core/                          # 核心基础设施层 (全局单例与适配器)
│   ├── api/
│   │   ├── rest_client.dart       # Retrofit 定义 (@RestApi)
│   │   ├── rest_client.g.dart     # Retrofit 生成的代码
│   │   ├── dio_client.dart        # Dio 配置 (含长轮询专属的 Timeout 设置)
│   │   └── api_provider.dart      # 提供普通 API 与长轮询 API 的双实例 Provider
│   ├── bluetooth/
│   │   ├── ble_manager.dart       # FlutterBluePlus 扫描与连接逻辑
│   │   └── ble_provider.dart      # BLE 状态流提供者
│   ├── config/
│   │   ├── app_config.dart        # 应用配置常量
│   │   └── state_management_guide.md # 状态管理指南文档
│   ├── services/                  # 【重点】后台与实时服务
│   │   ├── polling_service.dart   # 核心：基于长轮询的消息拉取引擎 (取代 Socket)
│   │   ├── message_forwarder.dart # 消息转发服务（轮询 → 蓝牙）
│   │   ├── notification_service.dart # 本地通知弹出封装 (flutter_local_notifications)
│   │   ├── avatar_service.dart    # 头像上传服务
│   │   └── toast_service.dart     # Toast 提示服务
│   ├── theme/
│   │   ├── app_theme.dart         # FlexColorScheme 配置 (基于 FlexScheme.material)
│   │   └── design_system.dart     # 存放全局圆角 (12.0)、Padding 等常量
│   └── voice/                     # (目录存在但为空，语音功能待实现)
│
├── shared/                        # 跨业务复用层
│   ├── widgets/
│   │   ├── avatar_uploader.dart   # 头像上传组件
│   │   ├── user_avatar.dart       # 用户头像组件
│   │   ├── service_account_avatar.dart # 服务账号头像组件
│   │   ├── waveform_visualizer.dart # 声波可视化组件
│   │   └── waveform_image_exporter.dart # 声波图像导出组件
│   └── models/
│       ├── user_model.dart        # Freezed 用户实体
│       ├── user_model.g.dart      # Freezed 生成的代码
│       ├── message_model.dart     # Freezed 消息实体 (含 ASR 文本与语音 URL)
│       ├── message_model.g.dart   # Freezed 生成的代码
│       ├── poster_model.dart      # 海报/广告实体
│       ├── poster_model.g.dart    # Freezed 生成的代码
│       ├── service_account_model.dart # 服务账号实体
│       └── service_account_model.g.dart # Freezed 生成的代码
│
└── features/                      # 业务垂直切片 (Feature-First)
    ├── home/                      # 【Tab A】首页广场
    │   ├── logic/
    │   │   ├── home_provider.dart # 广场动态状态管理
    │   │   └── poster_provider.dart # 海报/广告状态管理
    │   └── ui/
    │       ├── home_screen.dart   # 广场主页
    │       └── widgets/
    │           ├── bluetooth_status_card.dart # 蓝牙状态卡片
    │           └── poster_carousel.dart       # 海报轮播组件
    │
    ├── pager/                     # 【Tab B】核心：传唤台
    │   ├── logic/
    │   │   └── pager_notifier.dart # 状态机 (Idle, Calling, Recording, Manual)
    │   └── ui/
    │       ├── pager_screen.dart  # 传唤台主页 (模式 A/B 切换)
    │       └── widgets/
    │           └── waveform_view.dart # 动态声纹 CustomPainter
    │
    ├── message/                   # 【Tab C】消息中心
    │   ├── README.md              # 消息模块说明文档
    │   ├── message.dart           # 消息模块导出文件
    │   ├── logic/
    │   │   ├── message_provider.dart # 订阅 polling_service 的流并过滤当前对话
    │   │   └── message_controller.dart # 发送消息、重发逻辑
    │   └── ui/
    │       ├── message_screen.dart    # 消息主屏幕
    │       ├── message_main_screen.dart # 消息主界面
    │       ├── message_list_screen.dart # 消息列表界面
    │       ├── message_detail_screen.dart # 消息详情界面
    │       ├── service_subscription_screen.dart # 服务订阅界面
    │       └── widgets/
    │           └── msg_bubble.dart # 气泡组件
    │
    ├── profile/                   # 【Tab D】个人中心
    │   ├── logic/
    │   │   └── profile_notifier.dart # 个人设置与本地持久化
    │   └── ui/
    │       ├── profile_screen.dart # 个人主页
    │       └── settings_page.dart  # 软件设置项
    │
    ├── auth/                      # 鉴权模块
    │   ├── logic/
    │   │   └── auth_notifier.dart # Token 管理与登录状态
    │   └── ui/
    │       ├── login_page.dart    # 登录页面
    │       ├── login_debug_page.dart # 调试登录页面
    │       └── register_page.dart # 注册页面
    │
    └── bluetooth/                 # 蓝牙功能模块
        ├── logic/
        │   ├── ble_protocol.dart  # 简单高效的二进制协议定义
        │   └── ble_protocol_service.dart # 蓝牙协议服务实现
        └── ui/
            ├── bluetooth_scan_screen.dart      # 蓝牙扫描页面
            ├── device_control_screen.dart      # 设备控制页面
            └── protocol_control_screen.dart    # 蓝牙协议控制页面

# 蓝牙协议架构说明

## 协议设计原则
1. **尽可能简单** - 最小化协议复杂度
2. **发送人与消息内容分离** - 支持单独传输发送人标识
3. **无电量回报** - 不包含设备电量状态上报

## 协议格式
### 基础协议头
```
[协议版本:1字节][消息类型:1字节]
```

### 消息类型
- `0x01`: 时间同步（手机 → 设备）
- `0x02`: 文本消息（手机 → 设备）
- `0x03`: 确认响应（设备 → 手机）

### 详细格式
1. **时间同步** (6字节):
   ```
   [版本:1][类型:1=0x01][Unix时间戳:4]
   ```

2. **文本消息** (可变长度，最大240字节):
   ```
   [版本:1][类型:1=0x02][发送人ID长度:1][发送人ID...][消息内容...]
   ```

3. **确认响应** (4字节):
   ```
   [版本:1][类型:1=0x03][原始消息类型:1][状态码:1]
   ```

## 服务集成
### 核心服务
1. **PollingService** - 长轮询消息拉取引擎
2. **MessageForwarder** - 监听轮询服务，转发消息到蓝牙设备
3. **BleProtocolService** - 协议编码/解码、设备通信
4. **集成到App生命周期** - 在 `app.dart` 中统一管理

### 数据流
```
轮询服务 → 新消息 → MessageForwarder → BleProtocolService → 蓝牙设备
```

### 自动功能
1. **连接成功后自动时间同步**
2. **实时消息转发**（轮询收到后立即转发）
3. **设备连接状态管理**

## 技术实现
- **UUID**: Nordic UART Service (`6E400001-B5A3-F393-E0A9-E50E24DCCA9E`)
- **MTU**: 最大240字节消息长度
- **编码**: UTF-8 文本编码
- **状态管理**: Riverpod + Hooks
- **错误处理**: 简单重试机制

## 使用方式
1. 用户登录后自动启动蓝牙服务和消息转发
2. 连接蓝牙设备后自动发送时间同步
3. 收到新消息时自动转发到所有连接的设备
4. 可通过 `protocol_control_screen.dart` 手动控制

## 项目状态说明
### 已实现功能
- ✅ 用户认证系统（登录/注册）
- ✅ 长轮询消息拉取引擎
- ✅ 蓝牙设备连接与管理
- ✅ 蓝牙协议通信
- ✅ 消息转发服务
- ✅ 本地通知
- ✅ 头像上传
- ✅ 声波可视化

### 待实现功能
- ❌ 语音识别（sherpa_asr.dart）
- ❌ 语音合成（sherpa_tts.dart）
- ❌ 音频流采样与波动逻辑（audio_logic.dart）
- ❌ 虚拟接线员 UI（operator_panel.dart）

### 技术栈
- **Flutter**: 3.38.0+
- **状态管理**: Riverpod + Hooks
- **UI框架**: Shadcn UI + FlexColorScheme
- **网络**: Dio + Retrofit
- **蓝牙**: FlutterBluePlus
- **本地存储**: SharedPreferences
- **代码生成**: Freezed + Retrofit Generator

### 项目特点
1. **Feature-First 架构** - 按业务功能垂直切片
2. **响应式状态管理** - 基于 Riverpod 的声明式状态
3. **实时消息系统** - 长轮询替代 WebSocket
4. **蓝牙集成** - 支持离线消息转发到硬件设备
5. **模块化设计** - 核心服务与业务逻辑分离
