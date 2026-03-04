import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'audio_resource_manager.dart';
import '../utils/logger.dart';

/// 直接播放PCM数据的音频播放器
class AudioPlayer {
  static final AudioPlayer _instance = AudioPlayer._internal();
  factory AudioPlayer() => _instance;
  AudioPlayer._internal();

  late ja.AudioPlayer _player;
  final AudioResourceManager _audioManager = AudioResourceManager();
  bool _initialized = false;
  Completer<void>? _initCompleter;
  static const bool _verboseLogging = kDebugMode;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      _player = ja.AudioPlayer();
      _initialized = true;
      _initCompleter!.complete();
      if (_verboseLogging) logger.i('AudioPlayer: 初始化成功');
    } catch (e, stackTrace) {
      logger.e('AudioPlayer: 初始化失败', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  /// 播放PCM数据（16位，单声道，24kHz）
  ///
  /// [pcmBytes] PCM原始数据
  /// [sampleRate] 采样率，默认24000
  /// [channels] 声道数，默认1（单声道）
  /// [playbackTimeout] 播放超时，默认30秒；最多5分钟强制释放资源
  Future<void> playPcm(
    List<int> pcmBytes, {
    int sampleRate = 24000,
    int channels = 1,
    Duration playbackTimeout = const Duration(seconds: 30),
  }) async {
    if (!_initialized) {
      await init();
    }

    if (_verboseLogging) {
      logger.i('AudioPlayer.playPcm: 开始播放 ${pcmBytes.length} 字节');
    }

    final release = await _audioManager.acquire();
    Timer? leakDetectionTimer;
    bool released = false;

    try {
      // 设置资源泄漏检测：5分钟未释放则强制释放
      leakDetectionTimer = Timer(const Duration(minutes: 5), () {
        logger.w('AudioPlayer: 检测到资源泄漏，强制释放音频资源');
        if (!released) {
          released = true;
          release();
        }
      });

      // 将PCM包装为WAV格式（就_audio的需求）
      final wavBytes = _wrapPcmAsWav(pcmBytes, sampleRate, channels);

      if (_verboseLogging) {
        logger.i('AudioPlayer.playPcm: WAV大小 ${wavBytes.length} 字节');
      }

      // 使用URI方式播放（兼容iOS等平台）
      logger.i('AudioPlayer.playPcm: 设置音频源');
      await _player.setAudioSource(
        ja.AudioSource.uri(Uri.dataFromBytes(wavBytes, mimeType: 'audio/wav')),
      );

      logger.i('AudioPlayer.playPcm: 开始播放');
      await _player.play();

      if (_verboseLogging) {
        logger.i('AudioPlayer.playPcm: play() 调用成功');
      }

      // ✅ 优化：等待播放完成或超时
      // 先等待一个短超时检查是否能收到完成信号
      try {
        logger.i(
          'AudioPlayer.playPcm: 等待播放完成，超时: ${playbackTimeout.inSeconds}s',
        );
        final playerDone = _player.playerStateStream
            .where((state) {
              if (_verboseLogging) {
                logger.d('AudioPlayer: 播放状态 - ${state.processingState}');
              }
              return state.processingState == ja.ProcessingState.completed;
            })
            .first
            .timeout(playbackTimeout);

        await playerDone;
        logger.i('AudioPlayer.playPcm: ✅ 播放完成');
      } on TimeoutException {
        logger.w(
          'AudioPlayer.playPcm: ⚠️ 播放超时 ${playbackTimeout.inSeconds}s，但继续执行',
        );
        // 不 rethrow，允许继续（可能音频太短或系统问题）
        try {
          await _player.stop();
        } catch (e) {
          logger.w('AudioPlayer.playPcm: stop() 失败 - $e');
        }
      }
    } catch (e, stackTrace) {
      logger.e('AudioPlayer.playPcm: ❌ 播放失败', error: e, stackTrace: stackTrace);
      // 不 rethrow，让音频播放失败不影响后续流程
    } finally {
      leakDetectionTimer?.cancel();
      if (!released) {
        released = true;
        release();
      }
    }
  }

  /// 将PCM数据包装为WAV格式
  List<int> _wrapPcmAsWav(List<int> pcmData, int sampleRate, int channels) {
    final wav = <int>[];

    // 计算文件大小
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    // RIFF头
    wav.addAll([0x52, 0x49, 0x46, 0x46]); // "RIFF"
    wav.addAll(_intToLittleEndian(fileSize, 4)); // 文件大小 - 8
    wav.addAll([0x57, 0x41, 0x56, 0x45]); // "WAVE"

    // fmt子块
    wav.addAll([0x66, 0x6d, 0x74, 0x20]); // "fmt "
    wav.addAll(_intToLittleEndian(16, 4)); // Subchunk1Size
    wav.addAll(_intToLittleEndian(1, 2)); // AudioFormat (1=PCM)
    wav.addAll(_intToLittleEndian(channels, 2)); // NumChannels
    wav.addAll(_intToLittleEndian(sampleRate, 4)); // SampleRate
    wav.addAll(_intToLittleEndian(sampleRate * channels * 2, 4)); // ByteRate
    wav.addAll(_intToLittleEndian(channels * 2, 2)); // BlockAlign
    wav.addAll(_intToLittleEndian(16, 2)); // BitsPerSample

    // data子块
    wav.addAll([0x64, 0x61, 0x74, 0x61]); // "data"
    wav.addAll(_intToLittleEndian(dataSize, 4)); // Subchunk2Size
    wav.addAll(pcmData);

    return wav;
  }

  List<int> _intToLittleEndian(int value, int bytes) {
    final result = <int>[];
    for (int i = 0; i < bytes; i++) {
      result.add((value >> (i * 8)) & 0xFF);
    }
    return result;
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
    _initialized = false;
  }
}
