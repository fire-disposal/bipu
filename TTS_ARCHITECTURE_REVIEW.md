# TTS 底层接口和调用链详细审阅报告

## 📋 文档信息

- **审阅日期**: 2026-03-04
- **审阅范围**: TTS、ASR、音频播放的完整调用链
- **重点**: 错误处理、超时管理、资源释放、优先级队列

---

## 🏗️ 整体架构图

```
业务层 (PagerAssistant)
  ↓
语音统一服务 (VoiceService - 单例)
  ├─→ TTS引擎 (TTSEngine - 单例)
  ├─→ ASR引擎 (ASREngine - 单例)
  └─→ 音频播放 (AudioPlayer - 单例)
       ↓
底层库
  ├─→ sherpa_onnx (离线语音处理)
  ├─→ just_audio (音频播放)
  └─→ sound_stream (录音)
```

---

## 1️⃣ TTS 完整调用链

### 1.1 业务层调用

**文件**: [pager_assistant.dart](../pager_assistant.dart)

```dart
// 步骤1: 业务层发起调用
Future<String> greet() async {
  final text = _operator?.dialogues.getGreeting() ?? '您好...';
  try {
    await _speak(text);  // ← 内部包装方法
  } catch (e) {
    logger.w('TTS 播放失败，但返回文本');  // ✅ 错误处理：不中断
  }
  return text;  // ✅ 返回文本供 UI 显示
}

// 步骤2: 内部包装方法
Future<void> _speak(String text, {double? customSpeed}) async {
  if (!_initialized) await init();

  final speed = customSpeed ?? _operator?.ttsSpeed ?? 1.0;
  final voiceId = _operator?.ttsId ?? 0;

  logger.i('播放: "$text" (音色: $voiceId, 速度: $speed)');

  try {
    // 调用底层服务
    await _voiceService.speak(text, sid: voiceId, speed: speed);
  } catch (e) {
    logger.w('TTS 播放失败 - $e');  // ✅ 降级：不 rethrow
  }
}
```

**特点**:
- ✅ 错误不向上传播（`catch` 而不 `rethrow`）
- ✅ 返回文本确保 UI 始终有显示内容
- ✅ 音色 (`sid`) 和语速 (`speed`) 应用

---

### 1.2 统一服务层

