import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/voice/voice_service_unified.dart';
import '../../core/utils/logger.dart';
import 'models/operator_model.dart';

/// 拨号业务层助手 - 接线员对话管理
///
/// 职责：
/// - 管理接线员特定的对话流程
/// - 应用接线员的语音配置（音色、语速）
/// - 处理命令识别和反馈
/// - 隐藏底层语音服务复杂度
///
/// 使用示例：
/// ```dart
/// final assistant = PagerAssistant(operator: operator);
/// await assistant.greet();  // 播放问候
/// final text = await assistant.recordAndRecognize();  // 录音识别
/// await assistant.respond('已确认');  // 反馈
/// ```
class PagerAssistant {
  final VoiceService _voiceService = VoiceService();
  final OperatorPersonality? _operator;

  bool _initialized = false;
  String? _lastRecognizedText;

  PagerAssistant({OperatorPersonality? operator}) : _operator = operator;

  /// 初始化助手
  Future<void> init() async {
    if (_initialized) return;
    await _voiceService.init();
    _initialized = true;
    if (kDebugMode) {
      logger.i('PagerAssistant: 初始化完成 (接线员: ${_operator?.name ?? "默认"})');
    }
  }

  // ============ 接线员特定的对话API ============

  /// 播放问候语
  Future<void> greet() async {
    final text = _operator?.dialogues.getGreeting() ?? '您好，有什么我可以帮助您的吗？';
    await _speak(text);
  }

  /// 播放等待提示
  Future<void> promptForMessage() async {
    final text = _operator?.dialogues.getRequestMessage() ?? '请说出您的诉求';
    await _speak(text);
  }

  /// 播放验证确认
  Future<void> playVerification() async {
    final text = _operator?.dialogues.getVerify() ?? '我来帮您确认一下';
    await _speak(text);
  }

  /// 播放目标ID确认
  Future<void> confirmTargetId(String targetId) async {
    final text =
        _operator?.dialogues.getConfirmId(targetId) ?? '确认目标 ID：$targetId';
    await _speak(text);
  }

  /// 播放用户未找到提示
  Future<void> playUserNotFound() async {
    final text = _operator?.dialogues.getUserNotFound() ?? '抱歉，找不到该用户';
    await _speak(text);
  }

  /// 播放成功消息
  Future<void> playSuccess(String message) async {
    final text = message.isEmpty
        ? (_operator?.dialogues.getSuccessMessage() ?? '完成')
        : message;
    await _speak(text);
  }

  /// 播放emoji警告（需要用户输入时）
  Future<void> playEmojiWarning() async {
    final text = _operator?.dialogues.getEmojiWarning() ?? '不支持特殊字符';
    await _speak(text);
  }

  /// 播放自定义文本
  Future<void> respond(String text, {double? speed}) async {
    await _speak(text, customSpeed: speed);
  }

  // ============ 识别API ============

  /// 录音并识别（带业务层回调）
  Future<String> recordAndRecognize({
    Duration maxDuration = const Duration(seconds: 30),
    Duration silenceTimeout = const Duration(seconds: 5),
    ValueChanged<double>? onVolumeChanged,
    ValueChanged<String>? onInterimResult,
  }) async {
    if (!_initialized) await init();

    try {
      logger.i('PagerAssistant: 开始录音识别');

      // 启动录音
      await _voiceService.startRecording();

      // 监听实时反馈
      StreamSubscription<double>? volumeSub;
      StreamSubscription<String>? resultSub;

      volumeSub = _voiceService.volumeStream.listen((volume) {
        onVolumeChanged?.call(volume);
      });

      resultSub = _voiceService.recognitionResults.listen((interim) {
        _lastRecognizedText = interim;
        onInterimResult?.call(interim);
      });

      // 等待停止（超时或手动）
      await Future.delayed(maxDuration);

      final result = await _voiceService.stopRecording();
      _lastRecognizedText = result;

      await volumeSub.cancel();
      await resultSub.cancel();

      logger.i('PagerAssistant: 识别完成 - "$result"');
      return result;
    } catch (e) {
      logger.e('PagerAssistant: 识别失败 - $e');
      rethrow;
    }
  }

  /// 手动停止录音
  Future<String> stopRecording() async {
    try {
      final result = await _voiceService.stopRecording();
      logger.i('PagerAssistant: 录音已停止 - "$result"');
      return result;
    } catch (e) {
      logger.e('PagerAssistant: 停止录音失败 - $e');
      rethrow;
    }
  }

  /// 获取最后识别的文本
  String? getLastRecognizedText() => _lastRecognizedText;

  // ============ 内部实现 ============

  Future<void> _speak(String text, {double? customSpeed}) async {
    if (!_initialized) await init();

    final speed = customSpeed ?? _operator?.ttsSpeed ?? 1.0;
    final voiceId = _operator?.ttsId ?? 0;

    if (kDebugMode) {
      logger.i(
        'PagerAssistant._speak: "$text" (接线员: ${_operator?.name}, 音色: $voiceId, 速度: $speed)',
      );
    }

    try {
      await _voiceService.speak(text, sid: voiceId, speed: speed);
    } catch (e) {
      logger.e('PagerAssistant._speak: 播放失败 - $e');
      rethrow;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    // 语音服务的清理由其自己管理（单例）
    _initialized = false;
    if (kDebugMode) logger.i('PagerAssistant: 已清理');
  }
}
