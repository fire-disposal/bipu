# 虚拟接线员拨号页面架构文档

## 概述

本文档描述了虚拟接线员拨号发信页面的完整架构设计，包括状态机、业务逻辑、UI组件和集成方式。

## 架构设计

### 1. 状态机定义 (`pager_state_machine.dart`)

定义了三个主要状态及其数据结构：

#### State 1: 拨号准备 (DialingPrepState)
```dart
class DialingPrepState extends PagerState {
  final String targetId;              // 目标ID
  final String? selectedContactName;  // 选中的联系人名称
  final bool isLoading;               // 是否加载中
  final String? errorMessage;         // 错误信息
}
```

**职责**：
- 显示九键数字盘供用户输入ID
- 提供联系人选择功能
- 验证输入并准备拨号

#### State 2: 通话中 (InCallState)
```dart
class InCallState extends PagerState {
  final String targetId;              // 目标ID
  final String operatorImageUrl;      // 虚拟接线员立绘URL
  final String currentTtsText;        // 当前TTS文本
  final bool isTtsPlaying;            // TTS是否播放中
  final bool isAsrActive;             // ASR是否激活
  final String asrTranscript;         // ASR转写文本
  final List<double> waveformData;    // 声纹数据
  final bool isSilenceDetected;       // 是否检测到静默
}
```

**职责**：
- 显示虚拟接线员立绘
- 播放TTS引导台词
- 进行ASR语音转写
- 显示实时声纹动效

#### State 3: 发送与结束 (FinalizeState)
```dart
class FinalizeState extends PagerState {
  final String targetId;              // 目标ID
  final String messageContent;        // 消息内容
  final bool isSending;               // 是否发送中
  final bool sendSuccess;             // 是否发送成功
  final String? sendErrorMessage;     // 发送错误信息
  final bool showHangupButton;        // 是否显示挂断按钮
  final bool isPlayingSuccessTts;     // 是否播放成功TTS
}
```

**职责**：
- 显示消息内容确认
- 发送消息到API
- 播放成功TTS
- 提供挂断选项

### 2. 业务逻辑 (PagerCubit)

使用 `flutter_bloc` 的 Cubit 模式管理状态转换和业务流程。

#### 核心方法

```dart
// 初始化拨号准备状态
Future<void> initializeDialingPrep()

// 更新目标ID
void updateTargetId(String id)

// 选择联系人
void selectContact(String contactId, String contactName)

// 开始拨号 - 转换到通话中状态
Future<void> startDialing(String targetId, {String operatorImageUrl = ''})

// 发送消息
Future<void> sendMessage()

// 挂断 - 返回拨号准备状态
Future<void> hangup()

// 取消当前操作
Future<void> cancel()
```

#### 流程图

```
DialingPrepState
    ↓ (startDialing)
InCallState
    ├─ 播放TTS引导台词
    ├─ 启动ASR语音转写
    ├─ 显示实时声纹动效
    └─ 检测到静默后转换
    ↓
FinalizeState
    ├─ 显示消息内容
    ├─ 发送消息到API
    ├─ 播放成功TTS
    └─ 显示挂断按钮
    ↓ (hangup)
DialingPrepState
```

### 3. UI组件

#### 3.1 虚拟接线员立绘 (OperatorDisplayWidget)

```dart
class OperatorDisplayWidget extends StatefulWidget {
  final String imageUrl;              // 立绘URL或Asset路径
  final bool isAnimating;             // 是否播放动画
  final double scale;                 // 缩放比例
  final Duration animationDuration;   // 动画时长
}
```

**特性**：
- 支持网络URL和Asset路径
- 自动缓存网络图片
- 错误处理和占位符
- 进入/退出动画

#### 3.2 实时声纹动效 (WaveformAnimationWidget)

```dart
class WaveformAnimationWidget extends StatefulWidget {
  final List<double> waveformData;    // 声纹数据 (0-1范围)
  final bool isActive;                // 是否激活动画
  final Color waveColor;              // 波形颜色
  final double height;                // 高度
}
```

**特性**：
- 使用 CustomPainter 绘制声波
- 实时数据驱动动画
- 支持多种颜色主题

#### 3.3 其他动效组件

- `PulseAnimationWidget`: 圆形脉冲动效（录音/播放指示）
- `SpectrumAnimationWidget`: 频谱分析动效

### 4. 页面结构

#### 4.1 拨号准备页面 (DialingPrepPage)

```
┌─────────────────────────────────┐
│  标题: 拨号                      │
├─────────────────────────────────┤
│  ID输入框 + 联系人按钮          │
├─────────────────────────────────┤
│  九键数字盘                      │
│  1 2 3                           │
│  4 5 6                           │
│  7 8 9                           │
│  * 0 #                           │
├─────────────────────────────────┤
│  [删除] [清空]                   │
│  [拨号]                          │
└─────────────────────────────────┘
```

#### 4.2 通话中页面 (InCallPage)

