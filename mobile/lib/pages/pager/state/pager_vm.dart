import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/im_service.dart' show ImService;
import '../../../core/api/models/message_type.dart';
import '../models/operator_model.dart';
import '../services/operator_service.dart';
import '../services/operator_voice.dart';
import '../../../core/voice/voice_service.dart';
import '../../../core/voice/voice_manifest.dart';
import 'pager_phase.dart';

/// 发送记录
class SendRecord {
  final String targetId;
  final String content;
  final DateTime sentAt;

  const SendRecord({
    required this.targetId,
    required this.content,
    required this.sentAt,
  });
}

/// Pager 页面 ViewModel - 替代 PagerCubit
///
/// 使用 ChangeNotifier 而非 Cubit，简化状态管理
class PagerVM extends ChangeNotifier {
  static PagerVM? _instance;
  static PagerVM get instance {
    _instance ??= PagerVM._();
    return _instance!;
  }

  PagerVM._() {
    // 自动初始化
    initializePrep();
  }

  final VoiceService _voice = VoiceService();
  final OperatorService _operatorService = OperatorService();
  final VoiceModeManager _voiceModeManager = VoiceModeManager.instance;

  // 台词播放器（接线员 + 后端在 _selectRandomOperator 后初始化）
  late OperatorVoice _operatorVoice;
  late OperatorVoiceBackend _backend;

  // ASR 流管理
  StreamSubscription<String>? _asrSubscription;

  // 状态
  PagerPhase _phase = PagerPhase.prep;
  OperatorPersonality? _operator;
  String _targetId = '';
  String _messageContent = '';
  String _asrTranscript = '';
  String? _errorMessage;
  bool _isSending = false;
  bool _isConfirming = false;
  bool _isRecording = false;
  String _currentDialogue = '';

  /// inCall 子状态：目标 ID 是否已确认
  /// false → 展示号码输入面板；true → 展示录音面板
  bool _targetConfirmed = false;

  /// 台词历史（最近 8 条，供气泡流展示用）
  final List<String> _dialogueHistory = [];

  // 本次录音的振幅包络（随消息一起发送）
  List<int>? _capturedWaveform;

  // 通话记录
  final List<SendRecord> _sentHistory = [];

  // Getters
  PagerPhase get phase => _phase;
  OperatorPersonality? get operator => _operator;
  String get targetId => _targetId;
  String get messageContent => _messageContent;
  String get asrTranscript => _asrTranscript;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;
  bool get isConfirming => _isConfirming;
  bool get isRecording => _isRecording;
  String get currentDialogue => _currentDialogue;
  bool get targetConfirmed => _targetConfirmed;
  List<String> get dialogueHistory => List.unmodifiable(_dialogueHistory);
  List<SendRecord> get sentHistory => List.unmodifiable(_sentHistory);
  OperatorService get operatorService => _operatorService;

  // ───────────────────────────────────────────────────────────────────────────
  // 拨号准备
  // ───────────────────────────────────────────────────────────────────────────

  /// 初始化拨号准备
  Future<void> initializePrep() async {
    try {
      // 初始化语音服务（仅 ASR，TTS 已禁用）
      await _voice.init();

      // 初始化语音模式管理器（kUsePrerecordedVoiceOnly=true，直接进入 prerecordedOnly 模式）
      await _voiceModeManager.initialize();

      await _operatorService.init();
      await _selectRandomOperator();
      _phase = PagerPhase.prep;
      notifyListeners();
    } catch (e) {
      _error('初始化失败：$e');
    }
  }

  Future<void> _selectRandomOperator() async {
    _operator = _operatorService.getRandomOperator();
    await _initBackend();
    _operatorVoice = OperatorVoice(operator: _operator!, backend: _backend);
    debugPrint('[PagerVM] 选择接线员 - ${_operator!.name}');
    debugPrint('[PagerVM] 语音模式 - ${_voiceModeManager.mode}');
  }

