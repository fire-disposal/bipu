import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../../core/voice/asr_engine.dart';
import '../services/waveform_processor.dart';
import '../speech/speech_queue_service.dart';
import '../../../../core/utils/logger.dart';

/// 语音交互错误类型
class VoiceInteractionError {
  final String message;
  final String code;
  final Object? cause;

  VoiceInteractionError({
    required this.message,
    this.code = 'VOICE_ERROR',
    this.cause,
  });

  @override
  String toString() => 'VoiceInteractionError(code: $code, message: $message)';
}

/// 语音交互配置
class VoiceInteractionConfig {
  /// 静默检测超时（用户停止说话后自动结束录音）
  final Duration silenceTimeout;

  /// 全局录音超时（最长录音时间）
  final Duration globalTimeout;

  /// 是否启用静默检测
  final bool enableSilenceDetection;

  /// TTS 播放前的等待时间（单位：毫秒）
  final int ttsPreparationDelayMs;

  /// 波形更新频率（单位：毫秒）
  final int waveformUpdateIntervalMs;

  const VoiceInteractionConfig({
    this.silenceTimeout = const Duration(seconds: 2),
    this.globalTimeout = const Duration(seconds: 30),
    this.enableSilenceDetection = true,
    this.ttsPreparationDelayMs = 200,
    this.waveformUpdateIntervalMs = 100,
  });
}

/// 语音交互协调器
///
/// 封装 ASR 和 TTS 的底层控制，提供高级 API 给 Cubit 使用
/// 支持：
/// 1. TTS 播放与 ASR 的互斥协调
/// 2. 静默检测自动结束录音
/// 3. 手动结束按钮并行生效
/// 4. 波形数据实时生成
/// 5. 错误统一处理
class VoiceInteractionCoordinator {
  final ASREngine _asrEngine;
  final SpeechQueueService _speechQueue;
  final WaveformProcessor _waveformProcessor;
  final VoiceInteractionConfig _config;

  // 内部状态
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isTtsPlaying = false;
  bool _isStopping = false;

  // 超时定时器
  Timer? _silenceTimer;
  Timer? _globalTimeoutTimer;
  Timer? _waveformUpdateTimer;

  // 最后转录时间戳（用于静默检测）
  DateTime? _lastTranscriptTime;

  // 事件流控制器
  final StreamController<String> _transcriptController =
      StreamController.broadcast();
  final StreamController<List<double>> _waveformController =
      StreamController.broadcast();
  final StreamController<String> _recordingEndedController =
      StreamController.broadcast();
  final StreamController<VoiceInteractionError> _errorController =
      StreamController.broadcast();

  // ASR 订阅
  StreamSubscription<String>? _asrResultSubscription;
  StreamSubscription<double>? _asrVolumeSubscription;
  StreamSubscription<Uint8List>? _asrAudioSubscription;

  /// 转录文本事件流
  Stream<String> get onTranscript => _transcriptController.stream;

  /// 波形数据事件流
  Stream<List<double>> get onWaveform => _waveformController.stream;

  /// 录音结束事件流（无论手动或自动结束）
  Stream<String> get onRecordingEnded => _recordingEndedController.stream;

  /// 错误事件流
  Stream<VoiceInteractionError> get onError => _errorController.stream;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 是否正在播放 TTS
  bool get isTtsPlaying => _isTtsPlaying;

  /// 创建语音交互协调器
  VoiceInteractionCoordinator({
    ASREngine? asrEngine,
    SpeechQueueService? speechQueue,
    WaveformProcessor? waveformProcessor,
    VoiceInteractionConfig? config,
  }) : _asrEngine = asrEngine ?? ASREngine(),
       _speechQueue = speechQueue ?? SpeechQueueService(),
       _waveformProcessor = waveformProcessor ?? WaveformProcessor(),
       _config = config ?? const VoiceInteractionConfig();

