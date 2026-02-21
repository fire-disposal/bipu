# Flutter语音助手交互系统架构文档

## 概述

Bipupu应用的Flutter语音助手交互系统是一个基于意图驱动的多模态交互系统，集成了语音识别（ASR）、语音合成（TTS）和自然语言理解（NLU）功能。系统采用状态机模式管理用户交互流程，支持语音和文本两种输入方式，提供虚拟接线员角色选择功能。

## 系统架构

### 核心架构图

```
┌─────────────────────────────────────────────────────────┐
│                   用户界面层 (UI Layer)                  │
├─────────────────────────────────────────────────────────┤
│  PagerPage ──┬── VoiceAssistantPanel ──┬── OperatorGallery │
│              │                          │                  │
│              ├── IntentDrivenAssistantPanel              │
│              │                                          │
│              └── WaveformWidget (波形可视化)            │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                业务逻辑层 (Business Logic)               │
├─────────────────────────────────────────────────────────┤
│  IntentDrivenAssistantController (意图驱动控制器)        │
│  ├── AssistantPhase (业务阶段枚举)                      │
│  ├── UserIntent (用户意图枚举)                          │
│  └── 状态机转换逻辑                                     │
│                                                         │
│  AssistantConfig (助手配置)                             │
│  ├── VirtualOperator (虚拟操作员模型)                   │
│  ├── 关键词组定义                                       │
│  └── 操作员脚本配置                                     │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                语音服务层 (Voice Services)               │
├─────────────────────────────────────────────────────────┤
│  VoiceCommandCenter (语音命令中心)                      │
│  ├── PiperTTSEngine (TTS引擎)                           │
│  │   ├── PiperTtsPlugin (Piper TTS插件)                 │
│  │   └── AudioPlayer (音频播放器)                       │
│  │                                                      │
│  └── VoskASREngine (ASR引擎)                            │
│      ├── RecorderStream (录音流)                        │
│      └── 音频处理与识别                                 │
└─────────────────────────────────────────────────────────┘
```

## 核心组件详解

### 1. IntentDrivenAssistantController (意图驱动控制器)

#### 功能概述
- 统一管理语音助手的业务逻辑和状态转换
- 处理用户意图（语音或UI触发）
- 协调TTS和ASR引擎的交互
- 管理虚拟操作员切换

#### 关键特性
- **状态机设计**：定义了12个业务阶段（AssistantPhase）
- **意图驱动**：支持8种用户意图（UserIntent）
- **防抖机制**：防止语音和UI同时触发导致冲突
- **资源管理**：自动清理音频资源

#### 业务阶段 (AssistantPhase)
```dart
enum AssistantPhase {
  idle,           // 空闲
  greeting,       // 初始化引导
  askRecipientId, // 请提供收信方ID
  confirmRecipientId, // 请确认收信方ID
  guideRecordMessage, // 准备录音
  recording,      // 正在录音
  transcribing,   // 转写中
  confirmMessage, // 请确认消息
  sending,        // 发送中
  sent,           // 已发送
  farewell,       // 结束
  error,          // 出错
}
```

#### 用户意图 (UserIntent)
```dart
enum UserIntent {
  confirm,    // 确认/下一步
  modify,     // 修改/重填
  cancel,     // 取消/退出
  rerecord,   // 重录
  send,       // 最终发送
  start,      // 开始/启动
  stop,       // 停止
}
```

#### 状态转换逻辑
```
空闲(idle) → 开始(start) → 问候(greeting)
问候(greeting) → 确认(confirm) → 询问收信方ID(askRecipientId)
询问收信方ID(askRecipientId) → 确认(confirm) → 确认收信方ID(confirmRecipientId)
确认收信方ID(confirmRecipientId) → 确认(confirm) → 引导录音(guideRecordMessage)
引导录音(guideRecordMessage) → 确认(confirm) → 录音中(recording)
录音中(recording) → 停止(stop) → 转写中(transcribing)
转写中(transcribing) → 确认(confirm) → 确认消息(confirmMessage)
确认消息(confirmMessage) → 发送(send) → 发送中(sending)
发送中(sending) → 自动 → 已发送(sent)
已发送(sent) → 确认(confirm) → 结束(farewell)
结束(farewell) → 确认(confirm) → 空闲(idle)
```

### 2. VoiceCommandCenter (语音命令中心)

#### 功能概述
- 协调TTS和ASR引擎的初始化与交互
- 管理语音输入/输出的状态
- 提供音频流监听功能

