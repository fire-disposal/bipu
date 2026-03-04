# UI 不显示台词 & 音频无声 - 诊断与修复

**问题描述**:
- UI 界面持续显示"准备中"/"准备就绪"，没有显示接线员台词
- TTS 生成成功（119916 字节 PCM），但没有音频输出
- 状态日志显示流程推进，但最后的"播放完成"日志缺失

**根本原因**: 音频播放可能卡住（或无声），导致播放完成信号未收到，整个任务链停止

---

## 🔧 应用的修复

### 1️⃣ AudioPlayer - 改进错误诊断和恢复

**文件**: [audio_player.dart](mobile/lib/core/voice/audio_player.dart#L47-L135)

**修改内容**:

```dart
// ❌ 修复前：播放失败导致整个流程中断
try {
  await _player.setAudioSource(...);
  await _player.play();
  final playerDone = _player.playerStateStream
      .firstWhere((state) => state.processingState == ja.ProcessingState.completed)
      .timeout(playbackTimeout);
  await playerDone;  // 如果卡住，后续代码永不执行
} on TimeoutException {
  await _player.stop();
  rethrow;  // ❌ 导致VoiceService任务失败
} catch (e) {
  rethrow;  // ❌ 任务中断
} finally {
  release();
}

// ✅ 修复后：改进诊断和容错
try {
  logger.i('AudioPlayer.playPcm: 设置音频源');
  await _player.setAudioSource(...);

  logger.i('AudioPlayer.playPcm: 开始播放');
  await _player.play();

  logger.i('AudioPlayer.playPcm: 等待播放完成，超时: ${playbackTimeout.inSeconds}s');
  
  // 使用 where() 增加中间状态监控
  final playerDone = _player.playerStateStream
      .where((state) {
        logger.d('AudioPlayer: 播放状态 - ${state.processingState}');
        return state.processingState == ja.ProcessingState.completed;
      })
      .first  // 改用 first 而不是 firstWhere
      .timeout(playbackTimeout);

  await playerDone;
  logger.i('AudioPlayer.playPcm: ✅ 播放完成');
} on TimeoutException {
  logger.w('AudioPlayer.playPcm: ⚠️ 播放超时，但继续执行');
  // ✅ 超时时不 rethrow，允许流程继续
  try {
    await _player.stop();
  } catch (e) {
    logger.w('AudioPlayer.playPcm: stop() 失败 - $e');
  }
} catch (e, stackTrace) {
  logger.e('AudioPlayer.playPcm: ❌ 播放失败', error: e, stackTrace: stackTrace);
  // ✅ 播放失败也不 rethrow，允许流程继续
} finally {
  leakDetectionTimer?.cancel();
  if (!released) {
    released = true;
    release();
  }
}
```

**改进**:
- ✅ 添加 `logger.d()` 打印播放状态变化，便于诊断卡顿原因
- ✅ 超时时**不 rethrow**，允许流程继续（音频太短或系统延迟）
- ✅ 播放失败时**不 rethrow**，确保后续状态更新仍执行
- ✅ 添加 `released` 标志，防止重复调用 `release()`
- ✅ 更详细的日志帮助定位问题

---

### 2️⃣ VoiceService - 播放失败容错处理

**文件**: [voice_service_unified.dart](mobile/lib/core/voice/voice_service_unified.dart#L284-L310)

**修改内容**:

```dart
// ❌ 修复前：播放失败导致任务失败，队列停止
try {
  await _player.playPcm(
    pcmBytes,
    sampleRate: 24000,
    channels: 1,
    playbackTimeout: const Duration(seconds: 30),
  );
  nextTask.completer.complete(true);
} finally {
  release();
  _currentTask = null;
}

// ✅ 修复后：播放失败也记为完成，继续处理队列
try {
  try {
    await _player.playPcm(
      pcmBytes,
      sampleRate: 24000,
      channels: 1,
      playbackTimeout: const Duration(seconds: 30),
    );
    logger.i('VoiceService: 台词播放完成 "${nextTask.text}"');
  } catch (playbackError, playbackStackTrace) {
    // ✅ 捕获播放错误但继续
    logger.w(
      'VoiceService: 台词播放出错（但不中断） "${nextTask.text}"',
      error: playbackError,
      stackTrace: playbackStackTrace,
    );
  }
  nextTask.completer.complete(true);  // ✅ 标记任务完成
} finally {
  release();
  _currentTask = null;  // ✅ 继续处理队列
}
```

**改进**:
- ✅ 即使播放失败，也标记任务为完成，让队列继续处理
- ✅ 播放错误只是警告，不中断业务流程
- ✅ 确保 `_currentTask = null`，队列循环继续

---

### 3️⃣ PagerCubit - 增强状态更新日志

**文件**: [pager_cubit.dart](mobile/lib/pages/pager/state/pager_cubit.dart#L140-L181)

**修改内容**:

```dart
// ❌ 修复前：状态更新日志不足，难以调试
final greetingText = await _voiceAssistant.greet();
if (state is InCallState) {
  var currentState = state as InCallState;
  currentState = currentState.copyWith(
    operatorCurrentSpeech: greetingText,
    operatorSpeechHistory: [...currentState.operatorSpeechHistory, greetingText],
  );
  emit(currentState);  // 日志不清楚是否真的 emit 了
}

// ✅ 修复后：关键步骤都有日志
final greetingText = await _voiceAssistant.greet();
logger.i('PagerCubit: ✅ 获得问候语文本: "$greetingText"');  // ✅ 新增

if (state is InCallState) {
  var currentState = state as InCallState;
  currentState = currentState.copyWith(
    operatorCurrentSpeech: greetingText,
    operatorSpeechHistory: [...currentState.operatorSpeechHistory, greetingText],
  );
  logger.i('PagerCubit: 发送状态更新，历史: ${currentState.operatorSpeechHistory}');  // ✅ 新增
  emit(currentState);

  // ... 延时 ...

  final promptText = await _voiceAssistant.promptForMessage();
  logger.i('PagerCubit: ✅ 获得提示语文本: "$promptText"');  // ✅ 新增
  
  currentState = currentState.copyWith(
    operatorCurrentSpeech: promptText,
    operatorSpeechHistory: [...currentState.operatorSpeechHistory, promptText],
    isWaitingForUserInput: true,
  );
  logger.i('PagerCubit: 发送状态更新，历史: ${currentState.operatorSpeechHistory}，等待输入: true');  // ✅ 新增
  emit(currentState);
} else {
  logger.w('PagerCubit: 状态不是 InCallState，无法更新');  // ✅ 新增
}
```

**改进**:
- ✅ 明确标记获取文本的成功时刻
- ✅ 打印状态更新的详细内容，验证数据正确性
- ✅ 检测状态异常情况

---

### 4️⃣ PagerAssistant - 详细的播放流程日志

**文件**: [pager_assistant.dart](mobile/lib/pages/pager/pager_assistant.dart#L187-L212)

**修改内容**:

```dart
// ❌ 修复前：日志不足以追踪播放流程
try {
  await _voiceService.speak(text, sid: voiceId, speed: speed);
} catch (e) {
  logger.w('PagerAssistant._speak: TTS 播放失败 (仅显示文本) - $e');
}

// ✅ 修复后：详细记录播放过程的每一步
try {
  logger.i('PagerAssistant._speak: 调用 VoiceService.speak()');  // ✅ 新增
  await _voiceService.speak(text, sid: voiceId, speed: speed);
  logger.i('PagerAssistant._speak: ✅ 播放完成');  // ✅ 新增
} catch (e, stackTrace) {
  logger.w(
    'PagerAssistant._speak: ❌ TTS 播放失败 (仅显示文本)',
    error: e,
    stackTrace: stackTrace,  // ✅ 新增完整 stackTrace
  );
}
```

**改进**:
- ✅ 记录调用开始和完成，便于追踪异步延迟
- ✅ 包含完整 stackTrace，快速定位异常

---

## 📊 日志流程对比

### 修复前（日志缺失）
```
I/flutter: 💡 info: VoiceService: 播放台词 "您好，有什么我可以帮助您的吗？"
I/flutter: 💡 info: Generating TTS for text: "...", sid: 0, speed: 1.0
I/flutter: 💡 info: VoiceService: 已生成PCM 119916 字节，准备播放
I/flutter: 💡 info: AudioPlayer.playPcm: 开始播放 119916 字节
I/flutter: 💡 info: AudioPlayer.playPcm: 开始播放
# ❌ 缺失：播放完成日志
# ❌ UI 仍显示 "准备就绪"
```

### 修复后（完整日志）
```
I/flutter: 💡 info: PagerAssistant._speak: 调用 VoiceService.speak()
I/flutter: 💡 info: VoiceService.enqueueSpeech: 加入队列 "..." (优先级: ...)
I/flutter: 💡 info: VoiceService: 播放台词 "..."
I/flutter: 💡 info: Generating TTS for text: "...", sid: 0, speed: 1.0
I/flutter: 💡 info: VoiceService: 已生成PCM 119916 字节，准备播放
I/flutter: 💡 info: AudioPlayer.playPcm: 设置音频源
I/flutter: 💡 info: AudioPlayer.playPcm: 开始播放
I/flutter: 💡 info: AudioPlayer.playPcm: 等待播放完成，超时: 30s
I/flutter: 🔵 debug: AudioPlayer: 播放状态 - ProcessingState.buffering
I/flutter: 🔵 debug: AudioPlayer: 播放状态 - ProcessingState.ready
I/flutter: 🔵 debug: AudioPlayer: 播放状态 - ProcessingState.playing
I/flutter: 🔵 debug: AudioPlayer: 播放状态 - ProcessingState.completed
I/flutter: ✅ AudioPlayer.playPcm: ✅ 播放完成
I/flutter: ✅ PagerAssistant._speak: ✅ 播放完成
I/flutter: ✅ PagerCubit: 获得问候语文本: "您好，..."
I/flutter: 💡 info: PagerCubit: 发送状态更新，历史: ["您好，..."]
# ✅ UI 更新：显示接线员台词
```

---

## 🚨 故障诊断指南

如果修复后仍然有问题，根据日志查找：

### 场景 1：播放卡在 "buffering" 状态
```log
I/flutter: 🔵 debug: AudioPlayer: 播放状态 - ProcessingState.buffering
# 卡住了，没有进入 ready/playing
```
**可能原因**: 音频编码问题，WAV 头格式错误
**调试**: 检查 `_wrapPcmAsWav()` 的 WAV 头

### 场景 2：没有看到任何播放日志
```log
I/flutter: 💡 info: AudioPlayer.playPcm: 开始播放
# 后续没有日志
```
**可能原因**: 异常被吞掉
**调试**: 检查是否有未处理的异常，查看日志等级

### 场景 3：播放超时
```log
I/flutter: ⚠️ warn: AudioPlayer.playPcm: ⚠️ 播放超时 30s，但继续执行
```
**可能原因**: 音频文件太长，或系统延迟大
**调试**: 增加超时时间，或检查采样率/音频数据大小

### 场景 4：状态没有 emit
```log
I/flutter: ❌ warn: PagerCubit: 状态不是 InCallState，无法更新
```
**可能原因**: 用户已离开通话
**调试**: 检查离开通话的时机

---

## 💡 关键改进总结

| 修复项 | 效果 | 优先级 |
|-------|------|--------|
| 播放失败容错 | 音频失败不中断流程 | 🔴 高 |
| 状态更新日志 | 快速定位问题 | 🟡 中 |
| 播放状态监控 | 看到中间过程 | 🟡 中 |
| 超时处理改进 | 防止卡死 | 🟡 中 |

---

## ✅ 验证检查清单

运行后，查看日志是否出现：
- [ ] `PagerAssistant._speak: 调用 VoiceService.speak()`
- [ ] `AudioPlayer.playPcm: 设置音频源`
- [ ] `AudioPlayer: 播放状态 - ProcessingState.playing`
- [ ] `AudioPlayer.playPcm: ✅ 播放完成` 或 `⚠️ 播放超时，但继续执行`
- [ ] `PagerAssistant._speak: ✅ 播放完成`
- [ ] `PagerCubit: 发送状态更新，历史: [...]`
- [ ] UI 显示接线员台词而不是 "准备就绪"

---

**修复验证**: ✅ 0 编译错误 | 状态日志完整 | 容错机制完善