  /// 初始化协调器
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.i('VoiceInteractionCoordinator: 已经初始化');
      return;
    }

    try {
      logger.i('VoiceInteractionCoordinator: 开始初始化...');

      // 语音服务现在通过 SpeechQueueService 隐式初始化
      _isInitialized = true;
      logger.i('VoiceInteractionCoordinator: 初始化成功');
    } catch (e, stackTrace) {
      logger.e(
        'VoiceInteractionCoordinator: 初始化失败',
        error: e,
        stackTrace: stackTrace,
      );
      _emitError(
        VoiceInteractionError(
          message: '初始化失败: ${e.toString()}',
          code: 'INIT_FAILED',
          cause: e,
        ),
      );
      rethrow;
    }
  }

  /// 播放引导 TTS
  ///
  /// [text]: 要播放的文本
  /// [sid]: 语音ID（0-默认）
  /// [speed]: 语速（1.0-正常）
  ///
  /// 注意：播放 TTS 期间会暂停 ASR 录音
  Future<void> playGuidance(
    String text, {
    int sid = 0,
    double speed = 1.0,
  }) async {
    logger.i('VoiceInteractionCoordinator.playGuidance: 开始播放 "$text"');

    if (!_isInitialized) {
      await initialize();
    }

    try {
      _isTtsPlaying = true;

      // 如果有录音在进行，先暂停
      if (_isRecording) {
        logger.i('VoiceInteractionCoordinator: TTS播放前暂停录音');
        await _pauseRecording();
      }

      // 等待一小段时间确保UI更新
      await Future.delayed(
        Duration(milliseconds: _config.ttsPreparationDelayMs),
      );

      // 播放 TTS
      // 使用台词队列服务播放台词
      await _speechQueue.enqueueAndWait(
        text: text,
        priority: SpeechPriority.high,
        voiceId: sid,
        speed: speed,
        playbackTimeout: Duration(seconds: 10),
      );

      logger.i('VoiceInteractionCoordinator.playGuidance: TTS播放完成');
    } catch (e, stackTrace) {
      logger.e(
        'VoiceInteractionCoordinator.playGuidance: 播放失败',
        error: e,
        stackTrace: stackTrace,
      );
      _emitError(
        VoiceInteractionError(
          message: 'TTS播放失败: ${e.toString()}',
          code: 'TTS_FAILED',
          cause: e,
        ),
      );
    } finally {
      _isTtsPlaying = false;

      // 如果有录音需要恢复
      if (_isRecording) {
        logger.i('VoiceInteractionCoordinator: TTS播放完成后恢复录音');
        await _resumeRecording();
      }
    }
  }

  /// 开始录音
  ///
  /// 启动 ASR 转录，监听结果，自动处理静默检测和超时
  Future<void> startRecording() async {
    logger.i('VoiceInteractionCoordinator.startRecording: 开始录音');

    if (_isRecording) {
      logger.w('VoiceInteractionCoordinator: 已经在录音中');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 清空波形处理器
      _waveformProcessor.clear();

      // 初始化 ASR 引擎（如果尚未初始化）
      logger.i('VoiceInteractionCoordinator: 初始化ASR引擎...');
      await _asrEngine.init();

      // 开始录音
      logger.i('VoiceInteractionCoordinator: 启动ASR录音...');
      await _asrEngine.startRecording();

      _isRecording = true;
      _lastTranscriptTime = DateTime.now();

      logger.i('VoiceInteractionCoordinator: ASR录音已启动');

      // 设置订阅
      _setupSubscriptions();

      // 启动超时检测
      _startTimeoutDetection();

      // 启动波形更新定时器
      _startWaveformUpdates();
    } catch (e, stackTrace) {
      logger.e(
        'VoiceInteractionCoordinator.startRecording: 启动失败',
        error: e,
        stackTrace: stackTrace,
      );
      _emitError(
        VoiceInteractionError(
          message: '录音启动失败: ${e.toString()}',
          code: 'RECORD_START_FAILED',
          cause: e,
        ),
      );
      await _cleanupRecording();
      rethrow;
    }
  }

  /// 手动停止录音并返回最终转录文本
  ///
  /// 与静默检测并行生效，用户可随时点击结束按钮
  Future<String> stopRecording() async {
    logger.i('VoiceInteractionCoordinator.stopRecording: 手动停止录音');

    if (!_isRecording) {
      logger.w('VoiceInteractionCoordinator: 当前没有在录音');
      return '';
    }

    if (_isStopping) {
      logger.w('VoiceInteractionCoordinator: 已经在停止过程中');
      return '';
    }

    _isStopping = true;

    try {
      // 停止所有超时检测
      _stopTimeoutDetection();

      // 停止波形更新
      _stopWaveformUpdates();

      // 停止 ASR 录音并获取最终结果
      String finalTranscript = '';
      try {
        finalTranscript = await _asrEngine.stop();
        logger.i('VoiceInteractionCoordinator: 最终转录文本: "$finalTranscript"');
      } catch (e) {
        logger.e('VoiceInteractionCoordinator: 停止ASR失败: $e');
      }

      // 清理资源
      await _cleanupRecording();

      // 触发录音结束事件，传递最终转录文本
      _recordingEndedController.add(finalTranscript);

      return finalTranscript;
    } catch (e, stackTrace) {
      logger.e(
        'VoiceInteractionCoordinator.stopRecording: 停止失败',
        error: e,
        stackTrace: stackTrace,
      );
      _emitError(
        VoiceInteractionError(
          message: '录音停止失败: ${e.toString()}',
          code: 'RECORD_STOP_FAILED',
          cause: e,
        ),
      );
      return '';
    } finally {
      _isStopping = false;
    }
  }

  /// 播放成功提示 TTS
  Future<void> playSuccessTts(
    String text, {
    int sid = 0,
    double speed = 1.0,
  }) async {
    logger.i('VoiceInteractionCoordinator.playSuccessTts: 开始播放 "$text"');

    try {
      // 使用台词队列服务播放成功提示，使用普通优先级
      await _speechQueue.enqueueAndWait(
        text: text,
        priority: SpeechPriority.normal,
        voiceId: sid,
        speed: speed,
        playbackTimeout: Duration(seconds: 10),
      );
    } catch (e, stackTrace) {
      logger.e(
        'VoiceInteractionCoordinator.playSuccessTts: 播放失败',
        error: e,
        stackTrace: stackTrace,
      );
      _emitError(
        VoiceInteractionError(
          message: '成功提示TTS播放失败: ${e.toString()}',
          code: 'SUCCESS_TTS_FAILED',
          cause: e,
        ),
      );
    }
  }

  /// 取消所有语音交互
  ///
  /// 停止录音和TTS播放，清理所有资源
  Future<void> cancelAll() async {
    logger.i('VoiceInteractionCoordinator.cancelAll: 取消所有语音交互');

    // 停止录音
    if (_isRecording) {
      try {
        await _asrEngine.stop();
      } catch (e) {
        logger.e('VoiceInteractionCoordinator.cancelAll: 停止ASR失败: $e');
      }
    }

    // 停止所有台词播放
    try {
      await _speechQueue.stop();
    } catch (e) {
      logger.e('VoiceInteractionCoordinator.cancelAll: 停止台词队列失败: $e');
    }

    // 清理所有资源
    await _cleanupAll();

    logger.i('VoiceInteractionCoordinator.cancelAll: 所有语音交互已取消');
  }

  /// 设置订阅
  void _setupSubscriptions() {
    // 清理旧的订阅
    _asrResultSubscription?.cancel();
    _asrVolumeSubscription?.cancel();
    _asrAudioSubscription?.cancel();

    // 订阅 ASR 结果
    _asrResultSubscription = _asrEngine.onResult.listen((transcript) {
      logger.v('VoiceInteractionCoordinator: 收到转录: "$transcript"');

      // 更新最后转录时间（用于静默检测）
      _lastTranscriptTime = DateTime.now();

      // 转发转录结果
      _transcriptController.add(transcript);

      // 如果是有效内容，重置静默检测
      if (transcript.isNotEmpty && transcript != '检测到长时间静默，请说话...') {
        _resetSilenceTimer();

        // 如果有静默检测，检查是否应该自动结束
        if (_config.enableSilenceDetection) {
          _checkForSilence();
        }
      }
    });

    // 订阅音量数据
    _asrVolumeSubscription = _asrEngine.onVolume.listen((volume) {
      _waveformProcessor.addVolumeData(volume);
    });

    // 订阅音频数据
    _asrAudioSubscription = _asrEngine.onAudio.listen((audioData) {
      final pcmData = audioData.buffer.asUint8List().toList();
      _waveformProcessor.addPcmData(pcmData);
    });
  }

  /// 手动停止录音（静默检测触发时调用）
  Future<void> _stopRecordingOnSilence() async {
    if (!_isRecording) return;

    logger.i(
      'VoiceInteractionCoordinator._stopRecordingOnSilence: 静默检测触发，停止录音',
    );

    try {
      // 停止 ASR 录音并获取最终结果
      String finalTranscript = '';
      try {
        finalTranscript = await _asrEngine.stop();
        logger.i('VoiceInteractionCoordinator: 最终转录文本: "$finalTranscript"');
      } catch (e) {
        logger.e('VoiceInteractionCoordinator: 停止ASR失败: $e');
      }

      // 清理资源
      await _cleanupRecording();

      // 触发录音结束事件，传递最终转录文本
      _recordingEndedController.add(finalTranscript);
    } catch (e, stackTrace) {
      logger.e(
        'VoiceInteractionCoordinator._stopRecordingOnSilence: 停止失败',
        error: e,
        stackTrace: stackTrace,
      );
      _emitError(
        VoiceInteractionError(
          message: '静默检测停止失败: ${e.toString()}',
          code: 'SILENCE_STOP_FAILED',
          cause: e,
        ),
      );
    }
  }

  /// 启动超时检测
  void _startTimeoutDetection() {
    // 全局超时（最长录音时间）
    _globalTimeoutTimer = Timer(_config.globalTimeout, () {
      if (_isRecording) {
        logger.i('VoiceInteractionCoordinator: 全局超时，自动停止录音');
        stopRecording();
      }
    });

    // 静默检测（如果启用）
    if (_config.enableSilenceDetection) {
      _resetSilenceTimer();
    }
  }

  /// 重置静默检测定时器
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_config.silenceTimeout, () {
      if (_isRecording) {
        logger.i('VoiceInteractionCoordinator: 检测到静默，自动停止录音');
        _stopRecordingOnSilence();
      }
    });
  }

  /// 检查是否需要静默检测
  void _checkForSilence() {
    if (!_config.enableSilenceDetection || _lastTranscriptTime == null) {
      return;
    }

    final now = DateTime.now();
    final silenceDuration = now.difference(_lastTranscriptTime!);

    if (silenceDuration >= _config.silenceTimeout) {
      logger.i('VoiceInteractionCoordinator: 静默检测触发，自动停止录音');
      _stopRecordingOnSilence();
    }
  }

  /// 启动波形更新定时器
  void _startWaveformUpdates() {
    _waveformUpdateTimer?.cancel();

    _waveformUpdateTimer = Timer.periodic(
      Duration(milliseconds: _config.waveformUpdateIntervalMs),
      (_) {
        if (_isRecording) {
          final waveform = _waveformProcessor.getWaveformFromVolume();
          if (waveform.isNotEmpty) {
            _waveformController.add(waveform);
          }
        }
      },
    );
  }

  /// 暂停录音（用于 TTS 播放期间）
  Future<void> _pauseRecording() async {
    if (!_isRecording) return;

    logger.i('VoiceInteractionCoordinator._pauseRecording: 暂停录音');

    // 暂停超时检测
    _silenceTimer?.cancel();
    _globalTimeoutTimer?.cancel();

    // 暂停 ASR（如果支持暂停）
    // 注意：当前 ASR 引擎可能不支持暂停，这里先记录
    logger.i('VoiceInteractionCoordinator: 录音暂停（逻辑暂停）');
  }

  /// 恢复录音（TTS 播放完成后）
  Future<void> _resumeRecording() async {
    if (!_isRecording) return;

    logger.i('VoiceInteractionCoordinator._resumeRecording: 恢复录音');

    // 重新启动超时检测
    _startTimeoutDetection();

    logger.i('VoiceInteractionCoordinator: 录音恢复');
  }

  /// 停止超时检测
  void _stopTimeoutDetection() {
    _silenceTimer?.cancel();
    _silenceTimer = null;

    _globalTimeoutTimer?.cancel();
    _globalTimeoutTimer = null;
  }

  /// 停止波形更新
  void _stopWaveformUpdates() {
    _waveformUpdateTimer?.cancel();
    _waveformUpdateTimer = null;
  }

  /// 清理录音资源
  Future<void> _cleanupRecording() async {
    logger.i('VoiceInteractionCoordinator._cleanupRecording: 清理录音资源');

    _isRecording = false;
    _lastTranscriptTime = null;

    // 取消订阅
    await _asrResultSubscription?.cancel();
    await _asrVolumeSubscription?.cancel();
    await _asrAudioSubscription?.cancel();

    _asrResultSubscription = null;
    _asrVolumeSubscription = null;
    _asrAudioSubscription = null;

    // 停止所有定时器
    _stopTimeoutDetection();
    _stopWaveformUpdates();

    logger.i('VoiceInteractionCoordinator._cleanupRecording: 资源清理完成');
  }

  /// 清理所有资源
  Future<void> _cleanupAll() async {
    logger.i('VoiceInteractionCoordinator._cleanupAll: 清理所有资源');

    await _cleanupRecording();

    _isTtsPlaying = false;
    _isStopping = false;

    // 清空波形处理器
    _waveformProcessor.clear();

    logger.i('VoiceInteractionCoordinator._cleanupAll: 所有资源清理完成');
  }

  /// 发射错误事件
  void _emitError(VoiceInteractionError error) {
    logger.e('VoiceInteractionCoordinator: 发射错误 - $error');

    try {
      _errorController.add(error);
    } catch (e) {
      logger.e('VoiceInteractionCoordinator: 发射错误事件时失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    logger.i('VoiceInteractionCoordinator.dispose: 释放资源');

    await cancelAll();

    // 关闭事件流
    await _transcriptController.close();
    await _waveformController.close();
    await _recordingEndedController.close();
    await _errorController.close();

    // 释放台词队列服务
    await _speechQueue.dispose();

    logger.i('VoiceInteractionCoordinator.dispose: 资源释放完成');
  }

  /// 获取当前波形处理器实例（用于Cubit获取最终波形数据）
  WaveformProcessor get waveformProcessor => _waveformProcessor;
}
