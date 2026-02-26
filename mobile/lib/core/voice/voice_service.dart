import 'dart:async';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:just_audio/just_audio.dart';
import 'tts_engine.dart';
import 'audio_resource_manager.dart';
import '../utils/logger.dart';

/// 极简 TTS 朗读服务：一行代码即可播放语音
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final TTSEngine _tts = TTSEngine();
  final AudioResourceManager _audioManager = AudioResourceManager();
  late AudioPlayer _audioPlayer;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.init();
    _audioPlayer = AudioPlayer();
    _initialized = true;
    logger.i('VoiceService initialized');
  }

  /// 极简调用：直接播放文本
  /// 示例：await VoiceService().speak('你好', sid: 0);
  Future<void> speak(String text, {int sid = 0, double speed = 1.0}) async {
    if (!_initialized) await init();

    try {
      // 获取音频资源锁
      final release = await _audioManager.acquire();

      try {
        // 生成语音
        final audio = await _tts.generate(text: text, sid: sid, speed: speed);

        if (audio == null) {
          logger.w('Failed to generate audio for text: $text');
          return;
        }

        // 播放语音
        await _playAudio(audio);
      } finally {
        release();
      }
    } catch (e, stackTrace) {
      logger.e('Error in speak: $e', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _playAudio(sherpa.GeneratedAudio audio) async {
    try {
      // 将 sherpa 生成的音频转换为 PCM 字节
      final pcmBytes = _convertAudioToBytes(audio);

      // 使用 just_audio 播放
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.dataFromBytes(pcmBytes)),
      );
      await _audioPlayer.play();

      // 等待播放完成
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      logger.e('Error playing audio: $e');
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
