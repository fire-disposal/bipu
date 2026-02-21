import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:bipupu/features/assistant/assistant_config.dart';
import 'package:piper_tts_plugin/enums/piper_voice_pack.dart';

/// 用户意图枚举 - 统一UI和语音输入
enum UserIntent {
  confirm, // 确认/下一步
  modify, // 修改/重填
  cancel, // 取消/退出
  rerecord, // 重录
  send, // 最终发送
  start, // 开始/启动
  stop, // 停止
}

/// 语音助手业务阶段枚举
enum AssistantPhase {
  idle, // 空闲
  greeting, // 初始化引导
  askRecipientId, // 请提供收信方ID
  confirmRecipientId, // 请确认收信方ID
  guideRecordMessage, // 准备录音
  recording, // 正在录音
  transcribing, // 转写中
  confirmMessage, // 请确认消息
  sending, // 发送中
  sent, // 已发送
  farewell, // 结束
  error, // 出错
}

/// 意图驱动的语音助手控制器
/// 统一处理UI和语音输入，简化状态机逻辑
class IntentDrivenAssistantController extends ChangeNotifier {
  static final IntentDrivenAssistantController _instance =
      IntentDrivenAssistantController._internal();
  factory IntentDrivenAssistantController() => _instance;

  IntentDrivenAssistantController._internal();

  final AssistantConfig _config = AssistantConfig();

  /// 获取语音命令中心（用于波形控制器等）
  // VoiceCommandCenter? get voiceCommandCenter => null;

  // 操作员到Piper语音包的映射
  final Map<String, PiperVoicePack> _operatorVoiceMap = {
    'op_system': PiperVoicePack.norman,
    'op_001': PiperVoicePack.norman,
    'op_002': PiperVoicePack.amy,
  };

  // 语音命令中心引用
  // final VoiceCommandCenter _voiceCommandCenter = VoiceCommandCenter();
  // IM服务引用
  // final ImService _imService = ImService();

  AssistantPhase _currentPhase = AssistantPhase.idle;
  bool _isTransitioning = false;

  String? _currentText;
  String? _currentRecipientId;
  String _currentOperatorId = 'op_system';

  /// 当前业务阶段
  AssistantPhase get currentPhase => _currentPhase;

  /// 当前文本内容
  String? get currentText => _currentText;

  /// 当前收信方ID
  String? get currentRecipientId => _currentRecipientId;

  /// 当前操作员ID
  String get currentOperatorId => _currentOperatorId;

  /// 是否正在转换状态
  bool get isTransitioning => _isTransitioning;

  /// 启动语音助手流程
  Future<void> startAssistant() async {
    if (_currentPhase != AssistantPhase.idle) {
      log('无法启动：当前阶段不是空闲状态');
      return;
    }

    await _performTransition(AssistantPhase.greeting, UserIntent.start, null);
  }

  /// 开始监听语音输入
  Future<void> startListening() async {
    // await _voiceCommandCenter.startListening();
    log('开始监听语音输入（模拟）');
  }

  /// 停止监听语音输入
  Future<String> stopListening() async {
    // return await _voiceCommandCenter.stopListening();
    log('停止监听语音输入（模拟）');
    return '模拟的语音识别结果';
  }

  /// 获取当前可用的意图列表
  List<UserIntent> get availableActions {
    final actions = <UserIntent>[];

    // 根据当前阶段确定可用的意图
    switch (_currentPhase) {
      case AssistantPhase.idle:
        actions.add(UserIntent.start);
        break;

      case AssistantPhase.greeting:
        actions.add(UserIntent.cancel);
        break;

      case AssistantPhase.askRecipientId:
        actions.addAll([UserIntent.confirm, UserIntent.cancel]);
        break;

      case AssistantPhase.confirmRecipientId:
        actions.addAll([
          UserIntent.confirm,
          UserIntent.modify,
          UserIntent.cancel,
        ]);
        break;

      case AssistantPhase.guideRecordMessage:
        actions.addAll([UserIntent.confirm, UserIntent.cancel]);
        break;

      case AssistantPhase.recording:
        actions.add(UserIntent.stop);
        break;

      case AssistantPhase.confirmMessage:
        actions.addAll([
          UserIntent.send,
          UserIntent.rerecord,
          UserIntent.cancel,
        ]);
        break;

      case AssistantPhase.sending:
        // 发送中不可操作
        break;

      case AssistantPhase.sent:
        actions.add(UserIntent.confirm);
        break;

      case AssistantPhase.farewell:
        actions.add(UserIntent.confirm);
        break;

      case AssistantPhase.error:
        actions.addAll([UserIntent.start, UserIntent.cancel]);
        break;

      case AssistantPhase.transcribing:
        // 转写中不可操作
        break;
    }

    return actions;
  }

  /// 设置操作员
  void setOperator(String operatorId) {
    _currentOperatorId = operatorId;
    notifyListeners();
  }

  /// 设置收信方ID
  void setRecipient(String recipientId) {
    _currentRecipientId = recipientId;
    notifyListeners();
  }