#### 核心方法
- `init()`: 初始化语音命令中心
- `startListening()`: 开始监听语音输入
- `stopListening()`: 停止监听并返回结果
- `startTalking()`: 开始语音合成
- `stopTalking()`: 停止语音合成
- `stopAll()`: 停止所有音频活动

### 3. PiperTTSEngine (TTS引擎)

#### 技术栈
- **核心插件**: `piper_tts_plugin`
- **音频播放**: `just_audio`
- **文件管理**: `path_provider`

#### 支持的语音包
```dart
enum PiperVoicePack {
  norman,  // 默认男声
  amy,     // 女声
  // 其他语音包...
}
```

#### 工作流程
1. 初始化Piper TTS插件
2. 加载指定的语音包模型
3. 将文本合成为WAV音频文件
4. 使用AudioPlayer播放生成的音频
5. 清理临时音频文件

### 4. VoskASREngine (ASR引擎)

#### 技术栈
- **录音流**: `sound_stream`
- **权限管理**: `permission_handler`
- **音频处理**: 原生Dart音频处理

#### 功能特性
- 实时音频流处理
- 音量计算与可视化
- 模拟识别结果（实际项目需集成Vosk API）
- 错误处理与状态管理

### 5. AssistantConfig (助手配置)

#### 虚拟操作员系统
系统内置3个虚拟操作员：
1. **op_system**: 系统默认操作员（灰色主题）
2. **op_001**: 专业接线员青年男（青色主题）
3. **op_002**: 温柔接线员女声（粉色主题）

#### 关键词组定义
系统预定义了15个关键词组，包括：
- 问候(greeting): ['你好', '您好', 'hello', 'hi']
- 确认(confirm): ['是的', '对的', '正确', '确认']
- 取消(cancel): ['取消', '不要了', '算了', '停止']
- 发送(send): ['发送', '发出', '发出去', '传送']

#### 操作员脚本
每个操作员都有完整的交互脚本，支持参数替换：
```dart
{
  'greeting': '您好，我是Bipupu语音助手。请问您需要什么帮助？',
  'askRecipientId': '请问您要发送给哪位用户？请提供对方的Bipupu ID。',
  'confirmRecipientId': '您要发送给用户{recipientId}，对吗？',
  'guideRecordMessage': '好的，现在请说出您要发送的消息内容。',
  // ... 更多脚本
}
```

## 用户界面组件

### 1. PagerPage (传呼机主页面)

#### 功能特性
- **双模式切换**: 语音模式 vs 文本模式
- **消息历史**: 显示发送/接收的消息记录
- **操作员选择**: 集成OperatorGallery组件
- **语音助手面板**: 集成VoiceAssistantPanel

#### 界面布局
```
┌─────────────────────────────────────┐
│            AppBar (标题栏)           │
├─────────────────────────────────────┤
│                                     │
│         消息历史显示区域              │
│        (ListView.builder)           │
│                                     │
├─────────────────────────────────────┤
│                                     │
│   语音模式: VoiceAssistantPanel      │
│   或文本模式: 直接输入表单            │
│                                     │
└─────────────────────────────────────┘
```

### 2. VoiceAssistantPanel (语音助手面板)

#### 组件结构
- **阶段指示器**: 显示当前业务阶段和进度
- **操作按钮**: 根据当前阶段显示可用意图按钮
- **操作员选择器**: 显示当前操作员并提供更换功能
- **信息显示**: 显示收信方ID和消息内容

### 3. IntentDrivenAssistantPanel (意图驱动助手面板)

#### 高级功能
- 统一的意图处理接口
- 阶段信息可视化
- 操作员选择器（模态底部表单）
- 参数化脚本播放

### 4. WaveformController & Widgets (波形组件)

#### 功能概述
- 实时音频波形可视化
- 振幅数据缓冲与平滑处理
- 与VoiceCommandCenter的音量流集成

#### 组件组成
1. **WaveformController**: 管理振幅数据流
2. **WaveformPainter**: 自定义绘制波形
3. **WaveformWidget**: 集成显示组件

## 数据流与交互流程

### 典型用户交互流程

#### 语音模式流程
```
用户点击"开始"按钮
    ↓
系统播放问候语（TTS）
    ↓
用户说出收信方ID（ASR）
    ↓
系统确认收信方ID（TTS）
    ↓
用户确认收信方（语音或按钮）
    ↓
系统引导录音（TTS）
    ↓
用户说出消息内容（ASR）
    ↓
系统转写并确认消息（TTS）
    ↓
用户确认发送（语音或按钮）
    ↓
系统发送消息并播放成功提示（TTS）
```

