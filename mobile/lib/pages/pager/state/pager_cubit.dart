import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/api/models/message_create.dart';
import '../../../core/api/models/message_type.dart';
import '../services/waveform_processor.dart';
import '../services/text_processor.dart';
import '../services/operator_service.dart';
import '../models/operator_model.dart';
import '../pager_assistant.dart';
import 'pager_state_machine.dart';

/// 拨号页面业务逻辑 Cubit
/// 管理三个状态的转换和业务流程
class PagerCubit extends Cubit<PagerState> {
  final ApiClient _apiClient;
  final PagerAssistant _voiceAssistant;
  final OperatorService _operatorService;
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  // 状态管理
  List<int> _currentWaveformData = [];
  StreamSubscription<double>? _volumeSubscription;

  PagerCubit({
    ApiClient? apiClient,
    PagerAssistant? voiceAssistant,
    OperatorService? operatorService,
  }) : _apiClient = apiClient ?? ApiClient.instance,
       _voiceAssistant = voiceAssistant ?? PagerAssistant(),
       _operatorService = operatorService ?? OperatorService(),
       super(const PagerInitialState());

  /// 初始化拨号准备状态
  Future<void> initializeDialingPrep() async {
    try {
      // 初始化 OperatorService
      await _operatorService.init();

      // 初始化语音助手
      await _voiceAssistant.init();

      // 随机选择一个接线员
      final currentOperator = _operatorService.getRandomOperator();
      logger.i(
        'PagerCubit: 随机选择接线员 - ${currentOperator.name} (${currentOperator.id})',
      );

      emit(DialingPrepState(currentOperator: currentOperator));
    } catch (e) {
      logger.e('Failed to initialize dialing prep: $e');
      emit(PagerErrorState(message: '初始化失败：$e'));
    }
  }

  /// 更新目标 ID
  void updateTargetId(String id) {
    if (state is DialingPrepState) {
      final currentState = state as DialingPrepState;
      emit(currentState.copyWith(targetId: id));
    }
  }

  /// 选择联系人
  void selectContact(String contactId, String contactName) {
    if (state is DialingPrepState) {
      final currentState = state as DialingPrepState;
      emit(
        currentState.copyWith(
          targetId: contactId,
          selectedContactName: contactName,
        ),
      );
    }
  }

  /// 开始拨号 - 转换到通话中状态
  Future<void> startDialing(
    String targetId, {
    String operatorImageUrl = '',
  }) async {
    try {
      if (targetId.isEmpty) {
        emit(PagerErrorState(message: '请输入目标 ID'));
        return;
      }

      logger.i('PagerCubit: 开始拨号流程，目标 ID: $targetId');

      // 获取当前接线员
      OperatorPersonality? currentOperator;
      if (state is DialingPrepState) {
        currentOperator = (state as DialingPrepState).currentOperator;
      }

      // 如果没有接线员，随机选择一个
      currentOperator ??= _operatorService.getRandomOperator();

      // 1. 先检查用户是否存在
      emit(DialingPrepState(isLoading: true, currentOperator: currentOperator));

      try {
        await _apiClient.api.users.getApiUsersUsersBipupuId(bipupuId: targetId);
        logger.i('PagerCubit: 用户存在性检查通过，目标 ID: $targetId');
      } catch (e) {
        // 用户不存在，使用接线员的动态台词
        logger.w('PagerCubit: 用户不存在，目标 ID: $targetId');
        final notFoundText = currentOperator.dialogues.getUserNotFound();
        emit(
          DialingPrepState(isLoading: false, currentOperator: currentOperator),
        );
        emit(PagerErrorState(message: notFoundText));
        return;
      }

      // 2. 用户存在，转换到通话中状态，传递接线员信息
      emit(
        InCallState(
          targetId: targetId,
          operatorImageUrl: operatorImageUrl,
          operator: currentOperator,
        ),
      );

      // 等待 UI 更新，让用户看到通话界面
      await Future.delayed(const Duration(milliseconds: 300));

      // 检查是否仍在通话状态
      if (state is! InCallState) {
        logger.w('PagerCubit: 不在通话状态，停止拨号流程');
        return;
      }

      final inCallState = state as InCallState;

      // 播放问候语（使用 PagerAssistant 的新API）
      logger.i('PagerCubit: 开始播放问候语');
      await _voiceAssistant.greet();

      // 播放提示
      await _voiceAssistant.promptForMessage();

      await Future.delayed(const Duration(seconds: 1));

      logger.i('PagerCubit: 准备启动语音识别');

      // 开始录音识别
      await _startRecordingPhase(inCallState);
    } catch (e) {
      logger.e('Failed to start dialing: $e');
      emit(PagerErrorState(message: '拨号失败：$e'));
    }
  }

