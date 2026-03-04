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

  // 限制接线员台词历史长度，防止无限增长
  List<String> _appendSpeechHistory(
    List<String> existing,
    String newEntry, [
    int max = 50,
  ]) {
    final list = [...existing, newEntry];
    if (list.length <= max) return list;
    return list.sublist(list.length - max);
  }

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

      // ✅ 更新 PagerAssistant 的接线员（音色、语速）
      _voiceAssistant.updateOperator(currentOperator);

      // 等待 UI 更新，让用户看到通话界面
      await Future.delayed(const Duration(milliseconds: 300));

      // 检查是否仍在通话状态
      if (state is! InCallState) {
        logger.w('PagerCubit: 不在通话状态，停止拨号流程');
        return;
      }

      // ✅ 修复核心：先获取台词文本并立即更新 UI，再播放 TTS
      // 原来的 await greet() 会阻塞直到 TTS 播完才更新状态导致 UI 永远显示“准备中”
      logger.i('PagerCubit: 开始问候流程');

      // ① 立即获取问候语文本
      final greetingText = currentOperator.dialogues.getGreeting();
      if (state is InCallState) {
        var cs = state as InCallState;
        cs = cs.copyWith(
          operatorCurrentSpeech: greetingText,
          operatorSpeechHistory: _appendSpeechHistory(
            cs.operatorSpeechHistory,
            greetingText,
          ),
        );
        logger.i('PagerCubit: 问候语已更新 UI: "$greetingText"');
        emit(cs); // ✅ 先更新 UI
      }

      // ① 然后播放 TTS（状态已经更新，用户已看到台词）
      await _voiceAssistant.respond(greetingText);

      if (state is! InCallState) return;

      // ② 短暂延时后显示提示语
      await Future.delayed(const Duration(milliseconds: 300));

      final promptText = currentOperator.dialogues.getRequestMessage();
      if (state is InCallState) {
        var cs = state as InCallState;
        cs = cs.copyWith(
          operatorCurrentSpeech: promptText,
          operatorSpeechHistory: _appendSpeechHistory(
            cs.operatorSpeechHistory,
            promptText,
          ),
          // ✅ Bug 6 修复: 不在此处设置 isWaitingForUserInput=true
          // TTS 播完之前设置会导致声纹特效条提前出现
          // _startRecordingPhase 内部会在适当时机设置
        );
        logger.i('PagerCubit: 提示语已更新 UI: "$promptText"');
        emit(cs); // ✅ 先更新 UI
      }

      // ② 然后播放提示语 TTS（TTS 播完即开始录音）
      await _voiceAssistant.respond(promptText);

      if (state is! InCallState) return;

      logger.i('PagerCubit: 准备启动语音识别');

      // 开始录音识别
      await _startRecordingPhase(state as InCallState);
    } catch (e) {
      logger.e('Failed to start dialing: $e');
      emit(PagerErrorState(message: '拨号失败：$e'));
    }
  }

  /// 开始录音识别阶段
  Future<void> _startRecordingPhase(
    InCallState inCallState, {
    int retryCount = 0, // ✅ Bug 4 修复: 记录重试次数防止无限递归
  }) async {
    const maxRetries = 3;
    try {
      var currentState = inCallState;

      // ✅ Bug 2 修复: 每轮录音开始前清除波形处理器，防止跨轮数据累积
      _waveformProcessor.clear();

      // 更新状态：开始录音
      currentState = currentState.copyWith(
        isWaitingForUserInput: true,
        waveformData: [],
        asrTranscript: '',
        isSilenceDetected: false,
      );
      emit(currentState);

      final userText = await _voiceAssistant.recordAndRecognize(
        maxDuration: const Duration(seconds: 30),
        silenceTimeout: const Duration(seconds: 5),
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
        // ✅ Bug 4 修复: 超过最大重试次数则放弃
        if (retryCount >= maxRetries) {
          logger.w('PagerCubit: 连续 $maxRetries 次未识别到输入，结束通话');
          if (state is InCallState) {
            final cs = state as InCallState;
            final giveUpText =
                cs.operator?.dialogues.getUserNotFound() ?? '抱歉，未能识别您的语音，请稍后重试';
            emit(
              cs.copyWith(
                operatorCurrentSpeech: giveUpText,
                operatorSpeechHistory: _appendSpeechHistory(
                  cs.operatorSpeechHistory,
                  giveUpText,
                ),
                isWaitingForUserInput: false,
              ),
            );
            await _voiceAssistant.respond(giveUpText);
          }
          await Future.delayed(const Duration(milliseconds: 800));
          emit(const DialingPrepState()); // 返回拨号准备页
          return;
        }

        // 未检测到输入，播放提示并重试
        final retryText =
            (state as InCallState).operator?.dialogues.getRandomPhrase() ??
            '未检测到输入，请重试';

        // ✅ 先更新 UI 显示重试台词
        if (state is InCallState) {
          currentState = state as InCallState;
          currentState = currentState.copyWith(
            operatorCurrentSpeech: retryText,
            operatorSpeechHistory: _appendSpeechHistory(
              currentState.operatorSpeechHistory,
              retryText,
            ),
            asrTranscript: '',
            waveformData: [],
            isWaitingForUserInput: false,
          );
          emit(currentState);
        }

        // ✅ 再播放 TTS
        await _voiceAssistant.respond(retryText);

        await Future.delayed(const Duration(milliseconds: 500));
        if (state is InCallState) {
          await _startRecordingPhase(
            state as InCallState,
            retryCount: retryCount + 1,
          );
        }
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

      // ✅ 先更新 UI
      if (state is InCallState) {
        currentState = state as InCallState;
        currentState = currentState.copyWith(
          operatorCurrentSpeech: confirmPrompt,
          operatorSpeechHistory: _appendSpeechHistory(
            currentState.operatorSpeechHistory,
            confirmPrompt,
          ),
        );
        emit(currentState);
      }

      // ✅ 再播放 TTS
      await _voiceAssistant.respond(confirmPrompt);

      if (state is! InCallState) return;

      // ✅ Bug 3 修复: 确认轮录音前重置 UI 状态，让声纹特效条重新激活
      _waveformProcessor.clear();
      if (state is InCallState) {
        emit(
          (state as InCallState).copyWith(
            isWaitingForUserInput: true,
            waveformData: [],
            isSilenceDetected: false,
          ),
        );
      }

      final confirmText = await _voiceAssistant.recordAndRecognize(
        maxDuration: const Duration(seconds: 10),
        silenceTimeout: const Duration(seconds: 2),
        onVolumeChanged: (volume) {
          _waveformProcessor.addVolumeData(volume);
          if (state is InCallState) {
            final current = state as InCallState;
            emit(
              current.copyWith(
                waveformData: _waveformProcessor.getWaveformFromVolume(),
              ),
            );
          }
        },
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
        // ✅ 确认成功，先获取成功台词并更新 UI，再播放 TTS
        final successText =
            currentState.operator?.dialogues.getSuccessMessage() ?? '已完成';

        if (state is InCallState) {
          currentState = state as InCallState;
          emit(
            currentState.copyWith(
              operatorCurrentSpeech: successText,
              operatorSpeechHistory: _appendSpeechHistory(
                currentState.operatorSpeechHistory,
                successText,
              ),
            ),
          ); // ✅ 先更新 UI
        }

        await _voiceAssistant.respond(successText); // ✅ 再播放 TTS

        await Future.delayed(const Duration(milliseconds: 400));

        if (state is InCallState) {
          final cs = state as InCallState;
          emit(
            FinalizeState(
              targetId: cs.targetId,
              messageContent: userText,
              operator: cs.operator,
              operatorSpeechHistory: cs.operatorSpeechHistory,
            ),
          );
        }
      } else {
        // ✅ 用户否认，先更新 UI 再播放 TTS
        final cancelText =
            currentState.operator?.dialogues.getRandomPhrase() ?? '已取消，请重新说一遍';

        if (state is InCallState) {
          currentState = state as InCallState;
          currentState = currentState.copyWith(
            asrTranscript: '',
            operatorCurrentSpeech: cancelText,
            operatorSpeechHistory: _appendSpeechHistory(
              currentState.operatorSpeechHistory,
              cancelText,
            ),
            waveformData: [],
            isSilenceDetected: false,
          );
          emit(currentState); // ✅ 先更新 UI
        }

        await _voiceAssistant.respond(cancelText); // ✅ 再播放 TTS

        await Future.delayed(const Duration(milliseconds: 500));
        if (state is InCallState) {
          // ✅ Bug 4 修复: 传递 retryCount+1
          await _startRecordingPhase(
            state as InCallState,
            retryCount: retryCount + 1,
          );
        }
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
            operatorSpeechHistory: _appendSpeechHistory(
              current.operatorSpeechHistory,
              errorText,
            ),
          ),
        );
      }
    }
  }

  /// 手动结束 ASR 录音（用户点击结束按钮）
  void finishAsrRecording() {
    if (state is! InCallState) return;
    logger.i('PagerCubit: 用户手动结束录音');
    // ✅ Bug 1 修复: 仅发送停止信号，不直接调用 stopRecording()
    // 原来的实现会导致双重 stopRecording: 此处调一次、recordAndRecognize 里再调一次
    // 第二次调用返回 '' 使得最终识别文本丢失
    // 现在只发信号，recordAndRecognize 自行调用 stopRecording 并正确传递最终文本到 _startRecordingPhase
    _voiceAssistant.signalStop();
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
        // ✅ 发送成功
        emit(finalizeState.copyWith(isSending: false, sendSuccess: true));

        // ✅ Bug 5 修复: 先获取成功台词并更新 UI，再播放 TTS
        final successText =
            finalizeState.operator?.dialogues.getSuccessMessage() ?? '已完成';
        finalizeState = finalizeState.copyWith(
          isPlayingSuccessTts: true,
          operatorSpeechHistory: _appendSpeechHistory(
            finalizeState.operatorSpeechHistory,
            successText,
          ),
        );
        emit(finalizeState); // ✅ 先显示台词
        await _voiceAssistant.respond(successText); // ✅ 再播放 TTS

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
