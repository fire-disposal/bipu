import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/voice/asr_engine.dart';
import '../../core/voice/tts_engine.dart';
import '../../core/services/im_service.dart';
import '../../core/voice/audio_resource_manager.dart';
import '../../core/utils/logger.dart';
import 'assistant_config.dart';

/// 语音助手状态枚举
enum AssistantState { idle, listening, thinking, speaking }

/// 更细粒度的业务阶段，用于驱动引导式 UI 与进度条
enum AssistantPhase {
  idle,
  greeting,
  askRecipientId,
  confirmRecipientId,
  guideRecordMessage,
  recording,
  transcribing,
  confirmMessage,
  sending,
  sent,
  farewell,
  error,
}

/// 语音助手事件
class AssistantEvent {
  final AssistantState state;
  final String? text;
  final String? error;

  AssistantEvent(this.state, {this.text, this.error});
}

/// 语音助手控制器 - 重新聚合精简的服务层
class AssistantController extends ChangeNotifier {
  static final AssistantController _instance = AssistantController._internal();
  factory AssistantController() => _instance;

  AssistantController._internal();

  final ASREngine _asr = ASREngine();
  final TTSEngine _tts = TTSEngine();
  final ImService _imService = ImService();
  final AudioResourceManager _audioManager = AudioResourceManager();
  final AssistantConfig _config = AssistantConfig();

  final ValueNotifier<AssistantState> state = ValueNotifier(
    AssistantState.idle,
  );
  final ValueNotifier<AssistantPhase> phase = ValueNotifier<AssistantPhase>(
    AssistantPhase.idle,
  );
  String? _currentText;
  String? get currentText => _currentText;

  String? _currentRecipientId;
  String? get currentRecipientId => _currentRecipientId;

  AssistantPhase get currentPhase => phase.value;

  /// 手动设置业务阶段（UI 可以监听 `phase`）
  void setPhase(AssistantPhase p) {
    if (phase.value != p) {
      phase.value = p;
      notifyListeners();
    }
  }

  String _currentOperatorId = 'op_system'; // 默认操作员
  String get currentOperatorId => _currentOperatorId;

  StreamSubscription<String>? _asrSubscription;
  StreamSubscription<double>? _volumeSubscription;

  final StreamController<AssistantEvent> _eventController =
      StreamController.broadcast();
  Stream<AssistantEvent> get onEvent => _eventController.stream;

  // 兼容旧API
  Stream<String> get onResult => _eventController.stream
      .where((event) => event.text != null)
      .map((event) => event.text!);

  // 公开音量流用于波形显示
  Stream<double> get onVolume => _asr.onVolume;

  /// 初始化所有引擎
  Future<void> init() async {
    try {
      await _asr.init();
      await _tts.init();
      logger.i('AssistantController initialized');
    } catch (e) {
      logger.e('AssistantController init failed: $e');
      rethrow;
    }
  }

  VoidCallback? _audioRelease;

  /// 开始语音监听
  Future<void> startListening() async {
    if (state.value != AssistantState.idle) return;

    try {
      _setState(AssistantState.listening);
      setPhase(AssistantPhase.recording);

      // 获取音频资源
      _audioRelease = await _audioManager.acquire();

      // 启动ASR
      await _asr.startRecording();

      // 监听结果
      _asrSubscription = _asr.onResult.listen((text) {
        _currentText = text;
        notifyListeners();
      });

      _volumeSubscription = _asr.onVolume.listen((volume) {
        // 可用于UI波形更新
      });
    } catch (e) {
      logger.e('Start listening failed: $e');
      _setState(AssistantState.idle);
      _audioRelease?.call();
      _audioRelease = null;
      rethrow;
    }
  }

  /// 停止监听并处理结果
  Future<void> stopListening() async {
    if (state.value != AssistantState.listening) return;

    try {
      await _asr.stop();
      _audioRelease?.call();
      _audioRelease = null;

      _asrSubscription?.cancel();
      _volumeSubscription?.cancel();

      if (_currentText?.isNotEmpty == true) {
        // 进入处理阶段
        setPhase(AssistantPhase.transcribing);
        await _processText(_currentText!);
      } else {
        _setState(AssistantState.idle);
      }
    } catch (e) {
      logger.e('Stop listening failed: $e');
      _setState(AssistantState.idle);
      rethrow;
    }
  }