```
┌─────────────────────────────────┐
│  通话中 | 目标ID: xxx | [取消]   │
├─────────────────────────────────┤
│                                 │
│      虚拟接线员立绘              │
│                                 │
├─────────────────────────────────┤
│  声纹动效                        │
├─────────────────────────────────┤
│  接线员说: "您好，请说出..."    │
├─────────────────────────────────┤
│  您说: "我想发送一条消息"       │
├─────────────────────────────────┤
│  状态: 正在录音...              │
├─────────────────────────────────┤
│  [暂停] [挂断]                   │
└─────────────────────────────────┘
```

#### 4.3 发送与结束页面 (FinalizePage)

```
┌─────────────────────────────────┐
│  消息准备 | 目标ID: xxx | [已发送]│
├─────────────────────────────────┤
│  消息内容                        │
│  ┌─────────────────────────────┐ │
│  │ 我想发送一条消息            │ │
│  │ 字数: 10                    │ │
│  └─────────────────────────────┘ │
├─────────────────────────────────┤
│  消息已准备就绪                  │
│  点击下方"发送"按钮确认发送     │
├─────────────────────────────────┤
│  [发送]                          │
│  [返回]                          │
└─────────────────────────────────┘
```

### 5. 集成方式

#### 5.1 在路由中使用

```dart
// 在 go_router 配置中
GoRoute(
  path: '/pager',
  builder: (context, state) => const PagerPageRefactored(),
),
```

#### 5.2 在其他页面中导航

```dart
// 使用 AppPages.push
AppPages.push(context, '/pager');

// 或直接使用 Navigator
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const PagerPageRefactored()),
);
```

### 6. 依赖关系

#### 外部依赖
- `flutter_bloc`: 状态管理
- `cached_network_image`: 网络图片缓存
- `sound_stream`: 音频录制
- `just_audio`: 音频播放
- `sherpa_onnx`: ASR语音识别（可选）

#### 内部依赖
- `ApiClient`: API调用
- `VoiceService`: TTS/ASR服务
- `AuthService`: 认证服务

### 7. 错误处理

所有异步操作都包含 try-catch 处理：

```dart
try {
  // 业务逻辑
} on ApiException catch (e) {
  // API错误处理
  emit(PagerErrorState(message: e.message));
} catch (e) {
  // 通用错误处理
  emit(PagerErrorState(message: '操作失败: $e'));
}
```

### 8. 扩展点

#### 8.1 自定义立绘
修改 `operatorImageUrl` 参数：
```dart
await cubit.startDialing(
  targetId,
  operatorImageUrl: 'https://example.com/operator.png',
);
```

#### 8.2 自定义TTS文本
修改 `_playGuidanceTts()` 方法中的 `guidanceText`

#### 8.3 集成真实ASR
替换 `_simulateAsrTranscription()` 中的模拟逻辑，集成 sherpa_onnx ASR引擎

#### 8.4 自定义联系人选择
实现 `_handleSelectContact()` 方法，集成联系人列表

## 文件结构

```
mobile/lib/pages/pager/
├── pager_page_refactored.dart       # 主页面框架
├── state/
│   ├── pager_state_machine.dart     # 状态定义
│   └── pager_cubit.dart             # 业务逻辑
├── pages/
│   ├── dialing_prep_page.dart       # 拨号准备页面
│   ├── in_call_page.dart            # 通话中页面
│   └── finalize_page.dart           # 发送与结束页面
├── widgets/
│   ├── operator_display_widget.dart # 虚拟接线员立绘
│   └── waveform_animation_widget.dart # 声纹动效
└── ARCHITECTURE.md                  # 本文档
```

## 使用示例

### 基础使用

```dart
// 在页面中使用
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const PagerPageRefactored();
  }
}
```

### 高级使用

```dart
// 自定义Cubit
final cubit = PagerCubit(
  apiClient: customApiClient,
  voiceService: customVoiceService,
);

// 监听状态变化
cubit.stream.listen((state) {
  if (state is FinalizeState && state.sendSuccess) {
    print('消息已发送');
  }
});

// 手动触发操作
await cubit.startDialing('12345');
```

## 性能优化

1. **图片缓存**: 使用 `cached_network_image` 自动缓存立绘
2. **动画优化**: 使用 `SingleTickerProviderStateMixin` 管理动画控制器
3. **内存管理**: 在 `dispose()` 中释放所有资源
4. **异步处理**: 使用 `Future` 和 `async/await` 避免阻塞UI

## 测试建议

1. **单元测试**: 测试 Cubit 的状态转换逻辑
2. **Widget测试**: 测试各个页面的UI渲染
3. **集成测试**: 测试完整的拨号流程

## 常见问题

### Q: 如何自定义立绘？
A: 在 `startDialing()` 时传入 `operatorImageUrl` 参数

### Q: 如何集成真实的ASR？
A: 修改 `_simulateAsrTranscription()` 方法，集成 sherpa_onnx

### Q: 如何处理网络错误？
A: 所有API调用都在 try-catch 中，错误会转换为 `PagerErrorState`

### Q: 如何自定义TTS文本？
A: 修改 `_playGuidanceTts()` 和 `_playSuccessTts()` 方法

## 更新日志

- v1.0.0 (2026-02-26): 初始版本，包含三个状态和完整UI