  /// 开始录音识别阶段
  Future<void> _startRecordingPhase(InCallState inCallState) async {
    try {
      final userText = await _voiceAssistant.recordAndRecognize(
        maxDuration: Duration(seconds: 30),
        silenceTimeout: Duration(seconds: 5),
        onVolumeChanged: (volume) {
          _waveformProcessor.addVolumeData(volume);
          if (state is InCallState) {
            final current = state as InCallState;
            final waveform = _waveformProcessor.getWaveformFromVolume();
            emit(current.copyWith(waveformData: waveform));
          }
        },
        onInterimResult: (interim) {
          if (state is InCallState) {
            final current = state as InCallState;
            emit(current.copyWith(asrTranscript: interim));
          }
        },
      );

      if (userText.isEmpty) {
        await _voiceAssistant.respond('未检测到输入，请重试');
        await _startRecordingPhase(inCallState);
        return;
      }

      if (state is! InCallState) return;
      final current = state as InCallState;

      // 用户输入识别完成，显示在UI中
      emit(current.copyWith(asrTranscript: userText, isSilenceDetected: true));

      // 播放确认提示
      await _voiceAssistant.respond('我听到了：$userText，请确认');

      // 等待用户确认
      final confirmText = await _voiceAssistant.recordAndRecognize(
        maxDuration: Duration(seconds: 10),
        silenceTimeout: Duration(seconds: 2),
      );

      // 简单的命令识别：包含"确认"、"是"等为确认
      final isConfirmed =
          confirmText.contains('确认') ||
          confirmText.contains('是') ||
          confirmText.contains('好') ||
          confirmText.contains('对');

      if (isConfirmed) {
        // 确认成功，转到最终编辑状态
        await _voiceAssistant.playSuccess('已确认');

        emit(
          FinalizeState(
            targetId: current.targetId,
            messageContent: userText,
            operator: current.operator,
          ),
        );
      } else {
        // 用户否认，返回重新录音
        await _voiceAssistant.respond('已取消，请重新说一遍');
        await _startRecordingPhase(current);
      }
    } catch (e, stackTrace) {
      logger.e('_startRecordingPhase failed', error: e, stackTrace: stackTrace);
      if (state is InCallState) {
        final current = state as InCallState;
        emit(current.copyWith(asrTranscript: '识别失败，请重试'));
      }
    }
  }

  /// 手动结束 ASR 录音（用户点击结束按钮）
  Future<void> finishAsrRecording() async {
    if (state is! InCallState) return;

    final currentState = state as InCallState;
    logger.i('PagerCubit: 用户手动结束录音');

    emit(currentState.copyWith(isSilenceDetected: true));
    await _voiceAssistant.stopRecording();
  }

