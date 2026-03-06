# ASR 流式识别修复与业务流程优化总结

## 日期
2026 年 3 月 4 日

## 问题概述
ASR 识别并未如期望般将识别内容流式识别进文本缓冲区，用户无法在录音过程中看到实时识别结果。同时业务流程复杂，编辑态体验繁琐。

## 根因分析

### 1. ASR 引擎问题 (`lib/core/voice/asr_engine.dart`)

**问题代码**（第 345-362 行）：
```dart
if (_volumeCounter % 20 == 0 && !_isStopping && !_isDisposing) {
    if (_recognizer!.isReady(_stream!) && !_isStopping && !_isDisposing) {
        _recognizer!.decode(_stream!);
    }

    final isEndpoint = _recognizer!.isEndpoint(_stream!);
    if (isEndpoint && !_isStopping && !_isDisposing) {
        final text = _recognizer!.getResult(_stream!).text;
        if (text.isNotEmpty && !_resultController.isClosed) {
            _resultController.add(text);  // ← 只在 endpoint 时推送
        }
    }
}
```

**问题**：只在检测到 `endpoint`（语句结束）时才推送识别结果，**不是真正的流式识别**。

### 2. 业务流程复杂 (`lib/pages/pager/state/pager_cubit.dart`)

**原流程**：
```
拨号 → 问候语 TTS → 提示语 TTS → 
[录音 30s → 识别 → 确认提示 TTS → 确认录音 10s] → 
判断确认/否认 → (成功→发送 | 失败→重试)
```

**问题**：
- 用户需要说两次话（一次输入，一次确认），体验拖沓
- 状态切换频繁，代码复杂
- 现代 ASR 准确率已很高，二次确认多余

### 3. 编辑态体验繁琐 (`lib/pages/pager/pages/finalize_page.dart`)

**问题**：
- 需要点击"编辑"→输入→点击"确认"才能退出编辑
- `finishEditingMessage()` 无实际作用，用户容易困惑
- 编辑后无保存提示
- `TextField` 控制器泄漏（每次重建都创建新控制器）

## 修复方案

### 修复 1: ASR 流式识别

**文件**: `lib/core/voice/asr_engine.dart`

**修改**：
```dart
if (_volumeCounter % 20 == 0 && !_isStopping && !_isDisposing) {
    if (_recognizer!.isReady(_stream!) && !_isStopping && !_isDisposing) {
        _recognizer!.decode(_stream!);

        // ✅ 流式识别：每次 decode 后立即推送中间结果
        final result = _recognizer!.getResult(_stream!);
        if (result.text.isNotEmpty && !_resultController.isClosed) {
            _resultController.add(result.text);
        }
    }

    // Endpoint 检测：语句结束时也推送最终结果
    final isEndpoint = _recognizer!.isEndpoint(_stream!);
    if (isEndpoint && !_isStopping && !_isDisposing) {
        final text = _recognizer!.getResult(_stream!).text;
        if (text.isNotEmpty && !_resultController.isClosed) {
            _resultController.add(text);
        }
    }
}
```

**效果**：每次 `decode()` 后立即推送中间识别结果，实现真正的流式识别。

### 修复 2: 简化业务流程

**文件**: `lib/pages/pager/state/pager_cubit.dart`

**新流程**：
```
拨号 → 问候语 + 提示语 TTS → 
[录音识别（流式显示）+ 用户可手动结束] → 
自动发送（无需确认）
```

**关键变更**：
1. 移除确认轮（二次录音）
2. 保留 `finishAsrRecording()` 手动结束功能
3. 识别成功后直接进入 `FinalizeState`
4. 简化状态管理

**代码对比**：

**原代码**（约 240 行）：
```dart
// 第一次录音
final userText = await _voiceAssistant.recordAndRecognize(...);

// 播放确认提示
final confirmPrompt = '我听到了：$userText，请确认';
await _voiceAssistant.respond(confirmPrompt);

// 第二次录音（确认轮）
final confirmText = await _voiceAssistant.recordAndRecognize(...);

// 判断确认/否认
final isConfirmed = confirmText.contains('确认') || ...;
if (isConfirmed) {
    // 发送
} else {
    // 重试
}
```

**新代码**（约 140 行）：
```dart
// 一次录音，直接发送
final userText = await _voiceAssistant.recordAndRecognize(...);

if (userText.isEmpty) {
    // 重试逻辑
} else {
    // 直接进入发送状态
    emit(FinalizeState(...));
}
```

### 修复 3: UI 状态显示优化

**文件**: `lib/pages/pager/pages/in_call_page.dart`

