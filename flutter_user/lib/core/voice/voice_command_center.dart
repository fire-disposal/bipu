import 'dart:async';
import 'piper_tts_engine.dart';
import 'vosk_asr_engine.dart';
import '../utils/logger.dart';

/// 简化的语音命令中心
/// 协调TTS和ASR引擎
class VoiceCommandCenter {
  static final VoiceCommandCenter _instance = VoiceCommandCenter._internal();
  factory VoiceCommandCenter() => _instance;
  VoiceCommandCenter._internal();

  final PiperTTSEngine _tts = PiperTTSEngine();
  final VoskASREngine _asr = VoskASREngine();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isTalking = false;

  final StreamController<String> _resultController =
      StreamController.broadcast();
  final StreamController<double> _volumeController =
      StreamController.broadcast();

  /// 初始化语音命令中心
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      logger.i('初始化语音命令中心...');

      // 并行初始化ASR和TTS
      await Future.wait([_asr.initialize(), _tts.init()]);

      _isInitialized = true;
      logger.i('语音命令中心初始化成功');
    } catch (e, stackTrace) {
      logger.e('语音命令中心初始化失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 开始监听语音输入
  Future<void> startListening() async {
    if (!_isInitialized) {
      await init();
    }

    if (_isListening) {
      logger.w('已经在监听语音输入');
      return;
    }

    logger.i('开始监听语音输入...');

    try {
      // 如果正在说话，先停止
      if (_isTalking) {
        await _tts.stop();
        _isTalking = false;
      }

      await _asr.startRecording();
      _isListening = true;
      logger.i('语音监听已开始');
    } catch (e, stackTrace) {
      logger.e('开始语音监听失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 停止监听语音输入
  Future<String> stopListening() async {
    if (!_isListening) {
      logger.w('没有正在进行的语音监听');
      return '';
    }

    logger.i('停止监听语音输入...');

    try {
      await _asr.stopRecording();
      _isListening = false;
      logger.i('语音监听已停止');
      return '语音监听已停止';
    } catch (e, stackTrace) {
      logger.e('停止语音监听失败', error: e, stackTrace: stackTrace);
      _isListening = false;
      rethrow;
    }
  }

  /// 开始说话
  Future<void> startTalking(String text) async {
    if (!_isInitialized) {
      await init();
    }

    if (_isTalking) {
      logger.w('已经在说话');
      return;
    }

    logger.i('开始说话: $text');

    try {
      // 如果正在监听，先停止
      if (_isListening) {
        await stopListening();
      }

      await _tts.speak(text);
      _isTalking = true;
      logger.i('开始说话成功');
    } catch (e, stackTrace) {
      logger.e('开始说话失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 停止说话
  Future<void> stopTalking() async {
    if (!_isTalking) {
      logger.w('没有正在进行的说话');
      return;
    }

    logger.i('停止说话...');

    try {
      await _tts.stop();
      _isTalking = false;
      logger.i('说话已停止');
    } catch (e, stackTrace) {
      logger.e('停止说话失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 停止所有音频活动
  Future<void> stopAll() async {
    logger.i('停止所有音频活动...');

    try {
      if (_isListening) {
        await stopListening();
      }

      if (_isTalking) {
        await stopTalking();
      }

      logger.i('所有音频活动已停止');
    } catch (e, stackTrace) {
      logger.e('停止所有音频活动失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 获取识别结果流
  Stream<String> get onResult => _resultController.stream;

  /// 获取音量流
  Stream<double> get onVolume => _volumeController.stream;

  /// 是否正在监听
  bool get isListening => _isListening;

  /// 是否正在说话
  bool get isTalking => _isTalking;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 释放资源
  Future<void> dispose() async {
    logger.i('释放语音命令中心资源...');

    try {
      await stopAll();
      await _asr.dispose();
      await _tts.dispose();

      await _resultController.close();
      await _volumeController.close();

      _isInitialized = false;
      logger.i('语音命令中心资源已释放');
    } catch (e, stackTrace) {
      logger.e('释放语音命令中心资源失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 获取状态信息
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isListening': _isListening,
      'isTalking': _isTalking,
      'asrStatus': {},
      'ttsStatus': {},
    };
  }

  /// 重置语音命令中心
  Future<void> reset() async {
    logger.i('重置语音命令中心...');

    try {
      await dispose();
      _isInitialized = false;
      _isListening = false;
      _isTalking = false;
      logger.i('语音命令中心已重置');
    } catch (e, stackTrace) {
      logger.e('重置语音命令中心失败', error: e, stackTrace: stackTrace);
    }
  }
}