  /// 发送消息
  Future<void> sendMessage() async {
    try {
      if (state is! FinalizeState) return;

      final finalizeState = state as FinalizeState;

      if (finalizeState.messageContent.isEmpty ||
          finalizeState.messageContent == '请编辑您的消息...') {
        emit(finalizeState.copyWith(sendErrorMessage: '消息内容不能为空'));
        return;
      }

      // 更新状态：发送中
      emit(finalizeState.copyWith(isSending: true));

      // 获取最终的波形数据
      _currentWaveformData = _waveformProcessor.finalize();

      logger.i(
        'Sending message with waveform: ${_currentWaveformData.length} points',
      );

      // 调用 API 发送消息
      await _apiClient.execute(
        () => _apiClient.api.messages.postApiMessages(
          body: MessageCreate(
            receiverId: finalizeState.targetId,
            content: finalizeState.messageContent,
            messageType: MessageType.voice,
            waveform: _currentWaveformData.isEmpty
                ? null
                : _currentWaveformData,
          ),
        ),
        operationName: 'SendMessage',
      );

      // 更新状态：发送成功
      emit(finalizeState.copyWith(isSending: false, sendSuccess: true));

      // 播放成功提示
      emit(finalizeState.copyWith(isPlayingSuccessTts: true));
      await _voiceAssistant.respond('消息已发送，感谢您的使用');
      emit(finalizeState.copyWith(isPlayingSuccessTts: false));

      // 增加接线员对话次数
      if (finalizeState.operator != null) {
        await _operatorService.incrementConversationCount(
          finalizeState.operator!.id,
        );
      }

      // 显示挂断按钮
      emit(finalizeState.copyWith(showHangupButton: true));
    } catch (e) {
      logger.e('Failed to send message: $e');
      if (state is FinalizeState) {
        final finalizeState = state as FinalizeState;
        emit(
          finalizeState.copyWith(isSending: false, sendErrorMessage: '发送失败：$e'),
        );
      }
    }
  }

  /// 开始编辑消息
  void startEditingMessage() {
    if (state is! FinalizeState) return;

    final finalizeState = state as FinalizeState;

    // 处理文本，检查表情符号等
    final textProcessingResult = TextProcessor.processText(
      finalizeState.messageContent,
    );

    emit(
      finalizeState.copyWith(
        isEditing: true,
        textProcessingResult: textProcessingResult,
      ),
    );
  }

  /// 取消编辑消息
  void cancelEditingMessage() {
    if (state is! FinalizeState) return;

    final finalizeState = state as FinalizeState;
    emit(finalizeState.copyWith(isEditing: false));
  }

  /// 更新编辑中的消息内容
  void updateEditingMessage(String content) {
    if (state is! FinalizeState) return;

    final finalizeState = state as FinalizeState;

    // 处理文本，检查表情符号等
    final textProcessingResult = TextProcessor.processText(content);

    emit(
      finalizeState.copyWith(
        messageContent: content,
        textProcessingResult: textProcessingResult,
      ),
    );
  }

  /// 完成编辑消息
  void finishEditingMessage() {
    if (state is! FinalizeState) return;

    final finalizeState = state as FinalizeState;
    emit(finalizeState.copyWith(isEditing: false));
  }

  /// 挂断 - 返回拨号准备状态
  Future<void> hangup() async {
    logger.i('PagerCubit: 挂断通话');

    try {
      // 停止录音和清理资源
      await _voiceAssistant.stopRecording();

      // 清理波形处理器
      _waveformProcessor.clear();

      // 返回初始状态
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to hangup: $e');
      emit(PagerErrorState(message: '挂断失败：$e'));
    }
  }

  /// 取消拨号
  Future<void> cancelDialing() async {
    logger.i('PagerCubit: 取消拨号');

    try {
      await _voiceAssistant.stopRecording();
      _waveformProcessor.clear();
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to cancel dialing: $e');
      emit(PagerErrorState(message: '取消拨号失败：$e'));
    }
  }

  @override
  Future<void> close() async {
    try {
      await _voiceAssistant.stopRecording();
      _waveformProcessor.clear();
      _volumeSubscription?.cancel();
      _voiceAssistant.dispose();
    } catch (e) {
      logger.e('Error closing PagerCubit', error: e);
    }
    return super.close();
  }
}
