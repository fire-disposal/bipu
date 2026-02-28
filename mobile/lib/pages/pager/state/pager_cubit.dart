import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/api/models/message_create.dart';
import '../../../core/api/models/message_type.dart';
import '../services/waveform_processor.dart';
import '../services/text_processor.dart';
import '../coordination/voice_interaction_coordinator.dart';
import 'pager_state_machine.dart';

/// 拨号页面业务逻辑 Cubit
/// 管理三个状态的转换和业务流程
class PagerCubit extends Cubit<PagerState> {
  final ApiClient _apiClient;
  final VoiceInteractionCoordinator _voiceCoordinator;
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  // 状态管理
  List<int> _currentWaveformData = [];

  // 协调器事件订阅
  StreamSubscription<String>? _transcriptSubscription;
  StreamSubscription<List<double>>? _waveformSubscription;
  StreamSubscription<void>? _recordingEndedSubscription;

  PagerCubit({
    ApiClient? apiClient,
    VoiceInteractionCoordinator? voiceCoordinator,
  }) : _apiClient = apiClient ?? ApiClient.instance,
       _voiceCoordinator = voiceCoordinator ?? VoiceInteractionCoordinator(),
       super(const PagerInitialState());

  /// 初始化拨号准备状态
  Future<void> initializeDialingPrep() async {
    try {
      await _voiceCoordinator.initialize();
      emit(const DialingPrepState());
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

  /// 设置语音协调器订阅
  void _setupVoiceCoordinatorSubscriptions() {
    // 清理旧的订阅
    _transcriptSubscription?.cancel();
    _waveformSubscription?.cancel();
    _recordingEndedSubscription?.cancel();

    // 订阅转录结果
    _transcriptSubscription = _voiceCoordinator.onTranscript.listen((
      transcript,
    ) {
      if (state is InCallState) {
        final currentState = state as InCallState;
        emit(currentState.copyWith(asrTranscript: transcript));
      }
    });

    // 订阅波形数据
    _waveformSubscription = _voiceCoordinator.onWaveform.listen((waveform) {
      if (state is InCallState) {
        final currentState = state as InCallState;
        emit(currentState.copyWith(waveformData: waveform));
      }
    });

    // 订阅录音结束事件（传递最终转录文本）
    _recordingEndedSubscription = _voiceCoordinator.onRecordingEnded.listen((
      finalTranscript,
    ) {
      _handleRecordingCompleted(finalTranscript);
    });
  }

  /// 处理录音完成
  Future<void> _handleRecordingCompleted(String finalTranscript) async {
    logger.i('PagerCubit: 录音完成，转换到最终状态，转录文本: "$finalTranscript"');

    // 清理订阅
    await _cleanupSubscriptions();

    // 转换到 Finalize 状态
    if (state is InCallState) {
      final inCallState = state as InCallState;
      emit(
        FinalizeState(
          targetId: inCallState.targetId,
          messageContent: finalTranscript.isNotEmpty
              ? finalTranscript
              : '请编辑您的消息...',
        ),
      );
    }
  }

  /// 清理订阅
  Future<void> _cleanupSubscriptions() async {
    await _transcriptSubscription?.cancel();
    await _waveformSubscription?.cancel();
    await _recordingEndedSubscription?.cancel();

    _transcriptSubscription = null;
    _waveformSubscription = null;
    _recordingEndedSubscription = null;
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

      logger.i('PagerCubit: 开始拨号流程，目标ID: $targetId');

      // 转换到通话中状态
      emit(InCallState(targetId: targetId, operatorImageUrl: operatorImageUrl));

      // 等待UI更新，让用户看到通话界面
      await Future.delayed(const Duration(milliseconds: 300));

      // 检查是否仍在通话状态
      if (state is! InCallState) {
        logger.w('PagerCubit: 不在通话状态，停止拨号流程');
        return;
      }

      final inCallState = state as InCallState;

      // 播放引导台词
      logger.i('PagerCubit: 开始播放引导TTS');
      final guidanceText = '您好，请说出您要传达的消息';

      // 更新状态：TTS 播放中，暂停 ASR，并立即将台词添加到历史记录
      emit(
        inCallState.copyWith(
          currentTtsText: guidanceText,
          isTtsPlaying: true,
          operatorSpeechHistory: [
            ...inCallState.operatorSpeechHistory,
            guidanceText,
          ],
        ),
      );

      // 播放引导TTS
      await _voiceCoordinator.playGuidance(guidanceText);

      // TTS播放完成，更新状态
      emit(
        inCallState.copyWith(currentTtsText: guidanceText, isTtsPlaying: false),
      );

      // 给用户一点时间阅读和准备
      logger.i('PagerCubit: TTS播放完成，等待用户准备');
      await Future.delayed(const Duration(seconds: 1));

      logger.i('PagerCubit: 准备启动ASR语音转写');

      // 设置转录监听
      _setupVoiceCoordinatorSubscriptions();

      // 启动录音
      await _voiceCoordinator.startRecording();
    } catch (e) {
      logger.e('Failed to start dialing: $e');
      emit(PagerErrorState(message: '拨号失败：$e'));
    }
  }

  /// 手动结束 ASR 录音（用户点击结束按钮）
  /// 与静默检测并行生效，用户可随时点击结束按钮
  Future<void> finishAsrRecording() async {
    if (state is! InCallState) return;

    final currentState = state as InCallState;

    logger.i('PagerCubit: 用户手动结束录音');

    // 更新状态：显示结束录音的视觉反馈
    emit(currentState.copyWith(isSilenceDetected: true));

    // 等待一小段时间让用户看到状态变化
    await Future.delayed(const Duration(milliseconds: 500));

    // 通过协调器停止录音并获取最终转录文本
    final finalTranscript = await _voiceCoordinator.stopRecording();

    // 清理订阅（协调器的录音结束事件也会触发，但这里直接处理）
    await _cleanupSubscriptions();

    // 转换到 Finalize 状态
    emit(
      FinalizeState(
        targetId: currentState.targetId,
        messageContent: finalTranscript.isNotEmpty
            ? finalTranscript
            : '请编辑您的消息...',
      ),
    );
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

      // 验证波形数据
      if (!WaveformValidator.isValid(_currentWaveformData)) {
        logger.w('Waveform data is invalid, sending without waveform');
        _currentWaveformData = [];
      }

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

      // 播放成功 TTS
      emit(finalizeState.copyWith(isPlayingSuccessTts: true));
      await _voiceCoordinator.playSuccessTts('消息已发送，感谢您的使用');
      emit(finalizeState.copyWith(isPlayingSuccessTts: false));

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
      // 使用协调器取消所有语音交互
      await _voiceCoordinator.cancelAll();

      // 清理本地订阅
      await _cleanupSubscriptions();

      // 清理波形处理器
      _waveformProcessor.clear();

      // 返回初始状态
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to hangup: $e');
      emit(PagerErrorState(message: '挂断失败：$e'));
    }
  }

  /// 取消当前操作
  /// 取消拨号 - 返回拨号准备状态
  Future<void> cancelDialing() async {
    logger.i('PagerCubit: 取消拨号');

    try {
      // 使用协调器取消所有语音交互
      await _voiceCoordinator.cancelAll();

      // 清理本地订阅
      await _cleanupSubscriptions();

      // 清理波形处理器
      _waveformProcessor.clear();

      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to cancel dialing: $e');
      emit(PagerErrorState(message: '取消拨号失败：$e'));
    }
  }

  @override
  Future<void> close() async {
    // 使用协调器取消所有语音交互
    await _voiceCoordinator.cancelAll();

    // 清理本地订阅
    await _cleanupSubscriptions();

    // 清理波形处理器
    _waveformProcessor.clear();

    // 释放协调器资源
    await _voiceCoordinator.dispose();

    return super.close();
  }
}