  /// 发送当前文本
  Future<void> send() async {
    if (_currentText?.isEmpty != true || _currentRecipientId == null) return;

    try {
      _setState(AssistantState.thinking);
      setPhase(AssistantPhase.sending);

      // 发送消息
      await _imService.messageApi.sendMessage(
        receiverId: _currentRecipientId!,
        content: _currentText!,
        msgType: 'USER_POSTCARD',
      );

      _currentText = null;
      setPhase(AssistantPhase.sent);
      _setState(AssistantState.idle);
      notifyListeners();
    } catch (e) {
      logger.e('Send failed: $e');
      setPhase(AssistantPhase.error);
      _setState(AssistantState.idle);
      rethrow;
    }
  }

  /// 重播最后的消息
  Future<void> replay() async {
    if (_currentText?.isEmpty != true) return;

    try {
      _setState(AssistantState.speaking);
      setPhase(AssistantPhase.sent);

      // 获取音频资源
      _audioRelease = await _audioManager.acquire();

      // 生成并播放TTS
      final audio = await _tts.generate(text: _currentText!);
      if (audio != null) {
        // 这里需要音频播放逻辑，暂时简化
        await Future.delayed(const Duration(seconds: 2)); // 模拟播放
      }

      _audioRelease?.call();
      _audioRelease = null;
      _setState(AssistantState.idle);
      setPhase(AssistantPhase.idle);
    } catch (e) {
      logger.e('Replay failed: $e');
      _audioRelease?.call();
      _audioRelease = null;
      _setState(AssistantState.idle);
      setPhase(AssistantPhase.error);
      rethrow;
    }
  }

  /// 设置接收者
  void setRecipient(String recipientId) {
    _currentRecipientId = recipientId;
    notifyListeners();
  }

  /// 取消当前操作
  Future<void> cancel() async {
    await stopListening();
    _currentText = null;
    _setState(AssistantState.idle);
    setPhase(AssistantPhase.idle);
    notifyListeners();
  }

  void _setState(AssistantState newState) {
    if (state.value != newState) {
      state.value = newState;
      _eventController.add(AssistantEvent(newState, text: _currentText));
      notifyListeners();
    }
  }

  Future<void> _processText(String text) async {
    // 简单的文本处理逻辑，可扩展NLP
    _setState(AssistantState.thinking);

    // 模拟处理延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 关键词识别和流程控制
    if (matchesKeyword(text, 'cancel')) {
      await speakScript('farewell');
      await cancel();
    } else if (matchesKeyword(text, 'send')) {
      await send();
    } else if (matchesKeyword(text, 'rerecord')) {
      await speakScript('guideRecordMessage');
      _currentText = null;
      setPhase(AssistantPhase.guideRecordMessage);
      _setState(AssistantState.idle);
    } else if (_currentRecipientId == null) {
      // 如果还没有接收者ID，认为是接收者ID
      _currentRecipientId = _extractRecipientId(text);
      if (_currentRecipientId != null) {
        setPhase(AssistantPhase.confirmRecipientId);
        await speakScript('confirmRecipientId', {
          'recipientId': _currentRecipientId!,
        });
      } else {
        setPhase(AssistantPhase.askRecipientId);
        await speakScript('clarify');
      }
      _setState(AssistantState.idle);
    } else if (matchesKeyword(text, 'confirm')) {
      // 确认接收者ID，开始录制消息
      setPhase(AssistantPhase.guideRecordMessage);
      await speakScript('guideRecordMessage');
      _setState(AssistantState.idle);
    } else if (matchesKeyword(text, 'modify')) {
      // 修改接收者ID
      _currentRecipientId = null;
      setPhase(AssistantPhase.askRecipientId);
      await speakScript('askRecipientId');
      _setState(AssistantState.idle);
    } else {
      // 认为是消息内容
      setPhase(AssistantPhase.confirmMessage);
      await speakScript('confirmMessage', {'message': text});
      _setState(AssistantState.idle);
    }
  }

