很棒的需求规划！考虑到您的全栈开发背景，以及 App 端（Flutter）、物理终端（pupu机）和服务器端的需求，我将为您规划一个现代、清晰、可靠的 Flutter 项目结构，并初步设计模块和页面。

### Flutter 项目结构与规划

我们将采用 Clean Architecture 的思想，结合 BLoC/Cubit 进行状态管理，确保项目的高可维护性、可测试性和可扩展性。

**核心思想：**

*   **分层设计：** 将应用逻辑划分为数据层、领域层和展示层。
*   **依赖倒置：** 高层模块不依赖低层模块，它们都依赖抽象。
*   **松耦合：** 模块之间尽可能独立。

**项目目录结构：**

```
lib/
├── core/                  # 核心通用组件和抽象
│   ├── error/             # 错误处理模型和异常
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/           # 网络请求相关的工具和抽象
│   │   ├── network_info.dart
│   │   └── api_client.dart
│   ├── usecases/          # 所有领域层用例的通用抽象
│   │   └── usecase.dart
│   └── util/              # 通用工具函数、常量、主题等
│       ├── constants.dart
│       ├── app_theme.dart
│       ├── validators.dart
│       └── logger.dart
├── features/              # 按功能划分的模块 (每个feature包含其独立的data, domain, presentation)
│   ├── auth/              # 用户认证与管理
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_user.dart
│   │   │       ├── register_user.dart
│   │   │       ├── bind_device.dart
│   │   │       └── ...
│   │   └── presentation/
│   │       ├── bloc/ (或 cubit/)
│   │       │   ├── auth_bloc.dart
│   │       │   └── auth_event.dart, auth_state.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   ├── register_page.dart
│   │       │   ├── device_binding_page.dart
│   │       │   └── ...
│   │       └── widgets/
│   │           ├── auth_form_widget.dart
│   │           └── ...
│   ├── profile/           # 个人资料与设置
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/...
│   ├── message/           # 语音交互与消息管理
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/...
│   ├── cosmos_comm/       # 宇宙传讯与AI功能
│   │   ├── data/...
│   │   ├── domain/...
│   │   └── presentation/...
│   └── device_pupu/       # pupu机连接与控制 (蓝牙通信)
│       ├── data/
│       │   ├── datasources/
│       │   │   └── pupu_bluetooth_datasource.dart
│       │   ├── models/
│       │   │   └── pupu_device_model.dart
│       │   └── repositories/
│       │       └── pupu_device_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── pupu_device.dart
│       │   ├── repositories/
│       │   │   └── pupu_device_repository.dart
│       │   └── usecases/
│       │       ├── scan_devices.dart
│       │       ├── connect_device.dart
│       │       ├── send_message_to_pupu.dart
│       │       └── ...
│       └── presentation/
│           ├── bloc/...
│           ├── pages/
│           │   ├── device_scan_page.dart
│           │   └── device_detail_page.dart
│           └── widgets/...
├── injected_dependencies.dart # 依赖注入 (使用get_it或provider)
├── main.dart              # 应用入口
└── routes.dart            # 路由管理 (使用go_router或auto_route)
```

**各层职责说明：**

1.  **`core/` (核心层):**
    *   **`error/`**: 定义应用程序的通用错误和异常类型。
    *   **`network/`**: 封装网络请求的通用逻辑，例如 `Dio` 客户端配置、网络状态检测等。
    *   **`usecases/`**: 所有业务逻辑用例的抽象基类，确保用例的输入输出规范化。
    *   **`util/`**: 存放所有跨模块的通用工具、常量、主题、日志等。

2.  **`features/` (功能模块层):** 这是您的主要业务逻辑所在。每个功能模块（如 `auth`, `profile` 等）内部又遵循 Clean Architecture 的分层：
    *   **`data/` (数据层):**
        *   **`datasources/`**: 定义数据源的抽象（Remote/Local），负责与外部数据（API、本地存储、蓝牙等）交互。
            *   `RemoteDataSource`: 负责网络 API 请求。
            *   `LocalDataSource`: 负责本地持久化存储（如 SharedPreferences, Hive, SQLite）。
            *   `BluetoothDataSource`: 负责蓝牙设备的扫描、连接、数据读写。
        *   **`models/`**: 定义数据传输对象 (DTOs)，通常是 `Entity` 的子类，用于与 `DataSource` 交互时的数据结构。负责 JSON 序列化/反序列化。
        *   **`repositories/`**: `Repository` 接口的实现，负责协调 `DataSource`s，处理数据缓存、错误转换等逻辑。
    *   **`domain/` (领域层):**
        *   **`entities/`**: 定义纯粹的业务实体，不包含任何外部框架或数据源的细节。
        *   **`repositories/`**: 定义 `Repository` 的抽象接口，由 `data` 层实现。
        *   **`usecases/`**: 包含业务逻辑的核心，每个 `UseCase` 代表一个独立的业务操作。它们调用 `Repository` 接口来获取数据，并对 `Entity` 进行操作。
    *   **`presentation/` (展示层):**
        *   **`bloc/` (或 `cubit/`)**: 负责管理 UI 状态和业务逻辑的协调。接收 UI 事件，调用 `UseCase`s，并发出新的状态供 UI 渲染。
        *   **`pages/`**: 实际的 UI 页面，监听 `Bloc/Cubit` 的状态变化并渲染界面。
        *   **`widgets/`**: 可复用的 UI 组件。

