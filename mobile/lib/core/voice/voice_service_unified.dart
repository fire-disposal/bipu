import 'dart:async';
import 'tts_engine.dart';
import 'asr_engine.dart';
import 'audio_player.dart';
import '../utils/logger.dart';

/// 统一语音服务：TTS 顺序播放 + ASR 录音识别
///
/// 设计原则：
/// - TTS 顺序执行：每次 speak() 等待上次播放完成后再执行
/// - ASR 独立运行：通过 stream 回调推送结果
/// - 无优先级队列、无双重 AudioResourceManager 锁（已修复死锁）
/// - AudioPlayer.playPcm() 内部独自管理 AudioResourceManager，
///   VoiceService 层不再重复 acquire，消除历史死锁根源
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final TTSEngine _tts = TTSEngine();
  final ASREngine _asr = ASREngine();
  final AudioPlayer _player = AudioPlayer();

  bool _initialized = false;
  Completer<void>? _initCompleter;

  /// 顺序锁：当前 speak() 未完成时，新的 speak() 排队等待
  Completer<void> _speakDone = Completer<void>()..complete();

  /// ASR 录音活跃标记（由 startRecording/stopRecording 维护）
  bool _isAudioRecording = false;

  /// 当前是否有 TTS 正在播放（包括排队等待播放的）
  bool get isSpeaking => !_speakDone.isCompleted;

  /// 当前是否有 ASR 录音在进行
  bool get isRecording => _isAudioRecording;

  // ============ 初始化 ============

  /// 初始化语音服务（TTS + ASR + AudioPlayer）
  /// 
  /// 🔑 关键修复：
  /// - 添加超时保护，防止模型加载卡死
  /// - 支持重复调用（幂等性）
  /// - 失败后可重试
  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      logger.i('VoiceService: 初始化...');
      
      // 🔑 添加超时保护：模型加载最多 60 秒
      await Future.wait([
        _tts.init().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('TTS 模型加载超时'),
        ),
        _asr.init().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('ASR 模型加载超时'),
        ),
      ]).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('语音服务初始化总超时'),
      );
      
      await _player.init();
      _initialized = true;
      _initCompleter!.complete();
      logger.i('VoiceService: ✅ 初始化完成');
    } catch (e, st) {
      logger.e('VoiceService: 初始化失败', error: e, stackTrace: st);
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      _initialized = false; // 失败后允许重试
      rethrow;
    }
  }

  /// 检查服务是否已初始化并可安全使用
  bool get isReady => _initialized && _initCompleter != null && _initCompleter!.isCompleted;

  // ============ TTS API ============

  /// 播放 TTS 语音，顺序执行，await 返回表示播放完毕
  ///
  /// 多次并发调用时按顺序串行执行，不会互相覆盖。
  /// 
  /// 🔑 关键修复：
  /// - 使用前检查初始化状态
  /// - 添加超时保护
  Future<void> speak(String text, {int sid = 0, double speed = 1.0}) async {
    // 🔑 如果未初始化，先初始化
    if (!_initialized) {
      logger.i('VoiceService.speak: 检测到未初始化，自动初始化');
      try {
        await init().timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw TimeoutException('TTS 初始化超时'),
        );
      } catch (e) {
        logger.e('VoiceService.speak: 初始化失败', error: e);
        return; // 直接返回，不执行后续逻辑
      }
    }

    // ✅ 安全联锁：TTS 播放前必须确保 ASR 已停止，防止麦克风拾入 TTS 音频造成回路
    if (_isAudioRecording) {
      logger.w('VoiceService.speak: ⚠️ 检测到录音进行中，自动停止 ASR 后再播放 TTS');
      await stopRecording();
    }

    // 等待上一次播放完成（超时保护 15s，防止卡死）
    if (!_speakDone.isCompleted) {
      logger.i('VoiceService.speak: 等待上次播放完成...');
      try {
        await _speakDone.future.timeout(const Duration(seconds: 15));
      } on TimeoutException {
        logger.w('VoiceService.speak: 等待超时，强制继续');
        // 不再等待，直接推进
      }
    }

    _speakDone = Completer<void>();
    try {
      logger.i('VoiceService.speak: 生成 TTS "$text" sid=$sid spd=$speed');
      final pcmBytes = await _tts.generate(
        text: text,
        sid: sid,
        speed: speed,
        timeout: const Duration(seconds: 30),
      );
      if (pcmBytes == null) {
        logger.w('VoiceService.speak: TTS 生成失败 "$text"');
        return;
      }

      // ✅ 关键：此处直接调用 playPcm，不再 acquire AudioResourceManager
      //    AudioPlayer.playPcm() 内部已独自 acquire/release，无需在此重复
      await _player.playPcm(
        pcmBytes,
        sampleRate: 24000,
        channels: 1,
        playbackTimeout: const Duration(seconds: 30),
      );
      logger.i('VoiceService.speak: ✅ 播放完成 "$text"');
    } catch (e, st) {
      logger.e('VoiceService.speak: ❌ 错误', error: e, stackTrace: st);
    } finally {
      if (!_speakDone.isCompleted) _speakDone.complete();
    }
  }

  /// 立即中断当前 TTS 播放
  Future<void> stopSpeaking() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (!_speakDone.isCompleted) _speakDone.complete();
  }

  // ============ ASR API ============

  /// 开始录音
  ///
  /// ✅ 安全联锁：录音前自动停止正在播放的 TTS，防止接线员声音被误录入。
  Future<void> startRecording() async {
    if (!_initialized) {
      logger.i('VoiceService.startRecording: 检测到未初始化，自动初始化');
      try {
        await init().timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw TimeoutException('ASR 初始化超时'),
        );
      } catch (e) {
        logger.e('VoiceService.startRecording: 初始化失败', error: e);
        return;
      }
    }

    // 若 TTS 正在播放，先中断它再录音
    if (!_speakDone.isCompleted) {
      logger.w('VoiceService.startRecording: ⚠️ 检测到 TTS 播放中，自动停止后再开始 ASR');
      await stopSpeaking();
    }

    _isAudioRecording = true;
    await _asr.startRecording();
  }

  /// 停止录音并返回识别结果
  Future<String> stopRecording() async {
    _isAudioRecording = false;
    return _asr.stop();
  }

  /// 实时识别结果流
  Stream<String> get recognitionResults => _asr.onResult;

  /// 实时音量流（0.0 ~ 1.0）
  Stream<double> get volumeStream => _asr.onVolume;

  // ============ 内部工具 ============

  void dispose() {
    _tts.dispose();
    _asr.dispose();
    _player.dispose();
    _initialized = false;
    _isAudioRecording = false;
    if (!_speakDone.isCompleted) _speakDone.complete();
  }
}
