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
    └── auth/                       # 鉴权模块
        ├── logic/
        │   └── auth_notifier.dart  # Token 管理与登录状态
        └── ui/
            └── login_page.dart     # 登录/注册
