import '../../../core/voice/voice_service.dart';
import '../../../core/utils/logger.dart';
import '../widgets/speech_bubble_widget.dart';

/// 增强版语音服务
/// 支持TTS主播放，失败时自动降级到气泡显示
/// 确保即使TTS异常，虚拟接线员也能正常交互
class VoiceServiceEnhanced {
  final VoiceService _voiceService;
  final SpeechBubbleManager _bubbleManager = SpeechBubbleManager();

  /// TTS是否可用
  bool _isTtsAvailable = true;

  /// TTS失败计数
  int _ttsFailureCount = 0;

  /// 最大失败次数后永久切换到气泡模式
  static const int _maxTtsFailures = 3;

  /// 当前是否正在播放语音
  bool _isPlaying = false;

  VoiceServiceEnhanced({VoiceService? voiceService})
    : _voiceService = voiceService ?? VoiceService();

  /// 初始化服务
  Future<void> init() async {
    try {
      await _voiceService.init();
      _isTtsAvailable = true;
      _ttsFailureCount = 0;
      logger.i('VoiceServiceEnhanced initialized');
    } catch (e) {
      logger.w('Failed to initialize TTS, using bubble fallback: $e');
      _isTtsAvailable = false;
    }
  }

  /// 说话 - 支持TTS失败时自动降级到气泡
  /// 返回true表示使用了语音，false表示使用了气泡
  Future<bool> speak(
    String text, {
    int sid = 0,
    double speed = 1.0,
    bool forceBubble = false,
  }) async {
    if (text.isEmpty) {
      return false;
    }

    _isPlaying = true;

    try {
      // 如果强制使用气泡或TTS已禁用
      if (forceBubble || !_isTtsAvailable) {
        _showSpeechBubble(text, hasAudio: false);
        return false;
      }

      // 尝试使用TTS
      try {
        await _voiceService.speak(text, sid: sid, speed: speed);
        _ttsFailureCount = 0; // 重置失败计数
        _showSpeechBubble(text, hasAudio: true);
        return true;
      } catch (ttsError) {
        logger.w('TTS failed, showing bubble instead: $ttsError');
        _ttsFailureCount++;

        // 如果失败次数过多，永久禁用TTS
        if (_ttsFailureCount >= _maxTtsFailures) {
          _isTtsAvailable = false;
          logger.i('TTS disabled after $_ttsFailureCount failures');
        }

        // 显示气泡（没有音频指示）
        _showSpeechBubble(text, hasAudio: false);
        return false;
      }
    } finally {
      _isPlaying = false;
    }
  }

  /// 说话 - 静态快捷方式（用于简单场景）
  static Future<bool> quickSpeak(
    String text, {
    int sid = 0,
    double speed = 1.0,
  }) async {
    final service = VoiceServiceEnhanced();
    await service.init();
    return service.speak(text, sid: sid, speed: speed);
  }

  /// 说话系列 - 顺序播放多句话
  Future<void> speakSequence(
    List<String> texts, {
    int sid = 0,
    double speed = 1.0,
    Duration delayBetween = const Duration(milliseconds: 500),
  }) async {
    for (int i = 0; i < texts.length; i++) {
      await speak(texts[i], sid: sid, speed: speed);

      if (i < texts.length - 1) {
        await Future.delayed(delayBetween);
      }
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _voiceService.stop();
      _isPlaying = false;
    } catch (e) {
      logger.e('Failed to stop voice: $e');
    }
  }

  /// 显示语音气泡
  void _showSpeechBubble(String text, {bool hasAudio = false}) {
    _bubbleManager.showSpeech(
      text: text,
      isOperator: true,
      hasAudio: hasAudio,
      displayDuration: _calculateDisplayDuration(text),
      style: _getStyleForText(text),
    );
  }

  /// 计算显示时长（基于文本长度）
  Duration _calculateDisplayDuration(String text) {
    // 基础时长 + 按字数增加的时长
    final baseSeconds = 2;
    final additionalSeconds = (text.length / 10).ceil();
    final totalSeconds = (baseSeconds + additionalSeconds).clamp(2, 10);
    return Duration(seconds: totalSeconds);
  }

  /// 获取样式（检测文本类型）
  SpeechBubbleStyle _getStyleForText(String text) {
    if (text.contains('抱歉') ||
        text.contains('无法') ||
        text.contains('不支持') ||
        text.contains('错误')) {
      return SpeechBubbleStyle.warning;
    }
    if (text.contains('成功') ||
        text.contains('已') ||
        text.contains('完成') ||
        text.contains('已发送')) {
      return SpeechBubbleStyle.success;
    }
    return SpeechBubbleStyle.primary;
  }

  /// 获取当前TTS状态
  bool get isTtsAvailable => _isTtsAvailable;

  /// 获取是否正在播放
  bool get isPlaying => _isPlaying;

  /// 强制启用TTS（用于测试或手动恢复）
  void forceTtsEnabled() {
    _isTtsAvailable = true;
    _ttsFailureCount = 0;
  }

  /// 强制禁用TTS（用于无声/无障碍模式）
  void forceTtsDisabled() {
    _isTtsAvailable = false;
  }

  /// 重置TTS状态
  void resetTtsState() {
    _ttsFailureCount = 0;
    _isTtsAvailable = true;
  }

  /// 显示成功信息
  void showSuccessMessage(String text) {
    _bubbleManager.showSuccess(text: text);
  }

  /// 显示警告信息
  void showWarningMessage(String text) {
    _bubbleManager.showWarning(text: text);
  }

  /// 显示错误信息
  void showErrorMessage(String text) {
    _bubbleManager.showError(text: text);
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      await stop();
      _voiceService.dispose();
    } catch (e) {
      logger.e('Failed to dispose VoiceServiceEnhanced: $e');
    }
  }

  /// 获取服务诊断信息
  Map<String, dynamic> getDiagnostics() {
    return {
      'ttsAvailable': _isTtsAvailable,
      'ttsFailureCount': _ttsFailureCount,
      'isPlaying': _isPlaying,
      'maxTtsFailures': _maxTtsFailures,
    };
  }
}

/// 语音服务状态管理
class VoiceServiceState {
  /// TTS是否启用
  final bool ttsEnabled;

  /// 当前播放文本
  final String? currentText;

  /// 是否正在播放
  final bool isPlaying;

  /// 上一个错误消息
  final String? lastError;

  const VoiceServiceState({
    this.ttsEnabled = true,
    this.currentText,
    this.isPlaying = false,
    this.lastError,
  });

  VoiceServiceState copyWith({
    bool? ttsEnabled,
    String? currentText,
    bool? isPlaying,
    String? lastError,
  }) {
    return VoiceServiceState(
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      currentText: currentText ?? this.currentText,
      isPlaying: isPlaying ?? this.isPlaying,
      lastError: lastError,
    );
  }
}

/// 辅助函数：在故事中原始语音服务升级
/// 如果需要临时测试，可以使用这个包装
Future<VoiceServiceEnhanced> createEnhancedVoiceService({
  VoiceService? voiceService,
}) async {
  final service = VoiceServiceEnhanced(voiceService: voiceService);
  await service.init();
  return service;
}
