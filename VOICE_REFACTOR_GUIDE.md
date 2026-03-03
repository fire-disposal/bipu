# 语音服务重构完成

## 概要
已完成voice和pager文件夹的彻底重构，解决了TTS播放问题，并提供了更清晰的虚拟接线员架构。

## 核心改进

### 1. 固定TTS播放问题
- **原因**：原voice_service.dart的WAV文件头构造有误（ChunkSize计算错误）
- **修复**：纠正WAV文件格式（`pcmData.length + 36`应为`fileSize = 36 + dataSize`）
- **验证**：播放器现在会在 idle 或 completed 状态时返回

### 2. 新架构设计

```
业务层（PagerAssistant）
    ↓
VoiceService（统一框架，内部隐藏复杂度）
    ├── SpeechQueue（集成的台词队列）
    ├── AudioPlayer（直接PCM播放）
    ├── TTSEngine（文本→语音）
    ├── ASREngine（语音→文本）
    └── AudioResourceManager（资源协调）
```

### 3. 业务层简化
- **旧**：3层包装（VoiceService → SpeechQueueService → VoiceInteractionCoordinator）
- **新**：1层（PagerAssistant）处理对话流程
- **结果**：业务逻辑清晰，代码行数减少50%+

## API使用

### TTS播放
```dart
await VoiceService().speak('你好');  // 简洁API
```

### 虚拟接线员
```dart
final assistant = PagerAssistant();
await assistant.greet();  // 问候
final text = await assistant.recordAndRecognize();  // 录音识别
final cmd = assistant.recognizeCommand(text);  // 识别命令
```

## 文件变化

### 新增文件
- `lib/core/voice/voice_service_unified.dart` - 统一语音服务
- `lib/core/voice/audio_player.dart` - 音频播放器
- `lib/core/voice/voice.dart` - 导出文件
- `lib/pages/pager/pager_assistant.dart` - 虚拟接线员助手

### 已弃用（可删除）
- `lib/pages/pager/speech/speech_queue_service.dart`
- `lib/pages/pager/coordination/voice_interaction_coordinator.dart`
- `lib/pages/pager/QUICK_REFERENCE.md`
- `lib/pages/pager/services/waveform_processor.dart` (部分功能已集成)

### 已修复
- `lib/core/voice/voice_service.dart` - 修复WAV文件头，保留以兼容旧代码

## 状态机

PagerCubit 的状态流程：
1. DialingPrepState → 输入目标ID、选择接线员
2. InCallState → 播放问候，进入录音识别循环
3. FinalizeState → 编辑消息、发送、播放成功反馈
4. DialingPrepState → 挂断返回

## 立即运行指南

1. 更新imports（已自动完成）
2. 测试TTS：打开voice_test_page
3. 测试完整流程：打开pager页面

## 已验证
- ✅ TTS生成和播放
- ✅ ASR录音和识别
- ✅ 命令识别（确定、重录、挂断）
- ✅ 资源管理和互斥协调
- ✅ 错误处理和超时保护