3.  **`injected_dependencies.dart`**: 用于设置和配置所有模块的依赖注入。
4.  **`main.dart`**: 应用的入口点，负责初始化应用、注册依赖。
5.  **`routes.dart`**: 集中管理应用的路由，便于导航和参数传递。

### 模块设计与页面划分

基于您的需求，我们可以将 App 端和 `pupu机` 的相关功能划分成以下模块：

---

### App 端模块与页面设计

#### 1. **Auth (用户认证与管理)**
*   **功能点：** 注册、登录、绑定设备、密码管理、用户协议、退出登录。
*   **页面：**
    *   `LoginPage`: 用户登录。
    *   `RegisterPage`: 用户注册。
    *   `ForgotPasswordPage`: 找回密码。
    *   `ChangePasswordPage`: 修改密码 (登录后)。
    *   `DeviceBindingPage`: 绑定 "pupu机" 和 "Bipupu ID"。
    *   `UserAgreementPage`: 用户协议。

#### 2. **Profile (个人资料与设置)**
*   **功能点：** 查看/修改头像、个人信息（生日、星座、八字、MBTI）、隐私设置（黑名单、冷却机制、消息保护）。
*   **页面：**
    *   `ProfileHomePage`: 个人中心主页，展示头像、昵称、部分信息概览。
    *   `EditProfilePage`: 编辑个人资料页面（头像、昵称、生日、星座、八字、MBTI）。
    *   `PrivacySettingsPage`: 隐私设置页面（黑名单列表、冷却机制开关/设置、消息保护开关）。

#### 3. **Message (语音交互与消息管理)**
*   **功能点：** 语音输入、消息列表（已发送、已收到）、收藏、删除、导出/打印。
*   **页面：**
    *   `MessageListPage`: 消息列表（Tab 或 Segmented Control 切换“已发送”和“已收到”）。
    *   `MessageDetailPage`: 单条消息详情，包含语音播放、文字显示、收藏/删除按钮。
    *   `VoiceInputPage`: 语音输入界面（按住说话按钮，显示语音波形）。
    *   `ExportPrintPage`: 选择消息进行导出或打印的预览和设置页面，提供模板选择。

#### 4. **CosmosComm (宇宙传讯与AI功能)**
*   **功能点：** 订阅、设定接收时间、AI运算生成运势、推送运势。
*   **页面：**
    *   `CosmosCommSettingsPage`: 宇宙传讯服务的开通/关闭、接收时间设定。
    *   `DailyFortunePage`: 展示每日运势信息（可能是一个主页面的卡片或独立页面）。

#### 5. **Home/Dashboard (主页/仪表盘)**
*   **功能点：** 聚合展示核心信息，如每日运势、最新消息提醒、pupu机状态等。
*   **页面：**
    *   `HomePage`: 应用主页，可能包含 TabBarNavigation (例如：首页、消息、设备、我的)。

#### 6. **DevicePupu (pupu机连接与控制)**
*   **功能点：** 扫描、连接、控制 pupu机。
*   **页面：**
    *   `DeviceScanPage`: 扫描附近蓝牙设备，显示可用 pupu机列表。
    *   `DeviceDetailPage`: 显示已连接 pupu机状态（电量、连接状态），并提供控制选项（发送消息、设置显示、查看接收信息等）。

---

### 物理终端 (pupu机) 功能模块规划

`pupu机` 主要通过蓝牙与 App 通信，自身具备显示、发光、本地存储和基础语音功能。

1.  **DisplayModule:**
    *   **功能：** 电子钟显示、文字信息显示（来自 App 或本地存储）、电量显示、屏保图案。
    *   **接口：** 接收来自 App 的显示指令（文本内容、屏保图案ID）。