  /// 初始化播放后端
  ///
  /// kUsePrerecordedVoiceOnly = true 时 VoiceModeManager 常量返回
  /// [VoiceMode.prerecordedOnly]，始终使用 [PrerecordedVoiceBackend]。
  Future<void> _initBackend() async {
    final mode = _voiceModeManager.mode;

    if (mode == VoiceMode.ttsOnly) {
      // TTS 已注释，正常情况下不应进入此分支
      _backend = TtsVoiceBackend(_voice);
      debugPrint('[PagerVM] ❗ TTS 后端（TTS 已禁用，延迟请检查 kUsePrerecordedVoiceOnly）');
    } else if (mode == VoiceMode.prerecordedOnly) {
      _backend = PrerecordedVoiceBackend();
      debugPrint('[PagerVM] ✅ 预录制后端（voice_manifest.json 索引）');
    } else {
      // Fallback 模式（不应再触及，保留兼容）
      _backend = FallbackVoiceBackend(
        prerecorded: PrerecordedVoiceBackend(),
        tts: TtsVoiceBackend(_voice),
      );
      debugPrint('[PagerVM] ⚠️ Fallback 后端（TTS 已禁用，请检查语音模式配置）');
    }
  }

  void selectOperator(OperatorPersonality op) async {
    _operator = op;
    await _initBackend();
    _operatorVoice.setOperator(op);
    notifyListeners();
  }

