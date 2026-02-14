# TTS / ASR 依赖树

日期：2026-02-15

说明：本文档列出项目中主要涉及 TTS（语音合成）与 ASR（语音识别）的页面、它们的直接依赖组件，以及这些组件的二级依赖（服务内部依赖）。便于快速定位相关模块与排查问题。

---

## 1. Pager 页面
路径：lib/features/pager/pages/pager_page.dart

- 直接依赖：
  - `SpeechRecognitionService`（ASR 服务）
  - `VoiceGuideService`（TTS 播放 / 音频管理）
  - `VoiceAssistantService`（语音助手：整合 TTS + ASR + 流程）
  - `ImService`（消息/联系人）
  - `WaveformController` / `WaveformWidget`（波形可视化，监听 ASR 音频流）
  - `VoiceAssistantPanel`（UI 控件，控制 `VoiceAssistantService`）
  - `StatusIndicatorWidget`（显示 TTS/ASR 状态）

- 二级依赖（服务/组件内部主要导入）：
  - `SpeechRecognitionService`：
    - `sherpa_onnx`（ONNX ASR 模型与推理）
    - `sound_stream`（麦克风音频流 / RecorderStream）
    - `permission_handler`（麦克风权限）
    - `path_provider`, `rootBundle`（拷贝模型资源）
    - `../core/utils/logger.dart`
  - `VoiceGuideService`：
    - `TtsService`（生成 TTS 音频）
    - `audioplayers`（播放 WAV/MP3）
    - `path_provider`, `sherpa_onnx`（写出生成的 WAV）
    - `audio_resource_manager.dart`（音频资源互斥获取/释放）
    - `VirtualOperator`（operator 配置）
  - `VoiceAssistantService`：
    - `TtsService`, `SpeechRecognitionService`, `VoiceGuideService`（组合使用）
    - `ImService`（发送消息）
    - `audio_resource_manager.dart`
    - operator 配置（templates / scripts）
    - `../core/utils/logger.dart`
  - `ImService`：
    - `dio`（API 访问）
    - `connectivity_plus`, `flutter_blue_plus`（网络/蓝牙）
    - `AuthService`, `BluetoothDeviceService`
  - `WaveformController` / `WaveformWidget`：
    - 监听 `SpeechRecognitionService.audioSamples`（Float32List）
    - 使用 `CustomPainter` 绘制波形
  - `VoiceAssistantPanel` / `StatusIndicatorWidget`：
    - 使用 `VoiceAssistantService` / `VoiceGuideService` / `SpeechRecognitionService` 的状态或事件流构建 UI

---

## 2. TTS Test 页面
路径：lib/features/tts_test/tts_test_page.dart

- 直接依赖：
  - `TtsService`（离线 TTS 生成）
  - `audioplayers`（播放生成 WAV）
  - `path_provider`（临时文件路径）
  - `sherpa_onnx`（写 WAV 帮助函数）

- 二级依赖：
  - `TtsService`：
    - `sherpa_onnx`（OfflineTts、模型配置）
    - `path_provider`, `rootBundle`（拷贝模型资源到本地）
    - `../core/utils/logger.dart`
  - 模型资产：`assets/models/tts/*`（vits 模型、tokens、lexicon 等）

---

## 3. ASR / Speech Test 页面
路径：lib/features/speech_test/speech_test_page.dart

- 直接依赖：
  - `SpeechRecognitionService`（识别服务）
  - `sound_stream.RecorderStream`（麦克风流）
  - `permission_handler`（麦克风权限）

- 二级依赖：
  - `SpeechRecognitionService`：
    - `sherpa_onnx`（OnlineRecognizer、模型文件）
    - `path_provider`, `rootBundle`（拷贝模型资源到本地）
    - `permission_handler`（权限处理）
    - `../core/utils/logger.dart`
  - 模型资产：`assets/models/asr/*`（encoder/decoder/joiner/tokens 等）

---

## 4. 全局 / 共享关键依赖
- 本地模型与推理：`sherpa_onnx`（用于 TTS 与 ASR）
- 模型文件位置：`assets/models/tts/` 与 `assets/models/asr/`
- 播放 / 录音 / 权限：
  - `audioplayers`, `sound_stream`, `permission_handler`, `path_provider`
- 应用内音频互斥：`lib/core/services/audio_resource_manager.dart`
- 日志：`lib/core/utils/logger.dart`
- 服务单例：`ImService`, `TtsService`, `SpeechRecognitionService`, `VoiceGuideService`, `VoiceAssistantService`
- 平台/网络库：`dio`, `connectivity_plus`, `flutter_blue_plus`
- 关键 UI 组件：`WaveformWidget`, `VoiceAssistantPanel`, `StatusIndicatorWidget`

---

## 5. 使用与注意事项
- 若要运行 TTS/ASR，需确保相应模型已被打包到 `assets/models/tts` / `assets/models/asr`，或在首次运行时可从资源拷贝到应用支持目录。
- TTS/ASR 初始化耗时且涉及本地 FFI（sherpa_onnx）。调试时建议在真实设备或可访问本地文件系统的平台运行（非 Web）。
- 音频资源争用通过 `AudioResourceManager` 协调（TTS 播放与 ASR 录音不可同时占用同一输出/输入资源）。

---

如果需要，我可以：
- 生成一份更详细的 Mermaid 依赖图；
- 将此文件加入到仓库 README 的索引；
- 或根据某个页面生成按文件的调用链（带文件链接）。