  /// 从文本中提取接收者ID（简化实现）
  String? _extractRecipientId(String text) {
    // 简单的数字提取逻辑
    final RegExp digitRegex = RegExp(r'\d+');
    final match = digitRegex.firstMatch(text);
    return match?.group(0);
  }

  /// 设置当前操作员
  void setOperator(String operatorId) {
    if (_config.getOperatorConfig(operatorId) != null) {
      _currentOperatorId = operatorId;
      notifyListeners();
    }
  }

  /// 获取当前操作员配置
  Map<String, dynamic>? getCurrentOperatorConfig() {
    return _config.getOperatorConfig(_currentOperatorId);
  }

  /// 播放操作员脚本
  Future<void> speakScript(
    String scriptKey, [
    Map<String, String>? params,
  ]) async {
    final script = _config.getOperatorScript(
      _currentOperatorId,
      scriptKey,
      params,
    );
    if (script.isNotEmpty) {
      await _speakText(script);
    }
  }

  /// 对外暴露的直接朗读文本接口（可指定说话人id和语速）
  Future<void> speakText(String text, {int sid = 0, double speed = 1.0}) async {
    if (text.isEmpty) return;

    try {
      _setState(AssistantState.speaking);

      // 获取音频资源
      final audioRelease = await _audioManager.acquire();

      // 生成并播放TTS
      final audio = await _tts.generate(text: text, sid: sid, speed: speed);
      if (audio != null) {
        // 占位播放逻辑（引擎返回音频后，实际播放由平台层处理）
        await Future.delayed(const Duration(seconds: 2));
      }

      audioRelease();
      _setState(AssistantState.idle);
    } catch (e) {
      logger.e('Speak text failed: $e');
      _setState(AssistantState.idle);
    }
  }

  /// 播放应用内音频资源（asset），并由 AssistantController 统一管理音频互斥
  Future<void> playAsset(String assetPath) async {
    if (assetPath.isEmpty) return;

    try {
      _setState(AssistantState.speaking);

      // 获取音频资源互斥锁
      final audioRelease = await _audioManager.acquire();

      final player = AudioPlayer();
      final Completer<void> played = Completer<void>();
      final sub = player.onPlayerComplete.listen((_) {
        if (!played.isCompleted) played.complete();
      });

      try {
        await player.play(AssetSource(assetPath));
        // 等待播放完成或出错
        await played.future;
      } catch (e) {
        logger.e('playAsset failed: $e');
      } finally {
        try {
          await player.stop();
        } catch (_) {}
        await player.dispose();
        await sub.cancel();
        // 释放资源
        try {
          audioRelease();
        } catch (_) {}
      }

      _setState(AssistantState.idle);
    } catch (e) {
      logger.e('playAsset failed: $e');
      _setState(AssistantState.idle);
    }
  }

  /// 检查文本是否匹配关键词
  bool matchesKeyword(String text, String keywordGroup) {
    return _config.matchesKeyword(text, keywordGroup);
  }

  /// 获取所有可用操作员
  List<String> getAvailableOperators() {
    return _config.getOperatorIds();
  }

  /// 语音播放文本（内部方法）
  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;

    try {
      _setState(AssistantState.speaking);

      // 获取音频资源
      final audioRelease = await _audioManager.acquire();

      // 生成并播放TTS
      final audio = await _tts.generate(
        text: text,
        sid: _getCurrentOperatorTtsSid(),
      );
      if (audio != null) {
        // 这里需要实际的音频播放逻辑
        // 暂时用延迟模拟
        await Future.delayed(const Duration(seconds: 2));
      }

      audioRelease();
      _setState(AssistantState.idle);
    } catch (e) {
      logger.e('Speak text failed: $e');
      _setState(AssistantState.idle);
    }
  }

  /// 获取当前操作员的TTS说话人ID
  int _getCurrentOperatorTtsSid() {
    final config = getCurrentOperatorConfig();
    return config?['ttsSid'] ?? 0;
  }
}
