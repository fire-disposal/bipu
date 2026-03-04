import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/voice/voice_service_unified.dart';
import '../../core/utils/logger.dart';
import 'models/operator_model.dart';

/// 拨号业务层语音助手
///
/// 封装 VoiceService，提供接线员对话所需的 TTS 和 ASR 接口。
///
/// 职责：
/// - 代理 VoiceService.speak()，附加接线员音色/语速
/// - 管理一次性录音生命周期（start → wait → stop → result）
/// - 提供 signalStop() 支持用户手动提前结束录音
class PagerAssistant {
  final VoiceService _voiceService = VoiceService();
  OperatorPersonality? _operator;

  bool _initialized = false;

  // 录音会话控制
  Completer<void>? _stopSignal; // 由 signalStop() / stopRecording() 触发
  bool _isRecording = false; // 防止并发 startRecording

  PagerAssistant({OperatorPersonality? operator}) : _operator = operator;

  /// 动态更新接线员（音色、语速）
  void updateOperator(OperatorPersonality operator) {
    _operator = operator;
    logger.i(
      'PagerAssistant: 接线员 -> ${operator.name} (ttsId=${operator.ttsId})',
    );
  }

  /// 初始化底层语音服务
  Future<void> init() async {
    if (_initialized) return;
    await _voiceService.init();
    _initialized = true;
    logger.i('PagerAssistant: 初始化完成 (接线员: ${_operator?.name ?? "默认"})');
  }

  // ============ TTS ============

  /// 播放任意文本，使用当前接线员音色/语速
  /// await 返回表示播放完毕（TTS 失败时静默跳过，不抛出异常）
  Future<void> respond(String text, {double? speed}) async {
    if (!_initialized) await init();
    final sid = _operator?.ttsId ?? 0;
    final spd = speed ?? _operator?.ttsSpeed ?? 1.0;
    if (kDebugMode) {
      logger.i('PagerAssistant.respond: "$text" sid=$sid spd=$spd');
    }
    try {
      await _voiceService.speak(text, sid: sid, speed: spd);
    } catch (e) {
      logger.w('PagerAssistant.respond: TTS失败（跳过） - $e');
    }
  }

  // ============ ASR ============

  /// 录音并识别，返回最终识别文本（识别失败返回空字符串）
  ///
  /// [maxDuration]       最大录音时长，超时自动停止
  /// [onVolumeChanged]   实时音量回调（0.0~1.0），用于波形动效
  /// [onInterimResult]   实时中间识别结果回调
  /// [onStarted]         录音真正开始时的回调（用于激活 UI 状态）
  Future<String> recordAndRecognize({
    Duration maxDuration = const Duration(seconds: 30),
    ValueChanged<double>? onVolumeChanged,
    ValueChanged<String>? onInterimResult,
    VoidCallback? onStarted,
  }) async {
    if (!_initialized) await init();

    // 防止并发录音
    if (_isRecording) {
      logger.w('PagerAssistant.recordAndRecognize: 已在录音中，忽略重复调用');
      return '';
    }

    _isRecording = true;
    _stopSignal = Completer<void>();
    String? lastInterim;
    StreamSubscription<double>? volumeSub;
    StreamSubscription<String>? resultSub;

    try {
      logger.i('PagerAssistant: 启动录音...');
      await _voiceService.startRecording();

      // 录音已真正启动，通知 UI
      try {
        onStarted?.call();
      } catch (_) {}
      logger.i('PagerAssistant: ✅ 录音已启动');

      // 订阅实时音量
      volumeSub = _voiceService.volumeStream.listen((vol) {
        try {
          onVolumeChanged?.call(vol);
        } catch (_) {}
      });

      // 订阅实时识别结果
      resultSub = _voiceService.recognitionResults.listen((text) {
        lastInterim = text;
        try {
          onInterimResult?.call(text);
        } catch (_) {}
      });

      // 等待：到达最大时长 OR 收到停止信号
      try {
        await _stopSignal!.future.timeout(maxDuration);
        logger.i('PagerAssistant: 收到停止信号，结束录音');
      } on TimeoutException {
        logger.i('PagerAssistant: 录音达到最大时长，自动停止');
      }

      // 停止录音，获取最终结果
      logger.i('PagerAssistant: 调用 stopRecording()...');
      final result = await _voiceService.stopRecording();

      // 优先使用 stopRecording 返回的结果，其次使用最后的 interimResult
      final finalText = result.isNotEmpty ? result : (lastInterim ?? '');
      logger.i('PagerAssistant: 识别结果 = "$finalText"');
      return finalText;
    } catch (e, st) {
      logger.e(
        'PagerAssistant.recordAndRecognize: 异常',
        error: e,
        stackTrace: st,
      );
      // 确保底层录音被停止
      try {
        await _voiceService.stopRecording();
      } catch (_) {}
      return '';
    } finally {
      await volumeSub?.cancel();
      await resultSub?.cancel();
      _stopSignal = null;
      _isRecording = false;
    }
  }

  // ============ 录音控制 ============

  /// 仅发送停止信号，让 recordAndRecognize() 自行调用 stopRecording()
  /// 用于用户手动点击"结束录音"按钮（finishAsrRecording）
  /// 这样可以保证 stopRecording 只被调用一次，避免结果丢失
  void signalStop() {
    if (_stopSignal != null && !_stopSignal!.isCompleted) {
      _stopSignal!.complete();
      logger.i('PagerAssistant: 停止信号已发送');
    }
  }

  /// 强制停止录音（用于 hangup / cancel / dispose）
  /// 同时发送信号并停止底层服务
  Future<void> stopRecording() async {
    // 先发信号，让 recordAndRecognize() 的 finally 块有机会清理
    signalStop();

    // 等待 recordAndRecognize 自行清理（最多 500ms）
    int waited = 0;
    while (_isRecording && waited < 25) {
      await Future.delayed(const Duration(milliseconds: 20));
      waited++;
    }

    // 若仍在录音（recordAndRecognize 未运行），直接停止底层服务
    if (_isRecording || waited >= 25) {
      try {
        await _voiceService.stopRecording();
      } catch (_) {}
      _isRecording = false;
    }
  }

  // ============ 生命周期 ============

  /// 清理资源
  Future<void> dispose() async {
    await stopRecording();
    try {
      await _voiceService.stopSpeaking();
    } catch (_) {}
    _initialized = false;
    if (kDebugMode) logger.i('PagerAssistant: 已清理');
  }
}
