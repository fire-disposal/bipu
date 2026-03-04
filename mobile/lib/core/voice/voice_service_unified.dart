import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'tts_engine.dart';
import 'asr_engine.dart';
import 'audio_player.dart';
import '../utils/logger.dart';

/// 统一语音服务：TTS顺序播放 + ASR录音识别
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

  // ============ 初始化 ============

  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      logger.i('VoiceService: 初始化...');
      await _tts.init();
      await _asr.init();
      await _player.init();
      _initialized = true;
      _initCompleter!.complete();
      logger.i('VoiceService: ✅ 初始化完成');
    } catch (e, st) {
      logger.e('VoiceService: 初始化失败', error: e, stackTrace: st);
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  // ============ TTS API ============

  /// 播放 TTS 语音，顺序执行，await 返回表示播放完毕
  ///
  /// 多次并发调用时按顺序串行执行，不会互相覆盖。
  Future<void> speak(String text, {int sid = 0, double speed = 1.0}) async {
    if (!_initialized) await init();

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
      logger.i('VoiceService.speak: 生成TTS "$text" sid=$sid spd=$speed');
      final audio = await _tts.generate(
        text: text,
        sid: sid,
        speed: speed,
        timeout: const Duration(seconds: 30),
      );

      if (audio == null) {
        logger.w('VoiceService.speak: TTS生成失败 "$text"');
        return;
      }

      final pcmBytes = _convertAudioToBytes(audio);
      logger.i('VoiceService.speak: PCM ${pcmBytes.length} 字节，开始播放');

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
  Future<void> startRecording() async {
    if (!_initialized) await init();
    await _asr.startRecording();
  }

  /// 停止录音并返回识别结果
  Future<String> stopRecording() async {
    return _asr.stop();
  }

  /// 实时识别结果流
  Stream<String> get recognitionResults => _asr.onResult;

  /// 实时音量流（0.0 ~ 1.0）
  Stream<double> get volumeStream => _asr.onVolume;

  // ============ 内部工具 ============

  List<int> _convertAudioToBytes(sherpa.GeneratedAudio audio) {
    final samples = audio.samples;
    final bytes = <int>[];
    for (final sample in samples) {
      final pcmSample = (sample * 32767).toInt().clamp(-32768, 32767);
      bytes.add(pcmSample & 0xFF);
      bytes.add((pcmSample >> 8) & 0xFF);
    }
    return bytes;
  }

  void dispose() {
    _tts.dispose();
    _asr.dispose();
    _player.dispose();
    _initialized = false;
    if (!_speakDone.isCompleted) _speakDone.complete();
  }
}