#### 文本模式流程
```
用户切换到文本模式
    ↓
手动输入收信方ID
    ↓
手动输入消息内容
    ↓
点击"发送"按钮
    ↓
系统发送消息
```

### 音频数据流
```
麦克风输入 → RecorderStream → VoskASREngine → 识别结果
    ↓
音量数据 → VolumeStream → WaveformController → 波形显示
    ↓
文本输入 → PiperTTSEngine → 音频文件 → AudioPlayer → 扬声器输出
```

## 错误处理与恢复

### 错误类型
1. **权限错误**: 麦克风权限被拒绝
2. **初始化错误**: TTS/ASR引擎初始化失败
3. **网络错误**: 消息发送失败
4. **超时错误**: 用户响应超时

### 恢复策略
- **权限错误**: 引导用户开启权限
- **初始化错误**: 尝试重新初始化
- **网络错误**: 提示用户检查网络并重试
- **超时错误**: 自动返回空闲状态

## 配置与自定义

### 添加新操作员
1. 在`AssistantConfig.operatorConfigs`中添加配置
2. 定义操作员ID、名称、描述和主题颜色
3. 编写完整的交互脚本
4. 在`IntentDrivenAssistantController._operatorVoiceMap`中映射语音包

### 扩展关键词组
1. 在`AssistantConfig.keywordGroups`中添加新组
2. 定义相关关键词列表
3. 在控制器中调用`matchesKeyword()`方法进行匹配

### 自定义业务阶段
1. 扩展`AssistantPhase`枚举
2. 在控制器中更新状态转换逻辑
3. 添加对应的脚本配置
4. 更新UI阶段指示器

## 性能优化

### 音频资源管理
- **懒加载**: TTS模型按需加载
- **缓存清理**: 自动删除临时音频文件
- **资源释放**: 页面销毁时释放所有音频资源

### 状态管理优化
- **防抖机制**: 防止重复状态转换
- **监听器管理**: 及时添加/移除状态监听器
- **内存管理**: 使用单例模式减少内存占用

### UI性能优化
- **值监听器**: 使用`ValueListenableBuilder`局部刷新
- **列表优化**: 使用`ListView.builder`虚拟滚动
- **动画优化**: 使用轻量级动画组件

## 测试与调试

### 语音测试页面
系统提供了两个测试页面：
1. **VoiceTestPage**: 原始语音测试页面
2. **NewVoiceTestPage**: 新的Piper TTS + 基础录音测试页面

### 测试功能
- TTS合成与播放测试
- 录音功能测试
- 音量可视化测试
- 运行日志记录

### 调试工具
- 详细的运行日志系统
- 状态监控与调试信息
- 错误堆栈跟踪

## 依赖关系

### 主要依赖包
```yaml
dependencies:
  # 语音相关
  sound_stream: ^0.4.2          # 音频流处理
  just_audio: ^0.10.5           # 音频播放
  piper_tts_plugin:             # Piper TTS插件
    git: https://github.com/dev-6768/piper_tts_plugin.git
  vosk_flutter:                 # Vosk ASR引擎
    git: https://github.com/alphacep/vosk-flutter.git
  
  # 权限管理
  permission_handler: ^11.3.1   # 权限处理
  
  # 状态管理
  flutter_bloc: ^9.1.1          # BLoC状态管理
```

## 已知问题与待优化项

### 当前问题
1. **ASR集成**: 当前使用模拟识别结果，需要集成Vosk API
2. **错误处理**: 部分错误处理逻辑需要完善
3. **国际化**: 脚本内容需要支持多语言
4. **性能**: 长文本TTS合成可能较慢

### 优化方向
1. **离线支持**: 增强离线语音识别能力
2. **语音唤醒**: 添加语音唤醒功能
3. **多语言TTS**: 支持更多语言和方言
4. **智能纠错**: 添加语音识别纠错机制
5. **上下文记忆**: 添加对话上下文记忆功能

## 部署与维护

### 环境要求
- Flutter SDK: ^3.10.1
- Android: API 21+
- iOS: 11.0+
- 麦克风权限
- 存储权限（用于缓存音频文件）

### 构建配置
- 确保正确配置Piper TTS插件
- 配置Vosk模型文件路径
- 设置适当的音频采样率
- 配置后台音频播放权限

### 监控指标
- TTS合成成功率
- ASR识别准确率
- 用户交互完成率
- 平均交互时长
- 错误发生率

---

*文档版本: 1.0.0*
*最后更新: 2024年*
*维护团队: Bipupu开发团队*