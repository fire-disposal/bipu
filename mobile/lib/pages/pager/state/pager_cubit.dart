import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/im_service.dart';
import '../../../core/utils/logger.dart';
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
  final ImService _imService;
  final PagerAssistant _voiceAssistant;
  final OperatorService _operatorService;
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  // 状态管理
  List<int> _currentWaveformData = [];
  StreamSubscription<double>? _volumeSubscription;

  PagerCubit({
    ApiClient? apiClient,
    ImService? imService,
    PagerAssistant? voiceAssistant,
    OperatorService? operatorService,
  }) : _apiClient = apiClient ?? ApiClient.instance,
       _imService = imService ?? ImService(),
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

      // ✅ 播放问候语并更新 UI（即使 TTS 失败也会返回文本）
      logger.i('PagerCubit: 开始播放问候语');
      final greetingText = await _voiceAssistant.greet();

      if (state is InCallState) {
        var currentState = state as InCallState;
        currentState = currentState.copyWith(
          operatorCurrentSpeech: greetingText,
          operatorSpeechHistory: [
            ...currentState.operatorSpeechHistory,
            greetingText,
          ],
        );
        emit(currentState);

        // 短暂延时让用户看到问候语
        await Future.delayed(const Duration(milliseconds: 600));

        // ✅ 播放提示语并更新 UI
        final promptText = await _voiceAssistant.promptForMessage();
        currentState = currentState.copyWith(
          operatorCurrentSpeech: promptText,
          operatorSpeechHistory: [
            ...currentState.operatorSpeechHistory,
            promptText,
          ],
          isWaitingForUserInput: true,
        );
        emit(currentState);

        logger.i('PagerCubit: 准备启动语音识别');

        // 等待用户开始输入
        await Future.delayed(const Duration(milliseconds: 500));

        // 开始录音识别
        await _startRecordingPhase(currentState);
      }
    } catch (e) {
      logger.e('Failed to start dialing: $e');
      emit(PagerErrorState(message: '拨号失败：$e'));
    }
  }

  /// 开始录音识别阶段
  Future<void> _startRecordingPhase(InCallState inCallState) async {
    try {
      var currentState = inCallState;

      // 更新状态：开始录音
      currentState = currentState.copyWith(isWaitingForUserInput: true);
      emit(currentState);

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
        // 未检测到输入，播放提示并重试
        final retryText =
            currentState.operator?.dialogues.getRandomPhrase() ?? '未检测到输入，请重试';
        await _voiceAssistant.respond(retryText);

        if (state is InCallState) {
          currentState = state as InCallState;
          currentState = currentState.copyWith(
            operatorCurrentSpeech: retryText,
            operatorSpeechHistory: [
              ...currentState.operatorSpeechHistory,
              retryText,
            ],
            asrTranscript: '',
            waveformData: [],
          );
          emit(currentState);
        }

        await Future.delayed(const Duration(milliseconds: 800));
        await _startRecordingPhase(currentState);
        return;
      }

      if (state is! InCallState) return;
      currentState = state as InCallState;

      // ✅ 用户输入识别完成，显示在 UI 中
      currentState = currentState.copyWith(
        asrTranscript: userText,
        isSilenceDetected: true,
        isWaitingForUserInput: false,
      );
      emit(currentState);

      // ✅ 播放确认提示
      final confirmPrompt = '我听到了：$userText，请确认';
      await _voiceAssistant.respond(confirmPrompt);

      if (state is InCallState) {
        currentState = state as InCallState;
        currentState = currentState.copyWith(
          operatorCurrentSpeech: confirmPrompt,
          operatorSpeechHistory: [
            ...currentState.operatorSpeechHistory,
            confirmPrompt,
          ],
        );
        emit(currentState);
      }

      // 等待用户确认
      await Future.delayed(const Duration(milliseconds: 500));

      final confirmText = await _voiceAssistant.recordAndRecognize(
        maxDuration: Duration(seconds: 10),
        silenceTimeout: Duration(seconds: 2),
      );

      if (state is! InCallState) return;
      currentState = state as InCallState;

      // 简单的命令识别：包含"确认"、"是"等为确认
      final isConfirmed =
          confirmText.contains('确认') ||
          confirmText.contains('是') ||
          confirmText.contains('好') ||
          confirmText.contains('对');

      if (isConfirmed) {
        // ✅ 确认成功，播放成功提示并转到最终编辑状态
        final successText = await _voiceAssistant.playSuccess('');

        // 短暂延时让用户听到成功提示
        await Future.delayed(const Duration(milliseconds: 800));

        // ✅ 更新提示词历史并转移
        final updatedHistory = [
          ...currentState.operatorSpeechHistory,
          successText,
        ];

        emit(
          FinalizeState(
            targetId: currentState.targetId,
            messageContent: userText,
            operator: currentState.operator,
            operatorSpeechHistory: updatedHistory,
          ),
        );
      } else {
        // ✅ 用户否认，播放取消提示并返回重新录音
        final cancelText =
            currentState.operator?.dialogues.getRandomPhrase() ?? '已取消，请重新说一遍';
        await _voiceAssistant.respond(cancelText);

        if (state is InCallState) {
          currentState = state as InCallState;
          currentState = currentState.copyWith(
            asrTranscript: '',
            operatorCurrentSpeech: cancelText,
            operatorSpeechHistory: [
              ...currentState.operatorSpeechHistory,
              cancelText,
            ],
            waveformData: [],
          );
          emit(currentState);
        }

        await Future.delayed(const Duration(milliseconds: 800));
        await _startRecordingPhase(currentState);
      }
    } catch (e, stackTrace) {
      logger.e('_startRecordingPhase failed', error: e, stackTrace: stackTrace);
      if (state is InCallState) {
        final current = state as InCallState;
        final errorText = '识别出错，请稍后重试';
        emit(
          current.copyWith(
            asrTranscript: errorText,
            operatorCurrentSpeech: errorText,
            operatorSpeechHistory: [
              ...current.operatorSpeechHistory,
              errorText,
            ],
          ),
        );
      }
    }
  }

  /// 手动结束 ASR 录音（用户点击结束按钮）
  Future<void> finishAsrRecording() async {
    if (state is! InCallState) return;

    final currentState = state as InCallState;
    logger.i('PagerCubit: 用户手动结束录音');

    emit(
      currentState.copyWith(
        isSilenceDetected: true,
        isWaitingForUserInput: false,
      ),
    );
    await _voiceAssistant.stopRecording();
  }

  /// 发送消息（支持接线员台词历史传递）
  Future<void> sendMessage() async {
    try {
      if (state is! FinalizeState) return;

      var finalizeState = state as FinalizeState;

      if (finalizeState.messageContent.isEmpty ||
          finalizeState.messageContent == '请编辑您的消息...') {
        emit(finalizeState.copyWith(sendErrorMessage: '消息内容不能为空'));
        return;
      }

      // ✅ 更新状态：发送中
      emit(finalizeState.copyWith(isSending: true));

      // 获取最终的波形数据
      _currentWaveformData = _waveformProcessor.finalize();

      logger.i(
        'PagerCubit: 发送消息 - 内容: "${finalizeState.messageContent}", 波形点数: ${_currentWaveformData.length}',
      );

      // 使用新的统一接口发送消息
      final result = await _imService.sendMessage(
        receiverId: finalizeState.targetId,
        content: finalizeState.messageContent,
        messageType: 'VOICE',
        waveform: _currentWaveformData.isEmpty ? null : _currentWaveformData,
      );

      if (result != null) {
        // ✅ 发送成功 - 播放成功提示
        emit(finalizeState.copyWith(isSending: false, sendSuccess: true));

        // 播放接线员的成功台词
        emit(finalizeState.copyWith(isPlayingSuccessTts: true));
        final successText = await _voiceAssistant.playSuccess('');

        // 更新接线员台词历史
        finalizeState = finalizeState.copyWith(
          operatorSpeechHistory: [
            ...finalizeState.operatorSpeechHistory,
            successText,
          ],
        );

        emit(finalizeState.copyWith(isPlayingSuccessTts: false));

        logger.i('PagerCubit: 消息发送成功');

        // ✅ 增加接线员对话次数
        if (finalizeState.operator != null) {
          await _operatorService.incrementConversationCount(
            finalizeState.operator!.id,
          );
          logger.i('PagerCubit: 接线员对话计数已增加 - ${finalizeState.operator!.name}');
        }

        // ✅ 短暂延时后显示挂断按钮
        await Future.delayed(const Duration(milliseconds: 800));
        emit(finalizeState.copyWith(showHangupButton: true));
      } else {
        // 发送失败
        logger.w('PagerCubit: 消息发送失败');
        emit(
          finalizeState.copyWith(
            isSending: false,
            sendErrorMessage: '发送失败，请重试',
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Failed to send message', error: e, stackTrace: stackTrace);
      if (state is FinalizeState) {
        final finalizeState = state as FinalizeState;
        emit(
          finalizeState.copyWith(isSending: false, sendErrorMessage: '发送异常：$e'),
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

  /// ✅ 挂断 - 返回拨号准备状态，进行资源清理
  Future<void> hangup() async {
    logger.i('PagerCubit: 用户挂断通话');

    try {
      // 停止录音
      await _voiceAssistant.stopRecording();

      // 清理波形处理器和音量订阅
      _waveformProcessor.clear();
      await _volumeSubscription?.cancel();
      _currentWaveformData.clear();

      logger.i('PagerCubit: 资源已清理');

      // 返回初始状态
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to hangup', error: e);
      emit(PagerErrorState(message: '挂断失败：$e'));
    }
  }

  /// ✅ 取消拨号 - 进行资源清理
  Future<void> cancelDialing() async {
    logger.i('PagerCubit: 用户取消拨号');

    try {
      // 停止所有进行中的操作
      await _voiceAssistant.stopRecording();

      // 清理资源
      _waveformProcessor.clear();
      await _volumeSubscription?.cancel();
      _currentWaveformData.clear();

      logger.i('PagerCubit: 拨号已取消，资源已清理');

      // 返回拨号准备状态
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to cancel dialing', error: e);
      emit(PagerErrorState(message: '取消拨号失败：$e'));
    }
  }

  /// ✅ 销毁 Cubit 时清理资源
  @override
  Future<void> close() async {
    logger.i('PagerCubit: 正在清理资源...');
    try {
      await _voiceAssistant.stopRecording();
      await _voiceAssistant.dispose();
      await _volumeSubscription?.cancel();
      _waveformProcessor.clear();
      _currentWaveformData.clear();
      logger.i('PagerCubit: 资源清理完成');
    } catch (e) {
      logger.e('Error during close', error: e);
    }
    return super.close();
  }

  /// ✅ 获取接线员信息（用于诊断和调试）
  OperatorPersonality? getCurrentOperator() {
    if (state is DialingPrepState) {
      return (state as DialingPrepState).currentOperator;
    } else if (state is InCallState) {
      return (state as InCallState).operator;
    } else if (state is FinalizeState) {
      return (state as FinalizeState).operator;
    }
    return null;
  }

  /// ✅ 获取当前对话历史（用于调试）
  List<String> getOperatorSpeechHistory() {
    if (state is InCallState) {
      return (state as InCallState).operatorSpeechHistory;
    } else if (state is FinalizeState) {
      return (state as FinalizeState).operatorSpeechHistory;
    }
    return [];
  }
}
