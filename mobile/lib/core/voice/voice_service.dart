import 'dart:async';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:just_audio/just_audio.dart';
import 'tts_engine.dart';
import 'audio_resource_manager.dart';
import '../utils/logger.dart';
import 'package:flutter/foundation.dart';

/// 极简 TTS 朗读服务：一行代码即可播放语音
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final TTSEngine _tts = TTSEngine();
  final AudioResourceManager _audioManager = AudioResourceManager();
  late AudioPlayer _audioPlayer;
  bool _initialized = false;
  static const bool _verboseLogging = kDebugMode;

  Future<void> init() async {
    if (_verboseLogging) logger.i('VoiceService: 开始初始化...');
    if (_initialized) {
      if (_verboseLogging) logger.i('VoiceService: 已经初始化，跳过');
      return;
    }

    try {
      if (_verboseLogging) logger.i('VoiceService: 初始化TTS引擎...');
      await _tts.init();
      if (_verboseLogging) logger.i('VoiceService: TTS引擎初始化完成');

      if (_verboseLogging) logger.i('VoiceService: 创建音频播放器...');
      _audioPlayer = AudioPlayer();

      _initialized = true;
      if (_verboseLogging) logger.i('VoiceService: 初始化成功!');
    } catch (e, stackTrace) {
      logger.e('VoiceService: 初始化失败!', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 极简调用：直接播放文本
  /// 示例：await VoiceService().speak('你好', sid: 0);
  Future<void> speak(String text, {int sid = 0, double speed = 1.0}) async {
    if (_verboseLogging)
      logger.i('VoiceService.speak: "$text", sid: $sid, speed: $speed');

    if (!_initialized) {
      if (_verboseLogging) logger.i('VoiceService: 初始化中...');
      await init();
    }

    try {
      if (_verboseLogging) logger.i('VoiceService: 获取音频资源锁');
      // 获取音频资源锁
      final release = await _audioManager.acquire();

      try {
        if (_verboseLogging) logger.i('VoiceService: 生成TTS音频');
        // 生成语音
        final audio = await _tts.generate(text: text, sid: sid, speed: speed);

        if (audio == null) {
          logger.e('VoiceService: TTS音频生成为空! 文本: "$text"');
          return;
        }

        if (_verboseLogging)
          logger.i('VoiceService: TTS音频生成完成，样本数: ${audio.samples.length}');

        // 播放语音
        if (_verboseLogging) logger.i('VoiceService: 播放音频');
        await _playAudio(audio);
      } finally {
        release();
        if (_verboseLogging) logger.i('VoiceService: 音频资源锁已释放');
      }
    } catch (e, stackTrace) {
      logger.e('VoiceService.speak: 播放失败', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _playAudio(sherpa.GeneratedAudio audio) async {
    if (_verboseLogging) logger.i('VoiceService._playAudio: 处理音频');

    try {
      if (_verboseLogging) logger.i('VoiceService._playAudio: 转换音频到PCM');
      // 将 sherpa 生成的音频转换为 PCM 字节
      final pcmBytes = _convertAudioToBytes(audio);
      if (_verboseLogging)
        logger.i('VoiceService._playAudio: PCM长度: ${pcmBytes.length}');

      if (_verboseLogging) logger.i('VoiceService._playAudio: 设置音频源');
      // 使用 just_audio 播放
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.dataFromBytes(pcmBytes)),
      );

      if (_verboseLogging) logger.i('VoiceService._playAudio: 开始播放');
      await _audioPlayer.play();

      // 等待播放完成
      if (_verboseLogging) logger.i('VoiceService._playAudio: 等待播放完成');
      await _audioPlayer.playerStateStream.firstWhere((state) {
        if (_verboseLogging)
          logger.v('VoiceService._playAudio: 播放器状态: ${state.processingState}');
        return state.processingState == ProcessingState.completed;
      });
    } catch (e, stackTrace) {
      logger.e(
        'VoiceService._playAudio: 播放失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<int> _convertAudioToBytes(sherpa.GeneratedAudio audio) {
    // 将 sherpa 的 GeneratedAudio 转换为 PCM 字节
    // 假设 audio.samples 是 Float32List
    final samples = audio.samples;
    final bytes = <int>[];

    for (final sample in samples) {
      // 转换为 16-bit PCM
      final pcmSample = (sample * 32767).toInt().clamp(-32768, 32767);
      bytes.add(pcmSample & 0xFF);
      bytes.add((pcmSample >> 8) & 0xFF);
    }

    return bytes;
  }

  /// 停止播放
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
    _tts.dispose();
  }
}
