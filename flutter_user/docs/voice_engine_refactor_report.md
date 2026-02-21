# 语音引擎重构报告 (ASR/TTS)

本报告总结了语音助手模块在重构前存在的主要问题以及当前版本的改进措施。

## 1. 核心引擎层 (ASR/TTS Engine)

### 原有问题：
*   **代码截断与资源泄露**：旧版本代码存在严重的语法截断，导致 `sherpa_onnx` 的 `Stream` 和 `Recognizer` 无法正确释放，频繁导致内存溢出或引擎卡死。
*   **识别结果丢失**：在停止录音时，未对缓冲区内最后的音频帧进行强制解码，导致用户说的最后一句话往往无法识别。
*   **TTS 数据格式混乱**：TTS 生成的原始采样数据处理逻辑分散，缺乏统一的 PCM16 转换标准，导致在不同设备上播放失败。

### 改进措施：
*   **完整生命周期管理**：在 [`ASREngine`](flutter_user/lib/core/voice/asr_engine.dart) 和 [`TTSEngine`](flutter_user/lib/core/voice/tts_engine.dart) 中实现了严格的 `dispose` 逻辑和异常捕获。
*   **强制尾帧解码**：在 [`stop()`](flutter_user/lib/core/voice/asr_engine.dart:148) 方法中增加了对流的最后一次 `decode` 调用，确保识别完整性。
*   **标准化 TTS 封装**：引入了 [`TTSResult`](flutter_user/lib/core/voice/tts_engine.dart:245) 包装类，统一将 Float32 采样转换为标准的 PCM16 字节流。

## 2. 状态机与业务逻辑 (AssistantController)

### 原有问题：
*   **状态竞争 (Race Conditions)**：ASR 录音和 TTS 播放没有互斥机制，同时触发时会导致底层音频设备冲突。
*   **业务阶段模糊**：`AssistantPhase` 切换逻辑混乱，UI 无法准确感知当前是处于“等待 ID”还是“确认消息”阶段。
*   **缺乏环境适应性**：未处理系统音频中断（如电话接入）和耳机拔出等硬件事件。

### 改进措施：
*   **音频资源互斥锁**：通过 [`AudioResourceManager`](flutter_user/lib/core/voice/audio_resource_manager.dart) 实现了严格的 `acquire/release` 机制，确保同一时间只有一个语音任务占用硬件。
*   **精细化状态驱动**：重构了 [`_processText`](flutter_user/lib/features/assistant/assistant_controller.dart:195) 逻辑，通过清晰的关键词匹配和阶段跳转驱动复杂的传呼业务流。
*   **系统事件监听**：集成了 `audio_session`，实现了对音频中断和 `becomingNoisy` 事件的自动响应（自动停止录音/播放）。

## 3. 页面与交互层 (UI/UX)

### 原有问题：
*   **数据不同步**：语音识别出的文本和 ID 无法实时反映到输入框中，用户无法手动修正。
*   **测试工具失效**：`VoiceTestPage` 无法独立运行，依赖于未初始化的全局状态。

### 改进措施：
*   **双向绑定模拟**：在 [`PagerPage`](flutter_user/lib/features/pager/pages/pager_page.dart) 中增加了对 `AssistantController` 的监听，实现识别结果与 `TextEditingController` 的实时同步。
*   **健壮的测试页面**：重构后的 [`VoiceTestPage`](flutter_user/lib/features/voice_test/voice_test_page.dart) 具备完整的初始化检查和状态反馈，支持 ASR/TTS 的压力测试。

## 4. 健壮性与安全性

*   **权限预检**：在启动录音前增加了 [`Permission.microphone.request()`](flutter_user/lib/core/voice/asr_engine.dart:117) 强制检查。
*   **WAV 标准封装**：实现了 [`_buildWav`](flutter_user/lib/features/assistant/assistant_controller.dart:264) 辅助方法，确保生成的临时音频文件符合标准 RIFF/WAVE 格式，提升了播放兼容性。
