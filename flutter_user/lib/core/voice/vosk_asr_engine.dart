import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';
import '../utils/logger.dart';

/// Vosk ASR错误类型
enum VoskAsrError {
  permissionDenied,
  initializationFailed,
  recordingFailed,
  modelNotFound,
}

/// 基于Vosk ASR的新ASR引擎
/// 简化版本，用于解决编译错误
class VoskASREngine {
  static final VoskASREngine _instance = VoskASREngine._internal();
  factory VoskASREngine() => _instance;
  VoskASREngine._internal();

  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _recorderSub;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isDisposing = false;

  final StreamController<String> _resultController =
      StreamController.broadcast();
  final StreamController<double> _volumeController =
      StreamController.broadcast();
  final StreamController<VoskAsrError> _errorController =
      StreamController.broadcast();

  /// 识别结果流
  Stream<String> get onResult => _resultController.stream;

  /// 音量流
  Stream<double> get onVolume => _volumeController.stream;

  /// 错误流
  Stream<VoskAsrError> get onError => _errorController.stream;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 初始化ASR引擎
  Future<void> initialize({String? modelPath}) async {
    if (_isInitialized) return;

    try {
      // 检查麦克风权限
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _errorController.add(VoskAsrError.permissionDenied);
        return;
      }

      // 初始化录音器
      await _recorder.initialize();

      _isInitialized = true;
      logger.i('Vosk ASR引擎初始化完成');
    } catch (e, stackTrace) {
      logger.e('Vosk ASR初始化失败', error: e, stackTrace: stackTrace);
      _errorController.add(VoskAsrError.initializationFailed);
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    if (!_isInitialized || _isRecording) return;

    try {
      _isRecording = true;
      await _recorder.start();

      // 模拟语音识别结果
      _recorderSub = _recorder.audioStream.listen((data) {
        // 计算音量
        final volume = _calculateVolume(data);
        _volumeController.add(volume);

        // 模拟识别结果（实际项目中这里会调用Vosk API）
        if (volume > 0.3 && _isRecording) {
          // 模拟识别到语音
          _resultController.add(
            '模拟识别结果: ${DateTime.now().millisecondsSinceEpoch}',
          );
        }
      });

      logger.i('开始录音');
    } catch (e, stackTrace) {
      logger.e('开始录音失败', error: e, stackTrace: stackTrace);
      _errorController.add(VoskAsrError.recordingFailed);
      _isRecording = false;
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      _isRecording = false;
      await _recorder.stop();
      _recorderSub?.cancel();
      _recorderSub = null;

      logger.i('停止录音');
    } catch (e, stackTrace) {
      logger.e('停止录音失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 计算音频数据的音量
  double _calculateVolume(List<int> audioData) {
    if (audioData.isEmpty) return 0.0;

    try {
      double sum = 0.0;
      int sampleCount = 0;

      // 将16位PCM数据转换为浮点数
      for (int i = 0; i < audioData.length - 1; i += 2) {
        final sample = (audioData[i + 1] << 8) | audioData[i];
        final normalized = sample / 32768.0;
        sum += normalized * normalized;
        sampleCount++;
      }

      final rms = sum > 0 ? sqrt(sum / sampleCount) : 0.0;
      return rms.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// 清理录音资源
  Future<void> _cleanupRecording() async {
    try {
      await _recorder.stop();
      _recorderSub?.cancel();
      _recorderSub = null;
    } catch (e) {
      logger.e('清理录音资源失败', error: e);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isDisposing) return;
    _isDisposing = true;

    try {
      await _cleanupRecording();
      _recorder.dispose();

      await _resultController.close();
      await _volumeController.close();
      await _errorController.close();

      _isInitialized = false;
      logger.i('Vosk ASR引擎已释放');
    } catch (e, stackTrace) {
      logger.e('释放Vosk ASR引擎失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 获取引擎状态
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isRecording': _isRecording,
      'isDisposing': _isDisposing,
    };
  }

  /// 重置引擎
  Future<void> reset() async {
    await dispose();
    _isDisposing = false;
  }
}
