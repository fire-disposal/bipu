## 🛠️ Bipupu 项目级 AI 全局上下文指令 (V3.2)

### 1. 项目概况与视觉基调

* **项目名称**：Bipupu (宇宙传讯)
* **平台属性**：仅移动端 (Android/iOS)，拒绝任何 Web/Desktop 代码。
* **开发模式**：极简重构、快速原型、现代自动化工具链。
* **视觉调性**：**保守浅蓝色系 (Professional Blue)**。默认支持 Dark/Light 模式，全局圆角规范为 **12.0**。

### 2. 技术栈强制约束 (Strict Architecture)

> **必须严格遵守以下选型，严禁引入替代方案：**

* **状态管理**：`hooks_riverpod` + `riverpod_generator`。禁止手写 Provider，必须使用 `@riverpod` 注解。
* **UI 组件逻辑**：`flutter_hooks`。**严禁使用 `StatefulWidget**`，所有局部控制器（Text/Scroll/Animation）必须使用 `use...` 系列 Hooks。
* **主题框架**：`flex_color_scheme` (Scheme: `FlexScheme.material`) + `shadcn_ui`。
* *原则*：严禁硬编码颜色值，必须引用 `Theme.of(context).colorScheme`。


* **数据层**：`retrofit` + `dio` + `freezed`。所有数据模型必须不可变且支持 JSON 序列化。
* **核心插件**：`flutter_blue_plus` (蓝牙)、`sherpa_onnx` (离线语音)、`animate_do` (动效)。

### 3. 目录与导航规范 (Feature-First)

* **lib/core/**：存放全局单例（`theme/`, `api/`, `voice/`, `services/`）。
* **lib/features/{feature_name}/**：按业务切片。
* `logic/`：Riverpod Notifiers。
* `ui/`：`HookConsumerWidget` 页面及 `widgets/` 局部私有组件。


* **lib/shared/**：跨功能复用的原子组件（`widgets/`, `models/`）。
* **导航模式**：**严禁使用路由插件 (如 GoRouter)**。
* **一级页面**：由 `MainLayout` 的 `IndexedStack` 承载。
* **二级/详情页**：直接使用 `Navigator.push(context, MaterialPageRoute(...))`。



### 4. 消息通信协议 (Polling-Only Strategy)

* **核心逻辑**：暂不使用 WebSocket。所有实时消息通过 **长轮询 (Long Polling)** 模拟。
* **网络要求**：使用 `Dio` 请求，`receiveTimeout` 必须设置为 **45秒**（适配后端 30-40秒的挂起）。
* **实现解耦**：UI 必须订阅 `messageStreamProvider`，严禁在 UI 层直接调用轮询请求。
* **功耗优化**：必须使用 `useAppLifecycleState` 监听生命周期。App 进入后台时，轮询间隔强制降级为每分钟一次。

### 5. 编码与打包规范 (DevOps)

* **代码生成**：优先运行 `flutter pub run build_runner watch --delete-conflicting-outputs`。
* **资源处理**：`Sherpa-ONNX` 模型加载必须封装在 `AsyncValue` 中，并优雅处理加载中/失败状态。
* **语义化 UI**：优先使用 `Shadcn` 组件，间距必须引用 `AppSpacing` 常量。
* **安卓打包**：必须开启 ABI 分离 (`--split-per-abi`)，重点优化 `arm64-v8a` 架构。
* **iOS 适配**：在 `Info.plist` 中预置麦克风、蓝牙等隐私权限描述。

### 7. Shadcn UI 特殊规范 (Atomic UI Strategy)
* **规范性**：强制使用 `ShadApp` 包裹。UI 编写必须遵循 Shadcn 的原子化原则，优先通过 `ShadThemeData` 全局配置样式，而非在单个 Widget 中硬编码。
* **一致性**：所有输入框必须使用 `ShadInput`，所有按钮必须使用 `ShadButton`。
* **交互性**：利用 `shadcn_ui` 优秀的内置 `ShadToast` 或 `ShadPopover` 来替代复杂的原生弹窗，减少 UI 层的嵌套深度。