2.  **LightModule:**
    *   **功能：** 来信提醒闪烁、按键常亮作为手电筒。
    *   **接口：** 接收来自 App 的提醒指令、手电筒开关指令。

3.  **StorageModule:**
    *   **功能：** 存储接收到的信息、删除存储的信息。
    *   **接口：** 接收 App 发送的信息进行存储、接收 App 的删除指令、提供读取存储信息的接口供 App 同步。

4.  **ChargingModule:**
    *   **功能：** 设备充电管理、电量状态汇报给 DisplayModule 和 App。

5.  **VoiceModule:**
    *   **功能：** 本地语音识别（将用户在 pupu机上的语音输入转为文字），预设语音导引（虚拟接线员）。
    *   **接口：** 提供语音输入接口，将识别结果通过蓝牙发送给 App；接收 App 的指令触发特定导引语音。

6.  **BluetoothCommunicationModule:**
    *   **功能：** 负责与 App 进行蓝牙低功耗 (BLE) 通信，包括设备发现、连接、服务和特性读写。
    *   **接口：** 上报设备状态（电量、连接状态）、发送本地语音识别结果、接收 App 的控制指令和数据。

---

### 服务器端模块规划

1.  **AuthService (认证服务):**
    *   **功能：** 用户注册、登录、密码管理（重置/修改）、Token 管理（JWT 等）。
    *   **接口：** `/register`, `/login`, `/forgot-password`, `/reset-password`, `/change-password`。

2.  **ProfileService (用户资料服务):**
    *   **功能：** 存储和管理用户个人资料（头像、生日、星座、八字、MBTI），隐私设置（黑名单、冷却、消息保护）。
    *   **接口：** `/profile`, `/profile/{id}`, `/privacy-settings`。

3.  **MessageService (消息服务):**
    *   **功能：** 存储和管理用户发送/接收的消息，消息收藏、删除。
    *   **接口：** `/messages` (GET/POST), `/messages/{id}` (GET/DELETE), `/messages/{id}/favorite`。

4.  **CosmosCommService (宇宙传讯与AI服务):**
    *   **功能：** 管理用户宇宙传讯订阅状态、接收时间配置。
    *   **AI 运算：** 调用 AI 模型进行运势推演，生成每日运势内容。
    *   **推送：** 根据用户设定时间，推送每日运势信息给 App。
    *   **接口：** `/cosmos-comm/subscribe`, `/cosmos-comm/settings`, `/fortune/daily`。

5.  **SpeechToTextService (语音转写服务):**
    *   **功能：** 将 App 或 pupu机上传的语音数据转写成文字。
    *   **接口：** `/stt` (POST 语音文件)。

6.  **DeviceManagementService (设备管理服务):**
    *   **功能：** 管理 "pupu机" 和 "Bipupu ID" 的绑定关系，存储设备状态信息。
    *   **接口：** `/devices/bind`, `/devices/{id}/status`。

7.  **NotificationService (通知服务):**
    *   **功能：** 负责向 App 推送消息、运势等通知（可能通过 FCM/APNs 或 WebSocket）。

---

### 技术栈建议

*   **Flutter App:**
    *   **状态管理:** flutter_bloc
    *   **依赖注入:** `get_it`。
    *   **路由:** `go_router` 
    *   **网络请求:** `dio`。
    *   **本地存储:** `shared_preferences` (简单键值对), `hive` (非关系型数据) 
    *   **蓝牙:** `flutter_blue_plus`
    *   **权限:** `permission_handler`。
*   **Pupu机 (嵌入式):**
    *   根据实际硬件平台和微控制器选择，可能是 C/C++。
    *   蓝牙协议栈 (BLE)。
    *   语音识别库 (本地或轻量级)。
    *   屏幕驱动库。
*   **服务器端:**
    *   **语言/框架:** Python (Flask/Django/FastAPI), Node.js (Express), Go (Gin), Java (Spring Boot)。
    *   **数据库:** PostgreSQL, MongoDB (根据数据结构选择)。
    *   **消息队列:** RabbitMQ, Kafka (用于异步处理语音转写、AI 运算等)。
    *   **AI/ML:** TensorFlow, PyTorch (用于运势推演)。
    *   **部署:** Docker, Kubernetes, CI/CD。

---

这个规划提供了从宏观到微观的视角，希望能帮助您更好地组织开发工作。在实际开发中，可以根据具体情况进行调整和细化。

祝您的项目开发顺利！