  /// 设置消息文本
  void setText(String text) {
    _currentText = text;
    notifyListeners();
  }

  /// 初始化语音系统
  Future<void> init() async {
    // await _voiceCommandCenter.init();
    log('初始化语音系统（模拟）');
  }

  /// 统一入口：处理用户意图（UI或语音触发）
  /// [intent] 用户意图
  /// [params] 额外参数（如文本内容、收信方ID等）
  Future<void> handleIntent(
    UserIntent intent, {
    Map<String, String>? params,
  }) async {
    // 防抖与状态锁：防止语音和UI同时触发导致冲突
    if (_isTransitioning) {
      log('意图处理被跳过：正在转换状态中');
      return;
    }

    _isTransitioning = true;

    try {
      log('处理意图: $intent, 当前阶段: $_currentPhase, 参数: $params');

      // 根据意图更新参数
      if (params != null) {
        if (params.containsKey('recipientId')) {
          _currentRecipientId = params['recipientId'];
        }
        if (params.containsKey('text')) {
          _currentText = params['text'];
        }
      }

      // 确定下一阶段
      final nextPhase = _determineNextPhase(_currentPhase, intent, params);
      if (nextPhase != null) {
        await _performTransition(nextPhase, intent, params);
      } else {
        log('没有找到从阶段 $_currentPhase 到意图 $intent 的转换');
      }
    } catch (e, stackTrace) {
      log('处理意图失败: $e, $stackTrace');
      await _handleError();
    } finally {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// 停止语音助手（返回空闲状态）
  Future<void> stop() async {
    await handleIntent(UserIntent.cancel);
  }

  /// 获取当前阶段可用的意图列表（供UI显示按钮）
  List<UserIntent> get availableIntents {
    final actions = <UserIntent>[];

    // 根据当前阶段确定可用的意图
    switch (_currentPhase) {
      case AssistantPhase.idle:
        actions.add(UserIntent.start);
        break;

      case AssistantPhase.greeting:
        actions.add(UserIntent.cancel);
        break;

      case AssistantPhase.askRecipientId:
        actions.addAll([UserIntent.confirm, UserIntent.cancel]);
        break;

      case AssistantPhase.confirmRecipientId:
        actions.addAll([
          UserIntent.confirm,
          UserIntent.modify,
          UserIntent.cancel,
        ]);
        break;

      case AssistantPhase.guideRecordMessage:
        actions.addAll([UserIntent.confirm, UserIntent.cancel]);
        break;

      case AssistantPhase.recording:
        actions.add(UserIntent.stop);
        break;

      case AssistantPhase.confirmMessage:
        actions.addAll([
          UserIntent.send,
          UserIntent.rerecord,
          UserIntent.cancel,
        ]);
        break;

      case AssistantPhase.sending:
        // 发送中不可操作
        break;

      case AssistantPhase.sent:
        actions.add(UserIntent.confirm);
        break;

      case AssistantPhase.farewell:
        actions.add(UserIntent.confirm);
        break;

      case AssistantPhase.error:
        actions.addAll([UserIntent.start, UserIntent.cancel]);
        break;

      case AssistantPhase.transcribing:
        // 转写中不可操作
        break;
    }

    return actions;
  }

  /// 执行阶段对应的操作
  Future<void> _executePhaseAction(
    AssistantPhase phase,
    UserIntent intent,
    Map<String, String>? params,
  ) async {
    switch (phase) {
      case AssistantPhase.greeting:
        await _speakScript('greeting');
        break;

      case AssistantPhase.askRecipientId:
        await _speakScript('askRecipientId');
        break;

      case AssistantPhase.confirmRecipientId:
        await _speakScript('confirmRecipientId', {
          'recipientId': _currentRecipientId ?? '',
        });
        break;

      case AssistantPhase.guideRecordMessage:
        await _speakScript('guideRecordMessage');
        break;

      case AssistantPhase.recording:
        // 开始录音
        // await _voiceCommandCenter.startListening();
        log('开始录音（模拟）');
        break;

      case AssistantPhase.transcribing:
        // 转写完成，显示确认界面
        await _speakScript('transcribingComplete');
        break;

      case AssistantPhase.confirmMessage:
        await _speakScript('confirmMessage', {'message': _currentText ?? ''});
        break;

      case AssistantPhase.sending:
        await _sendMessage();
        break;

      case AssistantPhase.sent:
        await _speakScript('sent');
        break;

      case AssistantPhase.farewell:
        await _speakScript('farewell');
        break;

      case AssistantPhase.error:
        await _speakScript('error');
        break;

      case AssistantPhase.idle:
        // 空闲状态，无需操作
        break;
    }
  }

  AssistantPhase? _determineNextPhase(
    AssistantPhase current,
    UserIntent intent,
    Map<String, String>? params,
  ) {
    log('确定下一阶段: 当前=$current, 意图=$intent');

    // 特殊处理：开始意图
    if (intent == UserIntent.start) {
      if (current == AssistantPhase.idle) {
        return AssistantPhase.greeting;
      }
      if (current == AssistantPhase.error) {
        return AssistantPhase.greeting;
      }
      return null;
    }

    // 特殊处理：停止意图（录音中）
    if (intent == UserIntent.stop && current == AssistantPhase.recording) {
      return AssistantPhase.transcribing;
    }

    // 路由映射表
    final routes = {
      AssistantPhase.greeting: {
        UserIntent.confirm: AssistantPhase.askRecipientId,
        UserIntent.cancel: AssistantPhase.farewell,
      },
      AssistantPhase.askRecipientId: {
        UserIntent.confirm: _currentRecipientId != null
            ? AssistantPhase.confirmRecipientId
            : AssistantPhase.askRecipientId,
        UserIntent.cancel: AssistantPhase.farewell,
      },
      AssistantPhase.confirmRecipientId: {
        UserIntent.confirm: AssistantPhase.guideRecordMessage,
        UserIntent.modify: AssistantPhase.askRecipientId,
        UserIntent.cancel: AssistantPhase.farewell,
      },
      AssistantPhase.guideRecordMessage: {
        UserIntent.confirm: AssistantPhase.recording,
        UserIntent.cancel: AssistantPhase.farewell,
      },
      AssistantPhase.transcribing: {
        UserIntent.confirm: AssistantPhase.confirmMessage,
        UserIntent.rerecord: AssistantPhase.guideRecordMessage,
        UserIntent.cancel: AssistantPhase.farewell,
      },
      AssistantPhase.confirmMessage: {
        UserIntent.send: AssistantPhase.sending,
        UserIntent.rerecord: AssistantPhase.guideRecordMessage,
        UserIntent.cancel: AssistantPhase.farewell,
      },
      AssistantPhase.sending: {
        // 发送完成后自动进入已发送状态
      },
      AssistantPhase.sent: {UserIntent.confirm: AssistantPhase.farewell},
      AssistantPhase.farewell: {UserIntent.confirm: AssistantPhase.idle},
    };

    return routes[current]?[intent];
  }

  /// 执行状态转换（包含清理和资源管理）
  Future<void> _performTransition(
    AssistantPhase nextPhase,
    UserIntent intent,
    Map<String, String>? params,
  ) async {
    log('执行转换: $_currentPhase -> $nextPhase');

    // 1. 强制停止当前所有音频活动
    // await _voiceCommandCenter.stopAll();
    log('停止所有音频活动（模拟）');

    // 2. 更新阶段
    _currentPhase = nextPhase;
    notifyListeners();

    // 3. 执行阶段对应的操作
    await _executePhaseAction(nextPhase, intent, params);
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    if (_currentText == null || _currentRecipientId == null) {
      log('发送消息失败：缺少必要参数');
      await _handleError();
      return;
    }

    try {
      // 使用IM服务发送消息（暂时注释）
      // await _imService.sendMessage(
      //   recipientBipupuId: _currentRecipientId!,
      //   content: _currentText!,
      // );
      log('模拟发送消息: 收信方=${_currentRecipientId}, 内容=${_currentText}');

      // 发送成功，进入已发送状态
      _currentPhase = AssistantPhase.sent;
      notifyListeners();

      await _speakScript('sent');
    } catch (e, stackTrace) {
      log('发送消息失败: $e, $stackTrace');
      await _handleError();
    }
  }

  /// 播放脚本
  Future<void> _speakScript(
    String scriptKey, [
    Map<String, String>? params,
  ]) async {
    try {
      final script = _config.getOperatorScript(
        _currentOperatorId,
        scriptKey,
        params,
      );

      if (script.isNotEmpty) {
        // 获取当前操作员对应的Piper语音包
        final voice =
            _operatorVoiceMap[_currentOperatorId] ?? PiperVoicePack.norman;

        // await _voiceCommandCenter.startTalking(script, voice: voice);
        log('播放脚本: $script，使用语音包: $voice');

        // 播完后根据配置决定是否开启录音
        if (_shouldAutoListenAfterScript(scriptKey)) {
          await Future.delayed(const Duration(milliseconds: 500));
          // await _voiceCommandCenter.startListening();
          log('自动开始监听（模拟）');
        }
      }
    } catch (e, stackTrace) {
      log('播放脚本失败: $e, $stackTrace');
    }
  }

  /// 判断脚本播放后是否自动开始录音
  bool _shouldAutoListenAfterScript(String scriptKey) {
    return scriptKey == 'guideRecordMessage' ||
        scriptKey == 'askRecipientId' ||
        scriptKey == 'clarify';
  }

  /// 处理错误
  Future<void> _handleError() async {
    _currentPhase = AssistantPhase.error;
    notifyListeners();

    await _speakScript('error');
  }

  /// 检查文本是否匹配关键词组
  bool matchesKeyword(String text, String keywordGroup) {
    return _config.matchesKeyword(text, keywordGroup);
  }

  @override
  void dispose() {
    // _voiceCommandCenter.dispose();
    super.dispose();
  }
}
