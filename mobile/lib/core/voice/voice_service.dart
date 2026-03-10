import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'tts_worker.dart';

/// 简化版语音服务 - 单例设计，仅供 Pager 页面使用
///
/// 职责：
/// - TTS: 播放文本（使用后台 Isolate 生成 PCM）
/// - ASR: 录音识别（使用系统 speech_to_text）
class VoiceService {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  // TTS
  final TtsWorker _tts = TtsWorker();

  // ASR
  final stt.SpeechToText _asr = stt.SpeechToText();
  final StreamController<String> _asrController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  bool _isListening = false;

  // 音频播放器
  final AudioPlayer _player = AudioPlayer();
  bool _isSpeaking = false;

  bool get isReady => _initialized;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  /// 初始化语音服务（应用启动时调用一次）
  Future<void> init() async {
    if (_initialized) return;

    debugPrint('[Voice] 初始化...');

    try {
      // 初始化 TTS Worker
      await _tts.init();

      // 初始化系统 ASR
      final available = await _asr.initialize(
        onError: (e) => debugPrint('[Voice ERROR] ASR 初始化错误：$e'),
        onStatus: (s) => debugPrint('[Voice] ASR 状态：$s'),
      );

      if (!available) {
        throw Exception('语音识别不可用');
      }

      // 配置音频会话
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      _initialized = true;
      debugPrint('[Voice] ✅ 初始化完成');
    } catch (e, st) {
      debugPrint('[Voice ERROR] 初始化失败：$e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// TTS: 播放文本并等待完成
  Future<void> speak(String text, {int sid = 0, double speed = 1.0}) async {
    if (!_initialized) await init();

    try {
      _isSpeaking = true;

      // 生成 PCM 数据
      final pcm = await _tts.generate(text, sid: sid, speed: speed);
      if (pcm == null) {
        debugPrint('[Voice WARN] TTS 生成失败');
        _isSpeaking = false;
        return;
      }

      // 播放 PCM
      await _playPcm(pcm);

      debugPrint('[Voice] ✅ 播放完成');
    } catch (e, st) {
      debugPrint('[Voice ERROR] 失败：$e');
      debugPrint('$st');
    } finally {
      _isSpeaking = false;
    }
  }

  /// 播放 PCM 数据（16-bit LE, 24kHz, 单声道）
  Future<void> _playPcm(List<int> pcm) async {
    final wav = _pcmToWav(pcm, 24000);

    await _player.setAudioSource(
      AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')),
    );

    await _player.play();

    // 等待播放完成，添加超时保护防止死锁
    try {
      await _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      debugPrint('[Voice WARN] 播放超时，强制停止');
      await _player.stop();
    }

    await _player.stop();
  }

  /// TTS: 立即停止
  Future<void> stopSpeaking() async {
    await _player.stop();
    _isSpeaking = false;
  }

  /// ASR: 开始录音，返回文本流
  Stream<String> startListening({Duration? timeout}) async* {
    if (!_initialized) await init();

    _isListening = true;
    final stopWatch = Stopwatch()..start();
    final effectiveTimeout = timeout ?? const Duration(seconds: 30);

    try {
      await _asr.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _asrController.add(result.recognizedWords);
          }
        },
        localeId: 'zh-CN',
        listenFor: effectiveTimeout,
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
      );

      // 等待结果或超时
      while (_isListening && stopWatch.elapsed < effectiveTimeout) {
        yield await _asrController.stream.first;
        break; // 收到一个结果后就返回
      }
    } catch (e, st) {
      debugPrint('[Voice ERROR] startListening 失败：$e');
      debugPrint('$st');
      _isListening = false;
    } finally {
      _isListening = false;
      stopWatch.stop();
    }
  }

  /// ASR: 停止录音
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _asr.stop();
    } catch (e) {
      debugPrint('[Voice WARN] stopListening: $e');
    } finally {
      _isListening = false;
    }
  }

  /// PCM 转 WAV（16-bit LE, 单声道）
  List<int> _pcmToWav(List<int> pcm, int sampleRate) {
    final dataSize = pcm.length;
    final fileSize = 36 + dataSize;

    return [
      // RIFF header
      ...[0x52, 0x49, 0x46, 0x46], // "RIFF"
      ..._int32LE(fileSize),
      ...[0x57, 0x41, 0x56, 0x45], // "WAVE"
      // fmt subchunk
      ...[0x66, 0x6d, 0x74, 0x20], // "fmt "
      ..._int32LE(16), // Subchunk1Size
      ..._int16LE(1), // AudioFormat (PCM)
      ..._int16LE(1), // NumChannels
      ..._int32LE(sampleRate),
      ..._int32LE(sampleRate * 2), // ByteRate
      ..._int16LE(2), // BlockAlign
      ..._int16LE(16), // BitsPerSample
      // data subchunk
      ...[0x64, 0x61, 0x74, 0x61], // "data"
      ..._int32LE(dataSize),
      ...pcm,
    ];
  }

  List<int> _int32LE(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  List<int> _int16LE(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  /// 清理资源
  Future<void> dispose() async {
    await stopSpeaking();
    await stopListening();
    await _player.dispose();
    _tts.dispose();
    _asrController.close();
    _initialized = false;
    debugPrint('[Voice] 已清理');
  }
}