**文件**: [voice_service_unified.dart](../voice_service_unified.dart#L94-L115)

```dart
/// 入口API
Future<void> speak(
  String text, {
  int sid = 0,
  double speed = 1.0,
  SpeechPriority priority = SpeechPriority.normal,
  Duration? timeout,
}) async {
  final id = _generateTaskId();
  await enqueueSpeech(
    text: text,
    voiceId: sid,
    speed: speed,
    priority: priority,
    id: id,
    timeout: timeout,
  );
}

/// 进阶API：优先级队列管理
Future<bool> enqueueSpeech({
  required String text,
  int voiceId = 0,
  double speed = 1.0,
  SpeechPriority priority = SpeechPriority.normal,
  String? id,
  Duration? timeout,
  int maxRetries = 1,
}) async {
  // 1. 初始化检查
  if (!_initialized) {
    await init();
  }

  // 2. 创建任务
  final taskId = id ?? _generateTaskId();
  final task = _SpeechTask(
    text: text,
    voiceId: voiceId,
    speed: speed,
    priority: priority,
    id: taskId,
  );

  if (_verboseLogging) {
    logger.i('加入队列 "$text" (优先级: $priority)');
  }

  // 3. 加入优先级队列
  _enqueueTask(task);

  // 4. 优先级处理
  if (priority == SpeechPriority.immediate && _currentTask != null) {
    logger.i('中断当前播放');
    await _player.stop();  // ✅ 立即优先级会打断当前
  }

  // 5. 启动处理循环
  _startProcessing();

  // 6. 等待完成或超时
  try {
    if (timeout != null) {
      await task.completer.future.timeout(timeout);  // ✅ 超时控制
    } else {
      await task.completer.future;
    }
    return true;
  } on TimeoutException {
    logger.w('台词播放超时');
    task.completer.completeError('timeout');
    return false;
  } catch (e) {
    logger.e('台词播放失败: $e');
    return false;
  }
}
```

**队列管理**:
```dart
enum SpeechPriority {
  immediate,  // 立即中断当前
  high,       // 等待当前完成后立即播放
  normal,     // 普通优先级
  low,        // 低优先级
}

void _enqueueTask(_SpeechTask task) {
  switch (task.priority) {
    case SpeechPriority.immediate:
      _highPriorityQueue.addFirst(task);  // ✅ 插入队头
      break;
    case SpeechPriority.high:
      _highPriorityQueue.add(task);
      break;
    case SpeechPriority.normal:
      _normalPriorityQueue.add(task);
      break;
    case SpeechPriority.low:
      _lowPriorityQueue.add(task);
      break;
  }
}
```

**处理循环**:
```dart
void _startProcessing() {
  if (_isProcessing) return;  // ✅ 防止重复启动
  _isProcessing = true;

  _processingTimer = Timer.periodic(Duration.zero, (_) async {
    await _processNextTask();  // ✅ 循环处理任务
  });
}

Future<void> _processNextTask() async {
  // 若有任务正在播放，等待
  if (_currentTask != null) {
    return;  // ✅ 单线程处理
  }

  // 从优先级队列获取下一个任务
  _SpeechTask? nextTask;
  if (_highPriorityQueue.isNotEmpty) {
    nextTask = _highPriorityQueue.removeFirst();
  } else if (_normalPriorityQueue.isNotEmpty) {
    nextTask = _normalPriorityQueue.removeFirst();
  } else if (_lowPriorityQueue.isNotEmpty) {
    nextTask = _lowPriorityQueue.removeFirst();
  }

  if (nextTask == null) {
    // 队列空了，停止处理
    _processingTimer?.cancel();
    _processingTimer = null;
    _isProcessing = false;
    return;
  }

  _currentTask = nextTask;

  try {
    logger.i('播放台词 "${nextTask.text}"');

    // 调用 TTS 引擎生成音频
    final audio = await _tts.generate(
      text: nextTask.text,
      sid: nextTask.voiceId,
      speed: nextTask.speed,
    );

    if (audio == null) {
      logger.e('TTS生成失败 "${nextTask.text}"');
      nextTask.completer.completeError('TTS generation failed');
      _currentTask = null;
      return;
    }

    // 转换为 PCM 字节
    final pcmBytes = _convertAudioToBytes(audio);

    // 获取音频资源（防止竞争）
    final release = await _audioManager.acquire();

    try {
      // 播放 PCM 数据
      await _player.playPcm(pcmBytes, sampleRate: 24000, channels: 1);
      nextTask.completer.complete(true);  // ✅ 完成任务
      logger.i('台词播放完成 "${nextTask.text}"');
    } finally {
      release();
      _currentTask = null;
    }
  } catch (e, stackTrace) {
    logger.e('台词播放异常 "${nextTask.text}"', error: e, stackTrace: stackTrace);
    nextTask.completer.completeError(e);
    _currentTask = null;
  }
}
```

**关键特性**:
- ✅ **优先级队列**: immediate → high → normal → low
- ✅ **单线程处理**: 同一时刻只有一个任务播放
- ✅ **超时控制**: 可选的超时保护
- ✅ **异常恢复**: 某个任务失败不影响后续任务
- ⚠️ **资源竞争**: 使用 `_audioManager.acquire()` 防止并发

---

### 1.3 TTS 引擎层

**文件**: [tts_engine.dart](../tts_engine.dart)

```dart
class TTSEngine {
  static final TTSEngine _instance = TTSEngine._internal();
  
  sherpa.OfflineTts? _tts;  // ✅ 单例
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      sherpa.initBindings();  // ✅ 初始化 Sherpa 绑定

      // 确保模型文件已准备
      await ModelManager.instance.ensureInitialized(VoiceConfig.ttsModelFiles);

      final paths = _extractModelPaths(VoiceConfig.ttsModelFiles);
      final config = _buildTtsConfig(paths);

      _tts = sherpa.OfflineTts(config);  // ✅ 创建 TTS 实例
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e('TTSEngine 初始化失败', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<sherpa.GeneratedAudio?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
  }) async {
    if (!_isInitialized || _tts == null) {
      if (_verboseLogging) logger.i('TTS未初始化，调用init()');
      await init();
    }

    if (_tts == null) {
      logger.e('TTS初始化失败');
      return null;  // ✅ 返回 null 而不是 rethrow
    }

    try {
      logger.i('生成TTS: "$text", sid: $sid, speed: $speed');
      return _tts!.generate(text: text, sid: sid, speed: speed);
    } catch (e, stackTrace) {
      logger.e('TTS生成失败: $e\n$stackTrace');
      return null;  // ✅ 错误降级，不中断
    }
  }

  void dispose() {
    _tts?.free();  // ✅ 释放 Sherpa 资源
    _tts = null;
    _isInitialized = false;
  }
}
```

**模型配置**:
```dart
// 文件: voice_config.dart
class VoiceConfig {
  // TTS 模型配置
  static const String ttsModel = 'vits';
  static const String ttsLexicon = 'lexicon';
  static const String ttsTokens = 'tokens';
  static const String ttsPhone = 'phone';
  static const String ttsDate = 'date';
  static const String ttsNumber = 'number';
  static const String ttsHeteronym = 'heteronym';
  
  static const int ttsNumThreads = 4;  // ✅ CPU 线程数
  static const bool ttsDebug = kDebugMode;
  
  static const Map<String, String> ttsModelFiles = {
    'model': 'models/tts/model.onnx',
    'lexicon': 'models/tts/lexicon.txt',
    'tokens': 'models/tts/tokens.txt',
    // ... 其他模型文件
  };
}
```

---

### 1.4 音频转换和播放

**文件**: [voice_service_unified.dart#L314](../voice_service_unified.dart#L314-L328)

```dart
List<int> _convertAudioToBytes(sherpa.GeneratedAudio audio) {
  final samples = audio.samples;  // float32 样本
  final bytes = <int>[];

  for (final sample in samples) {
    // 转换为 16 位 PCM（小端序）
    final pcmSample = (sample * 32767).toInt().clamp(-32768, 32767);
    bytes.add(pcmSample & 0xFF);           // 低字节
    bytes.add((pcmSample >> 8) & 0xFF);    // 高字节
  }

  return bytes;
}
```

**音频播放** - [audio_player.dart](../audio_player.dart#L39-L90)

```dart
Future<void> playPcm(
  List<int> pcmBytes, {
  int sampleRate = 24000,
  int channels = 1,
) async {
  if (!_initialized) {
    await init();
  }

  logger.i('播放PCM: ${pcmBytes.length} 字节');

  // 获取音频资源锁
  final release = await _audioManager.acquire();

  try {
    // 将 PCM 包装为 WAV 格式（兼容 just_audio）
    final wavBytes = _wrapPcmAsWav(pcmBytes, sampleRate, channels);

    // 创建数据 URI
    await _player.setAudioSource(
      ja.AudioSource.uri(Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav')),
    );

    // 播放
    await _player.play();

    // 等待播放完成（30秒超时保护）
    final timeout = Duration(seconds: 30);
    final playerDone = _player.playerStateStream
        .firstWhere(
          (state) => state.processingState == ja.ProcessingState.completed,
        )
        .timeout(timeout);

    await playerDone;
    logger.i('播放完成');
  } catch (e, stackTrace) {
    logger.e('播放失败', error: e, stackTrace: stackTrace);
    rethrow;  // ⚠️ 此处 rethrow，上层需要处理
  } finally {
    release();  // ✅ 释放资源锁
  }
}

List<int> _wrapPcmAsWav(List<int> pcmData, int sampleRate, int channels) {
  final wav = <int>[];

  final dataSize = pcmData.length;
  final fileSize = 36 + dataSize;

  // RIFF 头
  wav.addAll([0x52, 0x49, 0x46, 0x46]); // "RIFF"
  wav.addAll(_intToLittleEndian(fileSize, 4));
  wav.addAll([0x57, 0x41, 0x56, 0x45]); // "WAVE"

  // fmt 子块（WAV 格式信息）
  wav.addAll([0x66, 0x6d, 0x74, 0x20]); // "fmt "
  wav.addAll(_intToLittleEndian(16, 4)); // 子块大小
  wav.addAll(_intToLittleEndian(1, 2));  // 音频格式（1=PCM）
  wav.addAll(_intToLittleEndian(channels, 2));
  wav.addAll(_intToLittleEndian(sampleRate, 4));
  wav.addAll(_intToLittleEndian(sampleRate * channels * 2, 4)); // 字节率
  wav.addAll(_intToLittleEndian(channels * 2, 2)); // 块对齐
  wav.addAll(_intToLittleEndian(16, 2)); // 比特深度

  // data 子块（音频数据）
  wav.addAll([0x64, 0x61, 0x74, 0x61]); // "data"
  wav.addAll(_intToLittleEndian(dataSize, 4));
  wav.addAll(pcmData);

  return wav;
}
```

**音频资源管理** - [audio_resource_manager.dart](../audio_resource_manager.dart)

```dart
class AudioResourceManager {
  bool _isAcquired = false;
  late Completer<void> _acquireLock;

  /// 获取音频资源（防止并发播放）
  Future<void Function()> acquire() async {
    if (_isAcquired) {
      await _acquireLock.future;  // ✅ 等待资源释放
    }

    _isAcquired = true;
    _acquireLock = Completer<void>();

    return () {
      _isAcquired = false;
      if (!_acquireLock.isCompleted) {
        _acquireLock.complete();  // ✅ 释放资源
      }
    };
  }
}
```

---

## 2️⃣ ASR 调用链

**文件**: [asr_engine.dart](../asr_engine.dart)

```dart
class ASREngine {
  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;

  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _recorderSub;

  final StreamController<String> _resultController = StreamController.broadcast();
  Stream<String> get onResult => _resultController.stream;

  final StreamController<double> _volumeController = StreamController.broadcast();
  Stream<double> get onVolume => _volumeController.stream;

  Future<void> startRecording() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // 创建在线识别流
      _stream = _recognizer!.createStream();

      // 启动录音
      await _recorder.initialize();
      await _recorder.start();

      // 监听录音数据
      _recorderSub = _recorder.onAudioFrame.listen((data) {
        // 将 PCM 数据送入识别器
        _stream!.acceptWaveform(
          sampleRate: 16000,  // ✅ ASR 采样率
          waveform: data,
        );

        // 处理识别结果
        if (_stream!.isReady) {
          final result = _recognizer!.getResult(_stream!);
          _resultController.add(result.text);
        }

        // 计算音量
        final rms = _calculateRms(data);
        _volumeController.add(rms);
      });
    } catch (e) {
      logger.e('启动录音失败: $e');
      rethrow;
    }
  }

  Future<String> stop() async {
    try {
      // 停止录音
      await _recorder.stop();
      await _recorderSub?.cancel();

      // 获取最终识别结果
      if (_stream != null) {
        final result = _recognizer!.getResult(_stream!);
        _resultController.close();
        _volumeController.close();
        return result.text;
      }

      return '';
    } catch (e) {
      logger.e('停止录音失败: $e');
      rethrow;
    }
  }

  double _calculateRms(List<int> pcmData) {
    double sum = 0;
    for (final sample in pcmData) {
      final normalized = sample / 32768.0;
      sum += normalized * normalized;
    }
    final rms = (sum / pcmData.length).clamp(0.0, 1.0);
    return rms;
  }
}
```

---

## 3️⃣ 错误处理分析

### 3.1 错误传播策略

| 层级 | 方法 | 错误处理 | 特点 |
|------|------|--------|------|
| **业务层** | `greet()` | catch 不 rethrow | ✅ 降级：返回文本 |
| **业务层** | `_speak()` | catch 不 rethrow | ✅ 防止中断 |
| **服务层** | `speak()` | try-catch | ✅ 任务失败不影响队列 |
| **TTS 引擎** | `generate()` | 返回 null | ✅ 不抛异常 |
| **音频播放** | `playPcm()` | try-catch rethrow | ⚠️ 上层必须处理 |

**问题分析**:
- ✅ 业务层错误处理完善（降级到文本）
- ✅ 队列不会因单个失败而停止
- ⚠️ 音频播放的 rethrow 被上层 catch 处理
- ✅ TTS 生成失败返回 null 而不是异常

---

### 3.2 资源泄漏风险

| 资源 | 管理方式 | 风险评估 |
|------|--------|---------|
| **Sherpa TTSEngine** | `_instance` + `dispose()` | ✅ 单例，有清理 |
| **AudioPlayer** | `finally` 中 `release()` | ✅ 有保证 |
| **ASR 录音流** | `_recorderSub?.cancel()` | ✅ 有清理 |
| **StreamController** | `close()` | ⚠️ 可能忘记关闭 |

---

## 4️⃣ 超时和延迟分析

### 4.1 超时配置

```dart
// 音频播放超时：30 秒
final timeout = Duration(seconds: 30);
final playerDone = _player.playerStateStream
    .firstWhere((state) => state.processingState == ja.ProcessingState.completed)
    .timeout(timeout);

// 可选的上层超时
await enqueueSpeech(text, timeout: Duration(seconds: 10));
```

**评估**:
- ✅ 音频播放有保护（30秒）
- ✅ 上层可自定义超时
- ⚠️ TTS 生成无超时（可能卡住）

---

### 4.2 延迟处理

在 PagerCubit 中:

```dart
// 问候语后延迟
await Future.delayed(const Duration(milliseconds: 600));

// 确认后延迟
await Future.delayed(const Duration(milliseconds: 800));

// 用户开始输入前延迟
await Future.delayed(const Duration(milliseconds: 500));
```

**特点**:
- ✅ 延迟设置合理（让用户看到文本）
- ✅ 不会导致 UI 卡顿
- ✅ 在异步任务中执行，不阻塞主线程

---

## 5️⃣ 优先级系统深度分析

### 5.1 优先级队列机制

```dart
enum SpeechPriority {
  immediate, // 优先级最高：立即中断当前，插入队头
  high,      // 优先级次高：等待当前完成，插入高优先级队头
  normal,    // 普通：放入常规队列
  low,       // 低优先级：后处理
}

// 使用场景
await _voiceAssistant.greet();  // normal（默认）
await _voiceAssistant.playSuccess('');  // normal
await _voiceAssistant.respond('我听到了...');  // normal
```

**改进建议**:
```dart
// ✅ 建议为不同场景设置优先级
Future<String> greet() async {
  final text = _operator?.dialogues.getGreeting() ?? '您好...';
  await _speak(text, priority: SpeechPriority.high);  // ✅ 高优先级
  return text;
}

Future<String> playSuccess(String message) async {
  final text = message.isEmpty
      ? (_operator?.dialogues.getSuccessMessage() ?? '完成')
      : message;
  await _speak(text, priority: SpeechPriority.immediate);  // ✅ 立即
  return text;
}
```

---

## 6️⃣ 当前实现的关键问题

### 问题 1: TTS 生成无超时保护

**现状**:
```dart
return _tts!.generate(text: text, sid: sid, speed: speed);  // ❌ 无超时
```

**风险**: TTS 生成可能无限期卡住

**建议方案**:
```dart
Future<sherpa.GeneratedAudio?> generate({
  required String text,
  int sid = 0,
  double speed = 1.0,
  Duration timeout = const Duration(seconds: 30),
}) async {
  try {
    return await _tts!.generate(text: text, sid: sid, speed: speed)
        .timeout(timeout);  // ✅ 添加超时
  } on TimeoutException {
    logger.e('TTS 生成超时: $text');
    return null;  // ✅ 降级处理
  }
}
```

### 问题 2: 优先级未充分利用

**现状**: 所有台词使用 `normal` 优先级

**建议**:
```dart
// 重要台词使用高优先级
await _speak(greetingText, priority: SpeechPriority.high);

// 错误提示使用立即优先级
await _speak('错误：...', priority: SpeechPriority.immediate);

// 非关键反馈使用低优先级
await _speak('系统消息', priority: SpeechPriority.low);
```

### 问题 3: 资源竞争需要更严格的管理

**当前**:
```dart
final release = await _audioManager.acquire();
try {
  await _player.playPcm(pcmBytes);
} finally {
  release();
}
```

**改进建议**: 在 VoiceService 中增加超时释放

```dart
final release = await _audioManager.acquire();
Timer? timeout;
try {
  timeout = Timer(Duration(minutes: 5), () {
    logger.w('音频资源泄漏检测：强制释放');
    release();
  });
  await _player.playPcm(pcmBytes);
} finally {
  timeout?.cancel();
  release();
}
```

---

## 7️⃣ 改进建议总结

| 序号 | 问题 | 优先级 | 建议 |
|------|------|--------|------|
| 1 | TTS 生成无超时 | 🔴 高 | 添加 Duration timeout 参数 |
| 2 | 优先级未利用 | 🟡 中 | 为不同台词设置合适优先级 |
| 3 | 资源泄漏风险 | 🟡 中 | 添加超时自动释放 |
| 4 | 错误日志冗长 | 🟢 低 | 统一日志格式 |
| 5 | ASR 无降级方案 | 🟡 中 | 添加备选文本 |

---

## 📊 性能指标

| 指标 | 当前值 | 建议值 | 说明 |
|------|-------|--------|------|
| 音频播放超时 | 30s | 30s | ✅ 合理 |
| 单个任务处理 | 无限制 | < 60s | ⚠️ 需限制 |
| 队列深度 | 无限制 | < 100 | ⚠️ 需限制 |
| 优先级队列 | 4级 | 4级 | ✅ 足够 |

---

## 📝 结论

✅ **整体架构**: 分层清晰，单例模式恰当  
✅ **错误处理**: 业务层降级方案完善  
✅ **优先级系统**: 设计完整但未充分利用  
⚠️ **超时保护**: TTS 生成缺乏保护  
⚠️ **资源管理**: 需要强制释放机制  

**推荐立即改进项**: 1, 2, 3

