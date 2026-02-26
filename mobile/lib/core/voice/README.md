# Voice Service 语音服务层

## 概述

极简化的语音推理服务层，提供 ASR（语音识别）和 TTS（文本转语音）功能。

## 核心组件

### 1. VoiceService（推荐使用）
极简 TTS 朗读服务，一行代码即可播放语音。

**使用示例：**
```dart
// 初始化（首次调用自动初始化）
await VoiceService().speak('你好', sid: 0);

// 停止播放
await VoiceService().stop();

// 清理资源
VoiceService().dispose();
```

### 2. TTSEngine
文本转语音引擎，负责模型初始化和音频生成。

**特点：**
- 单例模式
- 自动模型加载和缓存
- 支持多说话人（sid）和语速调整

### 3. ASREngine
语音识别引擎，负责实时音频识别。

**特点：**
- 单例模式
- 实时流式识别
- 音量检测
- 自动端点检测

### 4. AudioResourceManager
音频资源互斥锁，协调 TTS 和 ASR 的资源竞争。

**特点：**
- 队列式资源分配
- 支持超时控制
- 自动音频会话管理

### 5. ModelManager
模型文件管理器，负责 assets 模型的本地化。

**特点：**
- 自动从 assets 拷贝到本地
- 路径缓存
- 支持多模型管理

## 文件结构

```
voice/
├── voice_service.dart          # 极简 TTS 服务（推荐使用）
├── voice_config.dart           # 配置文件（集中管理模型文件名和参数）
├── tts_engine.dart             # TTS 引擎
├── asr_engine.dart             # ASR 引擎
├── audio_resource_manager.dart # 资源互斥锁
├── model_manager.dart          # 模型管理
└── README.md                   # 本文档
```

## 配置管理

所有模型文件名和参数已集中配置在 [`voice_config.dart`](mobile/lib/core/voice/voice_config.dart)：

```dart
// ASR 模型文件
VoiceConfig.asrModelFiles  // 模型文件映射
VoiceConfig.asrEncoder     // 编码器文件名
VoiceConfig.asrDecoder     // 解码器文件名
VoiceConfig.asrJoiner      // 合并器文件名
VoiceConfig.asrTokens      // 词表文件名

// TTS 模型文件
VoiceConfig.ttsModelFiles  // 模型文件映射
VoiceConfig.ttsModel       // 模型文件名
VoiceConfig.ttsTokens      // 词表文件名
VoiceConfig.ttsLexicon     // 词典文件名
VoiceConfig.ttsPhone       // 音素 FST 文件名
VoiceConfig.ttsDate        // 日期 FST 文件名
VoiceConfig.ttsNumber      // 数字 FST 文件名
VoiceConfig.ttsHeteronym   # 多音字 FST 文件名

// 配置参数
VoiceConfig.asrSampleRate  // ASR 采样率
VoiceConfig.asrFeatureDim  // ASR 特征维度
VoiceConfig.ttsNumThreads  // TTS 线程数
VoiceConfig.ttsDebug       // TTS 调试模式
```

## 已移除的文件

- `audio_bus.dart` - 已移除，功能整合到 VoiceService

## 快速开始

### TTS 朗读

```dart
import 'package:bipupu/core/voice/voice_service.dart';

// 最简单的用法
await VoiceService().speak('欢迎使用');

// 指定说话人和语速
await VoiceService().speak(
  '这是一条消息',
  sid: 1,
  speed: 1.2,
);
```

### ASR 识别

```dart
import 'package:bipupu/core/voice/asr_engine.dart';

final asr = ASREngine();
await asr.init();

// 开始录音
await asr.startRecording();

// 监听识别结果
asr.onResult.listen((text) {
  print('识别结果: $text');
});

// 监听音量
asr.onVolume.listen((volume) {
  print('音量: $volume');
});

// 停止录音
final result = await asr.stop();
print('最终结果: $result');
```

## 设计原则

1. **极简性**：VoiceService 提供最简单的调用接口
2. **可靠性**：移除了冗余逻辑和重复计算
3. **模块化**：各组件职责清晰，易于维护
4. **资源管理**：自动处理音频资源竞争

## 性能优化

- 消除了重复的音频转换操作
- 移除了未使用的波形数据收集
- 优化了初始化流程
- 简化了配置构建逻辑
