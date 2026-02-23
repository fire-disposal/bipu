mobile/lib/
├── main.dart                      # 程序入口，初始化 ProviderScope及原生插件
├── app.dart                        # 根 Widget，挂载 FlexColorScheme，管理 Tab 切换与全局 Overlay
│
├── core/                           # 核心基础设施层 (全局单例与适配器)
│   ├── api/
│   │   ├── rest_client.dart        # Retrofit 定义 (@RestApi)
│   │   ├── dio_client.dart         # Dio 配置 (含长轮询专属的 Timeout 设置)
│   │   └── api_provider.dart       # 提供普通 API 与长轮询 API 的双实例 Provider
│   ├── voice/
│   │   ├── sherpa_asr.dart         # 离线识别封装
│   │   ├── sherpa_tts.dart         # 语音合成封装
│   │   └── voice_service.dart      # 语音引擎生命周期管理
│   ├── bluetooth/
│   │   ├── ble_manager.dart        # FlutterBluePlus 扫描与连接逻辑
│   │   └── ble_provider.dart       # BLE 状态流提供者
│   ├── theme/
│   │   ├── app_theme.dart          # FlexColorScheme 配置 (基于 FlexScheme.material)
│   │   └── design_system.dart      # 存放全局圆角 (12.0)、Padding 等常量
│   └── services/                   # 【重点】后台与实时服务
│       ├── polling_service.dart    # 核心：基于长轮询的消息拉取引擎 (取代 Socket)
│       ├── message_forwarder.dart  # 消息转发服务（轮询 → 蓝牙）
│       └── notification_service.dart # 本地通知弹出封装 (flutter_local_notifications)
│
├── shared/                         # 跨业务复用层
│   ├── widgets/
│   │   ├── carousel_banner.dart    # 轮播组件
│   │   ├── bipupu_button.dart      # 统一封装的 Shadcn 风格按钮
│   │   └── empty_state.dart        # 缺省页
│   └── models/
│       ├── user_model.dart         # Freezed 用户实体
│       └── message_model.dart      # Freezed 消息实体 (含 ASR 文本与语音 URL)
│
└── features/                       # 业务垂直切片 (Feature-First)
    ├── home/                       # 【Tab A】首页广场
    │   ├── logic/
    │   │   └── home_provider.dart  # 广场动态、Banner 状态管理
    │   └── ui/
    │       ├── home_screen.dart    # 广场主页
    │       └── widgets/            # 局部私有组件
    │
    ├── pager/                      # 【Tab B】核心：传唤台
    │   ├── logic/
    │   │   ├── pager_notifier.dart # 状态机 (Idle, Calling, Recording, Manual)
    │   │   └── audio_logic.dart    # 语音流采样与波动逻辑
    │   └── ui/
    │       ├── pager_screen.dart   # 传唤台主页 (模式 A/B 切换)
    │       └── widgets/
    │           ├── waveform_view.dart # 动态声纹 CustomPainter
    │           └── operator_panel.dart# 虚拟接线员 UI
    │
    ├── message/                    # 【Tab C】消息中心
    │   ├── logic/
    │   │   ├── chat_provider.dart  # 订阅 polling_service 的流并过滤当前对话
    │   │   └── chat_controller.dart # 发送消息、重发逻辑
    │   └── ui/
    │       ├── message_screen.dart # 消息列表
    │       ├── chat_page.dart      # 聊天详情页
    │       └── widgets/
    │           └── msg_bubble.dart # 气泡组件
    │
    ├── profile/                    # 【Tab D】个人中心
    │   ├── logic/
    │   │   └── profile_notifier.dart # 个人设置与本地持久化
    │   └── ui/
    │       ├── profile_screen.dart # 主页
    │       └── settings_page.dart  # 软件设置项
    │
    ├── auth/                       # 鉴权模块
    │   ├── logic/
    │   │   └── auth_notifier.dart  # Token 管理与登录状态
    │   └── ui/
    │       └── login_page.dart     # 登录/注册
    │
    └── bluetooth/                  # 蓝牙功能模块
        ├── logic/
        │   ├── ble_protocol.dart   # 简单高效的二进制协议定义
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
1. **BleProtocolService** - 协议编码/解码、设备通信
2. **MessageForwarder** - 监听轮询服务，转发消息到蓝牙设备
3. **集成到App生命周期** - 在 `app.dart` 中统一管理

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