  /// 切换语音模式
  Future<void> setVoiceMode(VoiceMode mode) async {
    _voiceModeManager.setMode(mode);
    await _initBackend();
    _operatorVoice = OperatorVoice(operator: _operator!, backend: _backend);
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 连接
  // ───────────────────────────────────────────────────────────────────────────

  /// 开始连接
  Future<void> startDialing() async {
    _operator ??= _operatorService.getRandomOperator();
    _phase = PagerPhase.connecting;
    notifyListeners();

    debugPrint('[PagerVM] 开始连接，接线员 = ${_operator!.name}');

    // 连接动画（2 秒）
    await Future.delayed(const Duration(seconds: 2));

    _phase = PagerPhase.inCall;
    notifyListeners();

    // 开始问候流程
    await _greetingFlow();
  }

  /// 问候流程
  Future<void> _greetingFlow() async {
    if (_phase != PagerPhase.inCall || _operator == null) return;

    // ① 问候语
    await _operatorVoice.say(OperatorLine.greeting, onText: _updateDialogue);

    if (_phase != PagerPhase.inCall) return;
    await Future.delayed(const Duration(milliseconds: 400));

    // ② 询问目标 ID
    await _operatorVoice.say(OperatorLine.askTarget, onText: _updateDialogue);

    await Future.delayed(const Duration(milliseconds: 400));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 目标 ID 输入
  // ───────────────────────────────────────────────────────────────────────────

  void updateTargetId(String id) {
    if (_isConfirming) return;
    if (id.length > 12) return;
    _targetId = id;
    _errorMessage = null;
    notifyListeners();
  }

  void clearTargetId() {
    if (_isConfirming) return;
    _targetId = '';
    notifyListeners();
  }

  /// 确认目标 ID
  Future<void> confirmTargetId() async {
    if (_isConfirming || _targetId.isEmpty || _phase != PagerPhase.inCall)
      return;

    _isConfirming = true;
    notifyListeners();

    final targetSnapshot = _targetId;

    try {
      bool userExists = false;
      final apiCallFuture = () async {
        try {
          await ApiClient.instance.api.users.getApiUsersUsersBipupuId(
            bipupuId: targetSnapshot,
          );
          userExists = true;
        } catch (_) {
          userExists = false;
        }
      }();

      // TTS + API 并行：onText 在播放前同步回调，UI 立即更新
      await Future.wait([
        _operatorVoice.say(
          OperatorLine.confirmId,
          param: targetSnapshot,
          onText: _updateDialogue,
        ),
        apiCallFuture,
      ]);

      if (_phase != PagerPhase.inCall) return;

      if (userExists) {
        debugPrint('[PagerVM] 目标用户存在，切换到录音阶段');
        await _operatorVoice.say(
          OperatorLine.requestMessage,
          onText: _updateDialogue,
        );
        if (_phase != PagerPhase.inCall) return;
        // ✅ 关键：切换到录音子阶段
        _targetConfirmed = true;
        notifyListeners();
      } else {
        debugPrint('[PagerVM WARN] 目标用户不存在');
        await _operatorVoice.say(
          OperatorLine.userNotFound,
          onText: _updateDialogue,
        );

        if (_phase != PagerPhase.inCall) return;

        _errorMessage = '该用户不存在，请重新输入 ID';
        _targetId = '';
        _targetConfirmed = false;
        notifyListeners();
      }
    } finally {
      _isConfirming = false;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 消息录入
  // ───────────────────────────────────────────────────────────────────────────

  /// 开始语音录音
  Future<void> startVoiceRecording() async {
    if (_phase != PagerPhase.inCall || _targetId.isEmpty) {
      debugPrint('[PagerVM WARN] 非 inCall 阶段或无目标 ID，无法开始录音');
      return;
    }

    await _voice.stopSpeaking();

    // 清理前一个 ASR 订阅
    await _asrSubscription?.cancel();

    _isRecording = true;
    _asrTranscript = '';
    notifyListeners();

    try {
      final results = _voice.startListening(
        timeout: const Duration(seconds: 30),
      );

      // 显式管理订阅，防止流泄漏
      bool resultReceived = false;
      _asrSubscription = results.listen(
        (text) {
          _asrTranscript = text;
          _messageContent = text;
          resultReceived = true;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[PagerVM ERROR] ASR 错误：$e');
          if (_isRecording) {
            _error('录音失败，请重试');
            _isRecording = false;
            notifyListeners();
          }
        },
        onDone: () {
          if (_isRecording && resultReceived) {
            _isRecording = false;
            // 录音流结束后立即取回振幅包络
            _capturedWaveform = _voice.lastWaveform;
            debugPrint(
              '[PagerVM] 捕获 waveform：${_capturedWaveform?.length ?? 0} 点',
            );
            _phase = PagerPhase.reviewing;
            notifyListeners();
          }
        },
        cancelOnError: true,
      );

      // 添加超时保护
      await Future.delayed(const Duration(seconds: 31));
      if (_isRecording) {
        debugPrint('[PagerVM WARN] ASR 超时，强制停止');
        await _asrSubscription?.cancel();
        _isRecording = false;
        _error('录音超时，请重试');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PagerVM ERROR] startVoiceRecording 异常：$e');
      _isRecording = false;
      _error('录音异常：$e');
      notifyListeners();
    }
  }

  /// 停止录音
  void stopRecording() {
    _voice.stopListening();
  }

  /// 切换到文字输入
  void switchToTextInput() {
    _voice.stopListening();
    _voice.stopSpeaking();
    _phase = PagerPhase.reviewing;
    notifyListeners();
  }

  void updateMessageContent(String content) {
    _messageContent = content;
    notifyListeners();
  }

  void backToVoiceInput() {
    _messageContent = '';
    _asrTranscript = '';
    _errorMessage = null;
    _capturedWaveform = null;
    // 保留 _targetConfirmed = true，回到录音面板而非重新输入号码
    _targetConfirmed = true;
    _phase = PagerPhase.inCall;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 发送消息
  // ───────────────────────────────────────────────────────────────────────────

  /// 发送消息
  Future<void> sendMessage({String? message}) async {
    // 第一层：预检查
    if (_phase != PagerPhase.reviewing) {
      debugPrint('[PagerVM WARN] 不在 reviewing 阶段，无法发送消息');
      return;
    }

    final content = (message ?? _messageContent).trim();
    if (content.isEmpty || _targetId.isEmpty) {
      debugPrint('[PagerVM WARN] 内容或目标为空，无法发送');
      return;
    }

    // 第二层：操作符检查
    if (_operator == null) {
      _error('接线员数据丢失');
      return;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    // 快照保存，防止 await 期间变量被修改
    final targetIdSnapshot = _targetId;
    final operatorSnapshot = _operator!;

    try {
      final result = await ImService().sendMessage(
        receiverId: targetIdSnapshot,
        content: content,
        messageType: MessageType.voice,
        waveform: _capturedWaveform,
      );

      // 网络请求后，重新检查状态
      if (_phase != PagerPhase.reviewing) {
        debugPrint('[PagerVM] 发送中状态已变化，放弃');
        return;
      }

      if (result != null) {
        debugPrint('[PagerVM] 消息发送成功');

        _sentHistory.add(
          SendRecord(
            targetId: targetIdSnapshot,
            content: content,
            sentAt: DateTime.now(),
          ),
        );

        // 成功提示（使用快照）
        await _operatorVoice.say(
          OperatorLine.successMessage,
          onText: _updateDialogue,
        );

        // 再次检查状态
        if (_phase != PagerPhase.reviewing) return;
        await Future.delayed(const Duration(milliseconds: 300));

        // 询问是否继续
        await _operatorVoice.say(
          OperatorLine.askContinue,
          onText: _updateDialogue,
        );

        // 成功后回到 inCall 的「输入号码」子阶段，等待下一条消息
        if (_phase == PagerPhase.reviewing) {
          await _operatorService.unlockOperator(operatorSnapshot.id);
          _targetId = '';
          _messageContent = '';
          _capturedWaveform = null;
          _targetConfirmed = false; // 重置子阶段
          _isSending = false;
          _phase = PagerPhase.inCall;
          notifyListeners();
        } else {
          debugPrint('[PagerVM] 发送完成但状态已变化，不更新');
          _isSending = false;
        }
      } else {
        _error('发送失败');
        if (_phase == PagerPhase.reviewing) {
          notifyListeners();
        }
      }
    } catch (e) {
      _error('发送异常：$e');
      if (_phase == PagerPhase.reviewing) {
        notifyListeners();
      }
    } finally {
      _isSending = false;
    }
  }

  /// 继续发送给另一人
  Future<void> continueToNextRecipient() async {
    _targetId = '';
    _messageContent = '';
    _errorMessage = null;
    _isSending = false;
    _targetConfirmed = false; // 重置到号码输入面板

    _phase = PagerPhase.inCall;
    notifyListeners();

    await _operatorVoice.say(OperatorLine.askTarget, onText: _updateDialogue);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 挂断
  // ───────────────────────────────────────────────────────────────────────────

  /// 挂断通话
  Future<void> hangup() async {
    debugPrint('[PagerVM] 挂断通话');

    // 停止所有语音操作
    await _voice.stopSpeaking();
    await _voice.stopListening();

    // 重置所有状态
    _phase = PagerPhase.prep;
    _targetId = '';
    _messageContent = '';
    _asrTranscript = '';
    _errorMessage = null;
    _currentDialogue = '';
    _capturedWaveform = null;
    _isSending = false;
    _isConfirming = false;
    _isRecording = false;
    _targetConfirmed = false;
    _dialogueHistory.clear();
    notifyListeners();

    // 重新初始化
    await initializePrep();
  }

  void _error(String message) {
    debugPrint('[PagerVM ERROR] 错误：$message');
    _errorMessage = message;
    notifyListeners();
  }

  /// 更新 UI 台词文字（用作 OperatorVoice.say 的 onText 回调）
  /// 同时写入台词历史（最多保留 8 条）
  void _updateDialogue(String text) {
    _currentDialogue = text;
    if (text.isNotEmpty) {
      _dialogueHistory.add(text);
      if (_dialogueHistory.length > 8) _dialogueHistory.removeAt(0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _asrSubscription?.cancel(); // 清理 ASR 流

    // 清理后端资源
    if (_backend is FallbackVoiceBackend) {
      (_backend as FallbackVoiceBackend).dispose();
    } else if (_backend is PrerecordedVoiceBackend) {
      (_backend as PrerecordedVoiceBackend).dispose();
    }

    _voice.dispose();
    super.dispose();
  }
}
