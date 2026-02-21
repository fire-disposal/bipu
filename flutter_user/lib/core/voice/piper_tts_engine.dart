import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:piper_tts_plugin/piper_tts_plugin.dart';
import 'package:piper_tts_plugin/enums/piper_voice_pack.dart';
import '../utils/logger.dart';

/// 基于Piper TTS的新TTS引擎
/// 替代原有的sherpa_onnx VITS模型
class PiperTTSEngine {
  static final PiperTTSEngine _instance = PiperTTSEngine._internal();
  factory PiperTTSEngine() => _instance;
  PiperTTSEngine._internal();

  final PiperTtsPlugin _piper = PiperTtsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isDisposing = false;
  PiperVoicePack _currentVoice = PiperVoicePack.norman;
  File? _currentAudioFile;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在说话
  bool get isSpeaking => _isSpeaking;

  /// 当前使用的语音包
  PiperVoicePack get currentVoice => _currentVoice;

  /// 初始化Piper TTS引擎
  Future<void> init({PiperVoicePack? voice}) async {
    if (_isInitialized) return;
    if (_isDisposing) throw Exception('Piper TTS Engine is disposing');

    try {
      logger.i('初始化Piper TTS引擎...');

      // 设置语音包
      if (voice != null) {
        _currentVoice = voice;
      }

      // 加载语音模型
      await _piper.loadViaVoicePack(_currentVoice);

      _isInitialized = true;
      logger.i('Piper TTS引擎初始化成功，使用语音包: ${_currentVoice.name}');
    } catch (e, stackTrace) {
      logger.e('Piper TTS引擎初始化失败', error: e, stackTrace: stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// 生成并播放语音
  /// [text] 要合成的文本
  /// [voice] 可选的语音包（如果为null则使用当前语音包）
  /// [speed] 语速（1.0为正常速度）
  Future<void> speak(
    String text, {
    PiperVoicePack? voice,
    double speed = 1.0,
  }) async {
    if (text.isEmpty) {
      logger.w('文本为空，跳过TTS合成');
      return;
    }

    if (_isDisposing) throw Exception('Piper TTS Engine is disposing');

    // 如果指定了不同的语音包，重新初始化
    if (voice != null && voice != _currentVoice) {
      _currentVoice = voice;
      _isInitialized = false;
    }

    if (!_isInitialized) {
      await init(voice: voice);
    }

    try {
      _isSpeaking = true;

      logger.i(
        'Piper TTS合成: "${text.substring(0, text.length > 50 ? 50 : text.length)}${text.length > 50 ? '...' : ''}"',
      );

      // 获取临时目录
      final dir = await getTemporaryDirectory();
      final outputFile = File(
        '${dir.path}/piper_${DateTime.now().millisecondsSinceEpoch}.wav',
      );

      // 使用Piper合成语音到文件
      final audioFile = await _piper.synthesizeToFile(
        text: text.trim(),
        outputPath: outputFile.path,
      );

      _currentAudioFile = audioFile;

      // 播放生成的音频文件
      await _audioPlayer.setFilePath(audioFile.path);
      await _audioPlayer.play();

      // 等待播放完成
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );

      logger.i('Piper TTS播放完成');
    } catch (e, stackTrace) {
      logger.e('Piper TTS合成或播放失败', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isSpeaking = false;
      _cleanupAudioFile();
    }
  }

  /// 停止当前播放
  Future<void> stop() async {
    if (!_isSpeaking) return;

    try {
      await _audioPlayer.stop();
      logger.i('Piper TTS播放已停止');
    } catch (e, stackTrace) {
      logger.e('停止Piper TTS播放失败', error: e, stackTrace: stackTrace);
    } finally {
      _isSpeaking = false;
      _cleanupAudioFile();
    }
  }

  /// 设置语音包
  Future<void> setVoice(PiperVoicePack voice) async {
    if (_currentVoice == voice && _isInitialized) return;

    try {
      await stop();
      _currentVoice = voice;
      _isInitialized = false; // 需要重新初始化

      logger.i('Piper TTS语音包已设置为: ${voice.name}');
    } catch (e, stackTrace) {
      logger.e('设置Piper TTS语音包失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 获取所有可用的语音包
  List<PiperVoicePack> getAvailableVoices() {
    return PiperVoicePack.values;
  }

  /// 获取语音包信息
  String getVoiceInfo(PiperVoicePack voice) {
    return '${voice.name} (${voice.index})';
  }

  /// 清理音频文件
  void _cleanupAudioFile() {
    try {
      if (_currentAudioFile != null && _currentAudioFile!.existsSync()) {
        _currentAudioFile!.deleteSync();
        _currentAudioFile = null;
      }
    } catch (e) {
      logger.w('清理Piper TTS音频文件失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isDisposing) return;
    _isDisposing = true;

    logger.i('释放Piper TTS引擎资源...');

    try {
      await stop();
      await _audioPlayer.dispose();
      _cleanupAudioFile();

      _isInitialized = false;
      logger.i('Piper TTS引擎资源已释放');
    } catch (e, stackTrace) {
      logger.e('释放Piper TTS引擎资源失败', error: e, stackTrace: stackTrace);
    }
  }
}

/// Piper TTS错误类型
enum PiperTtsErrorType {
  initialization,
  synthesis,
  playback,
  fileSystem,
  disposal,
}

/// Piper TTS自定义错误
class PiperTtsError implements Exception {
  final String message;
  final PiperTtsErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  PiperTtsError(this.message, this.type, {this.originalError, this.stackTrace});

  @override
  String toString() => 'PiperTtsError($type): $message';
}
