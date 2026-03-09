import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/im_service.dart' show ImService;
import '../../../core/api/models/message_type.dart';
import '../models/operator_model.dart';
import '../services/operator_service.dart';
import '../../../core/voice/voice_service.dart';
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
  List<SendRecord> get sentHistory => List.unmodifiable(_sentHistory);
  
  // ───────────────────────────────────────────────────────────────────────────
  // 拨号准备
  // ───────────────────────────────────────────────────────────────────────────
  
  /// 初始化拨号准备
  Future<void> initializePrep() async {
    try {
      await _operatorService.init();
      _selectRandomOperator();
      _phase = PagerPhase.prep;
      notifyListeners();
    } catch (e) {
      _error('初始化失败：$e');
    }
  }
  
  void _selectRandomOperator() {
    _operator = _operatorService.getRandomOperator();
    debugPrint('[PagerVM] 选择接线员 - ${_operator!.name}');
  }
  
  void selectOperator(OperatorPersonality op) {
    _operator = op;
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
    final greeting = _operator!.dialogues.getGreeting();
    await _voice.speak(greeting);
    
    if (_phase != PagerPhase.inCall) return;
    
    // 短暂停顿
    await Future.delayed(const Duration(milliseconds: 400));
    
    // ② 询问目标 ID
    final askTarget = _operator!.dialogues.getAskTarget();
    await _voice.speak(askTarget);
    
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
    if (_isConfirming || _targetId.isEmpty) return;
    
    _isConfirming = true;
    notifyListeners();
    
    try {
      // 播报确认台词
      final confirmText = _operator!.dialogues.getConfirmId(_targetId);
      await _voice.speak(confirmText);
      
      if (_phase != PagerPhase.inCall) return;
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 检查用户是否存在
      try {
        await ApiClient.instance.api.users.getApiUsersUsersBipupuId(
          bipupuId: _targetId,
        );
        debugPrint('[PagerVM] 目标用户存在');
        
        // 成功 → 进入消息录入
        final askMsg = _operator!.dialogues.getRequestMessage();
        await _voice.speak(askMsg);
        
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('[PagerVM WARN] 目标用户不存在');
        
        final notFound = _operator!.dialogues.getUserNotFound();
        await _voice.speak(notFound);
        
        if (_phase != PagerPhase.inCall) return;
        await Future.delayed(const Duration(milliseconds: 300));
        
        _errorMessage = '该用户不存在，请重新输入 ID';
        _targetId = '';
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
    if (_phase != PagerPhase.inCall) return;
    
    await _voice.stopSpeaking();
    _isRecording = true;
    _asrTranscript = '';
    notifyListeners();
    
    try {
      // 监听 ASR 结果
      final results = _voice.startListening(timeout: const Duration(seconds: 30));
      
      await for (final text in results) {
        _asrTranscript = text;
        notifyListeners();
        break; // 收到一个结果就停止
      }
      
      if (_asrTranscript.isEmpty) {
        debugPrint('[PagerVM WARN] 未识别到语音');
        _isRecording = false;
        notifyListeners();
        return;
      }
      
      debugPrint('[PagerVM] 识别结果 "${_asrTranscript}"');
      
      // 进入确认阶段
      _messageContent = _asrTranscript;
      _asrTranscript = '';
      _isRecording = false;
      _phase = PagerPhase.reviewing;
      notifyListeners();
      
    } catch (e) {
      debugPrint('[PagerVM ERROR] 录音失败：$e');
      _isRecording = false;
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
    _phase = PagerPhase.inCall;
    notifyListeners();
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // 发送消息
  // ───────────────────────────────────────────────────────────────────────────
  
  /// 发送消息
  Future<void> sendMessage({String? message}) async {
    final content = (message ?? _messageContent).trim();
    if (content.isEmpty || _targetId.isEmpty) return;
    
    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await ImService().sendMessage(
        receiverId: _targetId,
        content: content,
        messageType: MessageType.voice,
      );
      
      if (result != null) {
        debugPrint('[PagerVM] 消息发送成功');
        
        _sentHistory.add(SendRecord(
          targetId: _targetId,
          content: content,
          sentAt: DateTime.now(),
        ));
        
        // 成功提示
        final successText = _operator!.dialogues.getSuccessMessage();
        await _voice.speak(successText);
        
        if (_phase != PagerPhase.reviewing) return;
        await Future.delayed(const Duration(milliseconds: 300));
        
        // 询问是否继续
        final askContinue = _operator!.dialogues.getAskContinue();
        await _voice.speak(askContinue);
        
        // 解锁接线员
        await _operatorService.unlockOperator(_operator!.id);
        
        // 重置状态
        _targetId = '';
        _messageContent = '';
        _isSending = false;
        notifyListeners();
        
      } else {
        _error('发送失败');
        _phase = PagerPhase.reviewing;
        notifyListeners();
      }
    } catch (e) {
      _error('发送异常：$e');
      _phase = PagerPhase.reviewing;
      notifyListeners();
    }
  }
  
  /// 继续发送给另一人
  void continueToNextRecipient() async {
    final askTarget = _operator!.dialogues.getAskTarget();
    await _voice.speak(askTarget);
    
    _targetId = '';
    _messageContent = '';
    _phase = PagerPhase.inCall;
    notifyListeners();
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // 挂断
  // ───────────────────────────────────────────────────────────────────────────
  
  /// 挂断通话
  Future<void> hangup() async {
    debugPrint('[PagerVM] 挂断通话');
    
    await _voice.stopSpeaking();
    await _voice.stopListening();
    
    await initializePrep();
  }
  
  void _error(String message) {
    debugPrint('[PagerVM ERROR] 错误：$message');
    _errorMessage = message;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }
}