**修改**：
```dart
// 简化状态文本显示
Text(
    state.isWaitingForUserInput
        ? "停止录音"
        : state.asrTranscript.isNotEmpty
        ? "完成"  // 识别完成，准备发送
        : "准备中",
)
```

**效果**：移除"聆听中"等冗余状态，显示更直观。

### 修复 4: 编辑态体验优化

**文件**: `lib/pages/pager/pages/finalize_page.dart` & `pager_cubit.dart`

**问题**：
- 编辑流程繁琐：需要"编辑"→"确认"才能退出
- `finishEditingMessage()` 方法无实际作用
- `TextField` 控制器泄漏

**优化**：

1. **自动保存**：输入时实时更新状态，无需点击"确认"
2. **移除"确认"按钮**：只保留"取消"按钮
3. **点击外部退出**：点击编辑区域外自动完成编辑
4. **修复控制器泄漏**：使用 `FocusNode` 和正确的生命周期管理

**代码修改**：

```dart
// ✅ 添加 FocusNode 管理
class _FinalizePageState extends State<FinalizePage> {
  final FocusNode _focusNode = FocusNode();
  TextEditingController? _editingController;

  @override
  void dispose() {
    _focusNode.dispose();
    _editingController?.dispose();
    super.dispose();
  }

  // ✅ 点击外部区域退出编辑
  GestureDetector(
    onTap: () {
      if (state.isEditing) {
        _focusNode.unfocus();
        widget.cubit.cancelEditingMessage();
      }
    },
    child: ...
  )
}
```

**移除 `finishEditingMessage()` 方法**：
```dart
// ❌ 删除
void finishEditingMessage() {
    emit(finalizeState.copyWith(isEditing: false));
}

// ✅ 编辑自动保存，无需确认
void updateEditingMessage(String content) {
    emit(finalizeState.copyWith(
        messageContent: content,
        textProcessingResult: textProcessingResult,
    ));
}
```

**UI 提示优化**：
```dart
Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
        Text('自动保存'),  // 保存提示
        Text('点击外部区域完成编辑'),  // 操作提示
    ],
)
```

## 优化效果

### 用户体验改进
| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 录音次数 | 2 次 | 1 次 |
| 等待时间 | ~50 秒 | ~30 秒 |
| 流式识别 | ❌ | ✅ |
| 手动结束 | ✅ | ✅ (保留) |
| 状态显示 | 复杂 | 简洁 |
| 编辑体验 | 繁琐 | 简洁 |
| 编辑保存 | 手动确认 | 自动保存 |
| 退出编辑 | 点击"确认" | 点击外部区域 |

### 代码质量改进
| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| `_startRecordingPhase` 行数 | ~240 行 | ~140 行 |
| 编辑相关方法 | 4 个 | 2 个 |
| 状态转换复杂度 | 高 | 低 |
| 重试逻辑 | 分散 | 集中 |
| 注释清晰度 | 一般 | 清晰 |
| 资源泄漏 | 存在 | 修复 |

## 保留功能

✅ **手动结束录音**：用户可随时点击"停止录音"按钮结束录音
```dart
void finishAsrRecording() {
    if (state is! InCallState) return;
    _voiceAssistant.signalStop();  // 发送停止信号
}
```

✅ **重试机制**：连续 3 次未识别到输入时自动结束
```dart
if (retryCount >= maxRetries) {
    // 播放提示音并返回拨号准备页
}
```

✅ **流式识别**：实时显示识别结果
```dart
onInterimResult: (interim) {
    emit(current.copyWith(asrTranscript: interim));
}
```

## 测试建议

1. **流式识别测试**：
   - 录音时观察文本缓冲区是否实时更新
   - 说长句子时查看识别结果是否逐步显示

2. **手动结束测试**：
   - 录音开始后点击"停止录音"按钮
   - 验证识别结果是否正确传递

3. **重试机制测试**：
   - 连续 3 次不说话或说无效内容
   - 验证是否正确结束并返回拨号页

4. **正常流程测试**：
   - 完整走一遍拨号→录音→发送流程
   - 验证各状态转换是否正确

## 修改文件清单

1. `lib/core/voice/asr_engine.dart` - ASR 流式识别修复
2. `lib/pages/pager/state/pager_cubit.dart` - 业务流程简化 + 编辑方法优化
3. `lib/pages/pager/pages/in_call_page.dart` - UI 状态显示优化
4. `lib/pages/pager/pages/finalize_page.dart` - 编辑态体验优化

## 后续建议

1. **静默检测**：可考虑添加 VAD（语音活动检测），用户说完自动停止录音
2. **识别优化**：可调整 ASR 的 `endpoint` 检测灵敏度
3. **错误处理**：增强网络异常、TTS 失败等场景的用户提示
