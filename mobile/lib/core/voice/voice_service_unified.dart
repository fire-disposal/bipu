import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'tts_engine.dart';
import 'asr_engine.dart';
import 'audio_player.dart';
import 'audio_resource_manager.dart';
import '../utils/logger.dart';

/// 台词优先级
enum SpeechPriority {
  immediate, // 立即中断当前播放
  high, // 高优先级，等待当前完成后立即播放
  normal, // 普通优先级
  low, // 低优先级
}

/// 台词项内部表示
class _SpeechTask {
  final String text;
  final int voiceId;
  final double speed;
  final SpeechPriority priority;
  final String id;
  DateTime createdAt;
  int retryCount = 0;
  late Completer<bool> completer;

  _SpeechTask({
    required this.text,
    this.voiceId = 0,
    this.speed = 1.0,
    this.priority = SpeechPriority.normal,
    required this.id,
  }) : createdAt = DateTime.now() {
    completer = Completer<bool>();
  }
}

/// 统一语音服务：TTS播放、ASR识别、音频资源管理
///
/// 为业务层提供简洁API，隐藏所有底层复杂度
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final TTSEngine _tts = TTSEngine();
  final ASREngine _asr = ASREngine();
  final AudioPlayer _player = AudioPlayer();
  final AudioResourceManager _audioManager = AudioResourceManager();

  bool _initialized = false;
  Completer<void>? _initCompleter;
  static const bool _verboseLogging = kDebugMode;

  // 台词队列管理
  final Queue<_SpeechTask> _highPriorityQueue = Queue();
  final Queue<_SpeechTask> _normalPriorityQueue = Queue();
  final Queue<_SpeechTask> _lowPriorityQueue = Queue();

  _SpeechTask? _currentTask;
  bool _isProcessing = false;
  Timer? _processingTimer;

  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      if (_verboseLogging) logger.i('VoiceService: 初始化TTS引擎');
      await _tts.init();

      if (_verboseLogging) logger.i('VoiceService: 初始化ASR引擎');
      await _asr.init();

      if (_verboseLogging) logger.i('VoiceService: 初始化音频播放器');
      await _player.init();

      _initialized = true;
      _initCompleter!.complete();
      if (_verboseLogging) logger.i('VoiceService: 初始化成功');
    } catch (e, stackTrace) {
      logger.e('VoiceService: 初始化失败', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  // ============ TTS API ============

  /// 播放文本语音（简洁API）
  ///
  /// ```dart
  /// await VoiceService().speak('你好');
  /// await VoiceService().speak('谢谢', sid: 1, speed: 1.2);
  /// ```
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

  /// 进阶API：加入台词队列并等待完成
  Future<bool> enqueueSpeech({
    required String text,
    int voiceId = 0,
    double speed = 1.0,
    SpeechPriority priority = SpeechPriority.normal,
    String? id,
    Duration? timeout,
    int maxRetries = 1,
  }) async {
    if (!_initialized) {
      await init();
    }

    final taskId = id ?? _generateTaskId();
    final task = _SpeechTask(
      text: text,
      voiceId: voiceId,
      speed: speed,
      priority: priority,
      id: taskId,
    );
    task.retryCount = 0;

    if (_verboseLogging) {
      logger.i('VoiceService.enqueueSpeech: 加入队列 "$text" (优先级: $priority)');
    }

    // 加入对应优先级队列
    _enqueueTask(task);

    // 如果是立即优先级，中断当前播放
    if (priority == SpeechPriority.immediate && _currentTask != null) {
      if (_verboseLogging) {
        logger.i('VoiceService.enqueueSpeech: 中断当前播放');
      }
      await _player.stop();
    }

    // 启动处理
    _startProcessing();

    // 等待完成或超时
    try {
      if (timeout != null) {
        await task.completer.future.timeout(timeout);
      } else {
        await task.completer.future;
      }
      return true;
    } on TimeoutException {
      logger.w('VoiceService.enqueueSpeech: 台词 "$text" 播放超时');
      task.completer.completeError('timeout');
      return false;
    } catch (e) {
      logger.e('VoiceService.enqueueSpeech: 台词 "$text" 播放失败: $e');
      return false;
    }
  }

  // ============ ASR API ============

  /// 开始录音
  Future<void> startRecording() async {
    if (!_initialized) {
      await init();
    }
    await _asr.startRecording();
  }

  /// 停止录音并获取结果
  Future<String> stopRecording() async {
    return _asr.stop();
  }

  /// 监听识别结果实时流
  Stream<String> get recognitionResults => _asr.onResult;

  /// 监听音量
  Stream<double> get volumeStream => _asr.onVolume;

  // ============ 内部实现 ============

  void _enqueueTask(_SpeechTask task) {
    const int maxQueueLen = 200;
    switch (task.priority) {
      case SpeechPriority.immediate:
        // 保证队列长度上限，溢出时丢弃最老项
        if (_highPriorityQueue.length >= maxQueueLen)
          _highPriorityQueue.removeFirst();
        _highPriorityQueue.addFirst(task);
        break;
      case SpeechPriority.high:
        if (_highPriorityQueue.length >= maxQueueLen)
          _highPriorityQueue.removeFirst();
        _highPriorityQueue.add(task);
        break;
      case SpeechPriority.normal:
        if (_normalPriorityQueue.length >= maxQueueLen)
          _normalPriorityQueue.removeFirst();
        _normalPriorityQueue.add(task);
        break;
      case SpeechPriority.low:
        if (_lowPriorityQueue.length >= maxQueueLen)
          _lowPriorityQueue.removeFirst();
        _lowPriorityQueue.add(task);
        break;
    }
  }

  void _startProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;

    if (_verboseLogging) {
      logger.i('VoiceService: 启动处理循环');
    }

    // 使用单独的异步循环替代 Timer.periodic(Duration.zero)
    Future<void>(() async {
      try {
        while (_isProcessing) {
          // 如果没有任务则优雅退出循环（避免 Busy-loop），上层 enqueue 会再次启动
          final hasTask =
              _highPriorityQueue.isNotEmpty ||
              _normalPriorityQueue.isNotEmpty ||
              _lowPriorityQueue.isNotEmpty;
          if (!hasTask) {
            _isProcessing = false;
            if (_verboseLogging) logger.i('VoiceService: 队列已空，停止处理');
            break;
          }

          // 处理下一任务
          await _processNextTask();

          // 小睡以降低 CPU 占用，防止紧密重试
          await Future.delayed(const Duration(milliseconds: 40));
        }
      } catch (e, st) {
        logger.e('VoiceService: 处理循环意外退出', error: e, stackTrace: st);
        _isProcessing = false;
      }
    });
  }

  Future<void> _processNextTask() async {
    // 当前有任务正在播放，等待
    if (_currentTask != null) {
      return;
    }

    // 获取下一个任务
    _SpeechTask? nextTask;
    if (_highPriorityQueue.isNotEmpty) {
      nextTask = _highPriorityQueue.removeFirst();
    } else if (_normalPriorityQueue.isNotEmpty) {
      nextTask = _normalPriorityQueue.removeFirst();
    } else if (_lowPriorityQueue.isNotEmpty) {
      nextTask = _lowPriorityQueue.removeFirst();
    }

    if (nextTask == null) {
      // 队列空了，上层循环会发现并退出
      _isProcessing = false;
      if (_verboseLogging) {
        logger.i('VoiceService: 本次无任务，等待下一次启动');
      }
      return;
    }

    _currentTask = nextTask;

    try {
      if (_verboseLogging) {
        logger.i('VoiceService: 播放台词 "${nextTask.text}"');
      }

      // 生成TTS音频（30秒超时保护）
      final audio = await _tts.generate(
        text: nextTask.text,
        sid: nextTask.voiceId,
        speed: nextTask.speed,
        timeout: const Duration(seconds: 30),
      );

      if (audio == null) {
        // 失败时尝试有限重试
        nextTask.retryCount += 1;
        if (nextTask.retryCount <= 2) {
          if (_verboseLogging)
            logger.w(
              'VoiceService: TTS生成失败，重试 ${nextTask.retryCount} "${nextTask.text}"',
            );
          // 退回到普通队列尾部以便稍后重试
          if (_normalPriorityQueue.length >= 200)
            _normalPriorityQueue.removeFirst();
          _normalPriorityQueue.addLast(nextTask);
          _currentTask = null;
          return;
        }

        logger.e('VoiceService: TTS生成失败或超时 "${nextTask.text}"');
        nextTask.completer.completeError('TTS generation failed');
        _currentTask = null;
        return;
      }

      // 转换为PCM字节
      final pcmBytes = _convertAudioToBytes(audio);

      if (_verboseLogging) {
        logger.i('VoiceService: 已生成PCM ${pcmBytes.length} 字节，准备播放');
      }

      // 获取音频资源
      final release = await _audioManager.acquire();

      try {
        // 播放（30秒超时保护）
        // ✅ 即使播放失败也记录为完成，不中断队列处理
        try {
          await _player.playPcm(
            pcmBytes,
            sampleRate: 24000,
            channels: 1,
            playbackTimeout: const Duration(seconds: 30),
          );
          logger.i('VoiceService: 台词播放完成 "${nextTask.text}"');
        } catch (playbackError, playbackStackTrace) {
          // 播放失败时记录但继续
          logger.w(
            'VoiceService: 台词播放出错（但不中断） "${nextTask.text}"',
            error: playbackError,
            stackTrace: playbackStackTrace,
          );
        }
        nextTask.completer.complete(true);
      } finally {
        release();
        _currentTask = null;
      }
    } catch (e, stackTrace) {
      logger.e(
        'VoiceService: 台词播放异常 "${nextTask.text}"',
        error: e,
        stackTrace: stackTrace,
      );
      nextTask.completer.completeError(e);
      _currentTask = null;
    }
  }

  List<int> _convertAudioToBytes(sherpa.GeneratedAudio audio) {
    final samples = audio.samples;
    final bytes = <int>[];

    for (final sample in samples) {
      // 转换为16位PCM（小端序）
      final pcmSample = (sample * 32767).toInt().clamp(-32768, 32767);
      bytes.add(pcmSample & 0xFF);
      bytes.add((pcmSample >> 8) & 0xFF);
    }

    return bytes;
  }

  String _generateTaskId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_currentTask?.id.hashCode ?? 0}';
  }

  void dispose() {
    _processingTimer?.cancel();
    _processingTimer = null;
    // ✅ 修复：重置处理状态，避免重入时处理线程卡死
    _isProcessing = false;
    _currentTask = null;
    _highPriorityQueue.clear();
    _normalPriorityQueue.clear();
    _lowPriorityQueue.clear();
    _tts.dispose();
    _asr.dispose();
    _player.dispose();
    _initialized = false;
  }
}
