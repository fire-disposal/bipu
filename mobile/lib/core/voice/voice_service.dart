import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
// ✅ 预录制模式已启用，本地 TTS 引擎已注释关闭
// import 'tts_worker.dart';
// import 'voice_config.dart' show kUsePrerecordedVoiceOnly;

/// 简化版语音服务 - 单例设计，仅供 Pager 页面使用
///
/// 职责：
/// - TTS: 已注释（预录制模式启用，本地 TTS 引擎彻底关闭）
/// - ASR: 录音识别（使用系统 speech_to_text）
class VoiceService {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  // TTS Worker 已关闭（预录制模式）
  // final TtsWorker _tts = TtsWorker();

  // ASR
  final stt.SpeechToText _asr = stt.SpeechToText();
  final StreamController<String> _asrController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  bool _isListening = false;

  // 振幅包络采集
  final List<double> _amplitudeSamples = [];
  List<int>? _lastWaveform;

  // 音频播放器
  final AudioPlayer _player = AudioPlayer();
  bool _isSpeaking = false;

  bool get isReady => _initialized;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  /// 最近一次录音的振幅包络（1-255，最多128点）
  List<int>? get lastWaveform => _lastWaveform;

  /// 初始化语音服务（应用启动时调用一次）
  Future<void> init() async {
    if (_initialized) return;

    debugPrint('[Voice] 初始化...');

    try {
      // ✅ 预录制模式：本地 TTS 引擎已注释，节省资源
      // if (!kUsePrerecordedVoiceOnly) {
      //   await _tts.init();
      // }
      debugPrint('[Voice] 预录制模式：TTS 引擎已禁用，仅初始化 ASR');

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

  /// TTS: 已禁用（预录制模式）
  ///
  /// 台词播放由 [PrerecordedVoiceBackend] 直接播放 mp3，此方法为空桩保留接口兼容性。
  Future<void> speak(String text, {int sid = 0, double speed = 1.0}) async {
    // ✅ 预录制模式下 TTS 完全禁用，以下代码已注释
    debugPrint('[Voice] speak() 已禁用（预录制模式），忽略调用');
    // if (!_initialized) await init();
    // try {
    //   _isSpeaking = true;
    //   final pcm = await _tts.generate(text, sid: sid, speed: speed);
    //   if (pcm == null) { _isSpeaking = false; return; }
    //   await _playPcm(pcm);
    // } catch (e, st) {
    //   debugPrint('[Voice ERROR] 失败：$e');
    // } finally {
    //   _isSpeaking = false;
    // }
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
    _amplitudeSamples.clear();
    _lastWaveform = null;
    final stopWatch = Stopwatch()..start();
    final effectiveTimeout = timeout ?? const Duration(seconds: 30);

    try {
      await _asr.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _asrController.add(result.recognizedWords);
          }
        },
        onSoundLevelChange: (level) {
          // speech_to_text 返回 dB 值，Android 约 0~12，iOS 约 -160~0
          // 统一转为线性能量后入队
          _amplitudeSamples.add(level);
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
      // 录音结束后计算振幅包络
      _lastWaveform = _computeWaveform(_amplitudeSamples);
      debugPrint(
        '[Voice] waveform 采样点：${_amplitudeSamples.length} → ${_lastWaveform?.length ?? 0} 点',
      );
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

  /// 将原始振幅采样归一化为 1-255 的整数包络（低保真，最多 128 点）
  ///
  /// - 平均分桶降采样到 ≤128 点
  /// - Android soundLevel 为正 dB (0~12)；iOS 为负 dB (-160~0)；统一转线性后归一
  List<int> _computeWaveform(List<double> samples) {
    if (samples.isEmpty) return [];

    // 将 dB 转线性能量（负值平台补偿）
    final linear = samples.map((db) {
      // 如果都是负值（iOS），偏移到正值域
      final adjusted = db < 0 ? db + 160.0 : db;
      return adjusted.clamp(0.0, 200.0);
    }).toList();

    // 平均分桶降采样到最多 128 点
    const maxPoints = 128;
    final List<double> downsampled;
    if (linear.length <= maxPoints) {
      downsampled = List.of(linear);
    } else {
      downsampled = [];
      final bucketSize = linear.length / maxPoints;
      for (int i = 0; i < maxPoints; i++) {
        final start = (i * bucketSize).floor();
        final end = ((i + 1) * bucketSize).ceil().clamp(0, linear.length);
        final bucket = linear.sublist(start, end);
        downsampled.add(bucket.reduce((a, b) => a + b) / bucket.length);
      }
    }

    // 归一化到 1-255
    final maxVal = downsampled.reduce((a, b) => a > b ? a : b);
    final minVal = downsampled.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    if (range < 0.01) {
      // 全静音，返回低水位平坦值
      return List.filled(downsampled.length, 8);
    }

    return downsampled.map((v) {
      final norm = (v - minVal) / range; // 0.0~1.0
      return (norm * 254 + 1).round().clamp(1, 255);
    }).toList();
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
    // _tts.dispose(); // TTS Worker 已注释（预录制模式）
    _asrController.close();
    _initialized = false;
    debugPrint('[Voice] 已清理');
  }
}
