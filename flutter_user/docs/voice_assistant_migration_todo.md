# Voice Assistant 重构迁移计划与 TODO

日期：2026-02-15

目标：按“瘦身后三层模型”迁移语音助手架构，屏蔽底层 FFI 细节，统一业务状态机，降低 UI 与服务间耦合，提升性能与可测试性。

## 总体分解（高优先级首先完成）

- 里程碑 0：准备与兼容
  - 保留旧 `VoiceAssistantService`，新增 `AssistantController` 的适配器。确保回滚路径。

- 里程碑 1：模型与资源管理
  1. 实现 `ModelManager`（lib/core/services/model_manager.dart）
     - 单例：`ensureInitialized()`、`getModelPath(key)`、版本/校验逻辑
     - 抽出 `sherpa.initBindings()` 与 `_copyAssetToLocal()` 等逻辑
  2. 修改 `TtsService` 与 `SpeechRecognitionService`，在初始化前调用 `ModelManager.ensureInitialized()`。

- 里程碑 2：控制器与协调
  3. 实现 `AssistantController`（lib/features/voice_assistant/controller/assistant_controller.dart）
     - 状态：`idle`、`listening`、`thinking`、`speaking` 等
     - API：`start()`, `stop()`, `replay()`, `send()`；暴露 `ValueNotifier<AssistantState>` 或 `Stream<AssistantEvent>`
     - 内部依赖：`asrClient`, `ttsClient`, `imClient`, `audioManager`（保留 `AudioResourceManager`）
  4. 实现适配层：旧 `VoiceAssistantService` 委托/桥接到 `AssistantController` 以便平滑切换

- 里程碑 3：服务精简与性能
  5. 精简 `SpeechRecognitionService`：
     - 对外仅暴露：`Future<void> init()`, `Future<void> startRecording()`, `Future<void> stop()`, `Stream<String> onResult`, `Stream<double> onVolume`
     - 可选提供 `Stream<Float32List> rawSamples`（默认关闭，按需启用）
  6. 将同步阻塞 FFI 推理迁移到 isolate（TTS 与 ASR 的 heavy 调用），返回异步 `Future` 或输出临时文件路径

- 里程碑 4：前端更新与测试
  7. 更新 UI：`VoiceAssistantPanel`、`Pager` 页面与 `StatusIndicatorWidget` 订阅 `AssistantController`，Waveform 使用分贝驱动（`onVolume`）而非传递全部样本
  8. 完成单元测试与集成测试（状态机、错误恢复、资源互斥、性能/内存）
  9. 灰度发布：先内测，再 Canary，最后全面替换；保留旧服务作为回滚选项

---

## 详细 TODO（可直接拷贝到 `manage_todo_list`）

1. 实现 `ModelManager`（lib/core/services/model_manager.dart） — 2 天
2. 替换各 Service 的模型加载逻辑为 `ModelManager` 调用 — 0.5 天
3. 设计并实现 `AssistantController` 最小可用版本（含事件流） — 2 天
4. 实现旧 `VoiceAssistantService` 的适配器/桥接 — 0.5 天
5. 精简 `SpeechRecognitionService` 接口并增加 `onVolume` — 1 天
6. 把重的 FFI 调用迁移到 isolate（TTS 与 ASR）并验证线程安全 — 1–4 天（取决复杂度）
7. 更新 UI：Waveform、Panel、Pager 订阅新 Controller，并移除直接 raw samples 依赖 — 1 天
8. 编写并运行单元与集成测试 — 1–2 天
9. 灰度发布与回滚演练 — 0.5–1 天

> 估时合计（保守）：约 9–12 天（若 FFI 迁移复杂，时间上限可能到 15+ 天）

---

## 回滚与兼容策略

- 在 `AssistantController` 上线前，保持旧 `VoiceAssistantService` 可用；实现 `VoiceAssistantAdapter`，运行时通过配置切换使用哪个实现。
- 迁移步骤应小步快跑：先 `ModelManager`，再 `Controller` 最小版本，最后逐步剥离旧逻辑。

---

## 开始第一步（推荐）

我可以现在生成 `model_manager.dart` 的初始实现样板并提交为 PR 草稿，你想我立刻创建该文件吗？

---

## 附加：声纹压缩与振幅包络（Amplitude Envelope）优化

目标：为视觉效果传输极简声纹数据，仅传输每窗的振幅包络（1 字节/点），避免发送原始 PCM 样本。

要点：
- 窗口化：建议窗长 50ms（16kHz 下约 800 样本），每窗计算 RMS 或峰值。
- 归一化：将 RMS 映射到 0-255（1 字节）。
- 打包：产生 `List<int>` 或 Base64 字符串，塞入消息 JSON（例如 `waveform_b64`）。

实现建议：
1. 在 `SpeechRecognitionService` 内维护一个 `AmplitudeEnvelopeCollector`（按窗累积平方和并输出 uint8）。
2. 录音结束/发送时调用 `flushPartial()` 并通过 `toBase64()` 获取 Base64 字符串，放入消息负载。UI 解码后直接映射到高度绘制条状波形。
3. 默认关闭原始 `Float32List` 的长时间缓存，仅在需要发送波形或调试时启用。

示例（伪代码 / Dart）：

```dart
class AmplitudeEnvelopeCollector {
  final int sampleRate = 16000;
  final int windowMs = 50; // 每窗 50ms
  final int _windowSamples = ((16000 * 50) / 1000).ceil();
  int _accCount = 0;
  double _accSumSquares = 0.0;
  final List<int> _bytes = [];

  void addSamples(Float32List samples) {
    // 按需累加样本平方并在满窗时输出一个 0-255 的字节
  }

  void flushPartial({bool emitPartial = true}) { /* ... */ }
  List<int> toBytes() => List<int>.from(_bytes);
  String toBase64() => base64.encode(Uint8List.fromList(_bytes));
  void clear() { _bytes.clear(); _accCount = 0; _accSumSquares = 0.0; }
}
```

优点：
- 带宽低：10 秒语音（20 点/s）大约 200 字节，Base64 后 ~270 字符。
- 实现简单：无需解码 WAV/PCM，接收端仅做缩放绘制。
- 性能友好：RMS 计算为 O(N)，对单个窗的 800 点开销极小；必要时可移到 isolate。

最佳实践/陷阱：
- 保留 `rawSamples` 的按需开关以支持后续导出或调试。
- 固定发送点率（如 20Hz）以简化接收端绘图对齐。
- 不要传 FFT 频谱，除非确实需要频域展示。

将上述内容并入迁移计划后，可在后续任务中实现：
- 在 `SpeechRecognitionService` 中添加 `AmplitudeEnvelopeCollector`（对应 TODO id 5 和 7 的改动点）。

