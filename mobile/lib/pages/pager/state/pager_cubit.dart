import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/voice/voice_service.dart';
import '../../../core/voice/asr_engine.dart';
import '../../../core/utils/logger.dart';
import '../../../core/api/models/message_create.dart';
import '../../../core/api/models/message_type.dart';
import '../services/waveform_processor.dart';
import '../services/text_processor.dart';
import 'pager_state_machine.dart';

/// 拨号页面业务逻辑 Cubit
/// 管理三个状态的转换和业务流程
class PagerCubit extends Cubit<PagerState> {
  final ApiClient _apiClient;
  final VoiceService _voiceService;
  final ASREngine _asrEngine;

  // 音频录制相关
  bool _isRecording = false;
  bool _isStoppingAsr = false;
  StreamSubscription<String>? _asrResultSubscription;
  StreamSubscription<double>? _asrVolumeSubscription;

  // 波形处理
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  // 状态管理
  String _currentTargetId = '';
  String _currentMessageContent = '';
  List<int> _currentWaveformData = [];

  PagerCubit({
    ApiClient? apiClient,
    VoiceService? voiceService,
    ASREngine? asrEngine,
  }) : _apiClient = apiClient ?? ApiClient.instance,
       _voiceService = voiceService ?? VoiceService(),
       _asrEngine = asrEngine ?? ASREngine(),
       super(const PagerInitialState());

  /// 初始化拨号准备状态
  Future<void> initializeDialingPrep() async {
    try {
      await _voiceService.init();
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
      _currentTargetId = id;
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
      _currentTargetId = contactId;
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

      _currentTargetId = targetId;

      // 转换到通话中状态
      emit(InCallState(targetId: targetId, operatorImageUrl: operatorImageUrl));

      // 播放引导台词
      await _playGuidanceTts();

      // 启动 ASR 语音转写
      await _startAsrTranscription();
    } catch (e) {
      logger.e('Failed to start dialing: $e');
      emit(PagerErrorState(message: '拨号失败：$e'));
    }
  }

  /// 播放引导台词 (TTS)
  /// TTS 播放期间会暂停 ASR 录音，防止录入接线员自己的声音
  Future<void> _playGuidanceTts() async {
    try {
      if (state is! InCallState) return;

      final guidanceText = '您好，请说出您要传达的消息';

      // 更新状态：TTS 播放中，暂停 ASR
      final currentState = state as InCallState;
      emit(
        currentState.copyWith(
          currentTtsText: guidanceText,
          isTtsPlaying: true,
          isAsrActive: false,
        ),
      );

      // 播放 TTS
      await _voiceService.speak(guidanceText, sid: 0, speed: 1.0);

      // TTS 播放完成，恢复 ASR 录音
      emit(currentState.copyWith(isTtsPlaying: false, isAsrActive: true));
    } catch (e) {
      logger.e('Failed to play guidance TTS: $e');
    }
  }

  /// 启动 ASR 语音转写
  /// 如果 TTS 正在播放，会等待 TTS 完成后再启动 ASR
  Future<void> _startAsrTranscription() async {
    try {
      if (state is! InCallState) return;

      final currentState = state as InCallState;

      // 如果 TTS 正在播放，等待 TTS 完成
      if (currentState.isTtsPlaying) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          final state = this.state;
          return state is InCallState && state.isTtsPlaying;
        });
      }

      // 更新状态：ASR 激活
      emit(currentState.copyWith(isAsrActive: true));

      // 给用户一点反应时间（1秒）
      await Future.delayed(const Duration(seconds: 1));

      // 初始化 ASR 引擎
      await _asrEngine.init();

      // 开始真实 ASR 录音
      await _asrEngine.startRecording();

      _isRecording = true;

      // 监听 ASR 结果
      _asrResultSubscription = _asrEngine.onResult.listen((transcript) {
        if (state is InCallState) {
          final currentState = state as InCallState;
          emit(
            currentState.copyWith(
              asrTranscript: transcript,
              waveformData: _generateWaveformFromVolume(),
            ),
          );

          // 如果检测到用户说了内容，自动设置静默检测
          if (transcript.isNotEmpty && transcript != '检测到长时间静默，请说话...') {
            // 延迟1秒后检测静默
            Future.delayed(const Duration(seconds: 1), () {
              if (_isRecording && state is InCallState) {
                final updatedState = state as InCallState;
                if (updatedState.asrTranscript == transcript) {
                  // 用户停止说话，检测到静默
                  emit(updatedState.copyWith(isSilenceDetected: true));

                  // 自动结束录音
                  Future.delayed(const Duration(milliseconds: 500), () {
                    finishAsrRecording();
                  });
                }
              }
            });
          }
        }
      });

      // 监听音量数据用于波形显示
      _asrVolumeSubscription = _asrEngine.onVolume.listen((volume) {
        _waveformProcessor.addVolumeData(volume);
      });

      // 设置超时，如果用户长时间不说话，自动结束
      _setupAsrTimeout();
    } catch (e) {
      logger.e('Failed to start ASR transcription: $e');
      emit(PagerErrorState(message: 'ASR 启动失败：$e'));
    }
  }

  /// 设置 ASR 超时检测
  void _setupAsrTimeout() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_isRecording && state is InCallState) {
        final currentState = state as InCallState;
        if (currentState.asrTranscript.isEmpty) {
          // 用户长时间没有说话，显示提示
          emit(
            currentState.copyWith(
              asrTranscript: '检测到长时间静默，请说话...',
              showEmojiWarning: true,
            ),
          );
        }
      }
    });
  }

  /// 从音量数据生成波形
  List<double> _generateWaveformFromVolume() {
    return _waveformProcessor.getWaveformFromVolume();
  }

  /// 停止 ASR 并转换到 Finalize 状态
  Future<void> _stopAsrAndFinalize() async {
    // 防止重复调用
    if (_isStoppingAsr) {
      logger.w('⚠️  PagerCubit: 已经在停止ASR过程中，跳过重复调用');
      return;
    }

    _isStoppingAsr = true;

    try {
      _isRecording = false;

      // 停止 ASR 录音并获取最终结果
      String transcript = '';
      try {
        transcript = await _asrEngine.stop();
      } catch (e) {
        logger.e('❌ 停止ASR录音时出错: $e');
        transcript = '';
      }

      // 取消订阅
      await _asrResultSubscription?.cancel();
      await _asrVolumeSubscription?.cancel();
      _asrResultSubscription = null;
      _asrVolumeSubscription = null;

      _currentMessageContent = transcript;

      // 获取最终的波形数据用于 UI 显示
      final currentWaveform = _waveformProcessor.getCurrentWaveform();
      logger.i('Current waveform points: ${currentWaveform.length}');

      if (state is InCallState) {
        final inCallState = state as InCallState;

        // 转换到 Finalize 状态
        emit(
          FinalizeState(
            targetId: inCallState.targetId,
            messageContent: transcript.isNotEmpty ? transcript : '请编辑您的消息...',
          ),
        );
      }
    } catch (e) {
      logger.e('Failed to stop ASR: $e');
    }
  }

  /// 手动结束 ASR 录音（用户点击结束按钮）
  Future<void> finishAsrRecording() async {
    if (state is! InCallState) return;

    final currentState = state as InCallState;

    // 更新状态：检测到静默
    emit(currentState.copyWith(isSilenceDetected: true));

    // 等待一小段时间让用户看到状态变化
    await Future.delayed(const Duration(milliseconds: 500));

    // 停止 ASR 并转换到 Finalize 状态
    await _stopAsrAndFinalize();
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
      await _playSuccessTts();

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

  /// 播放成功 TTS
  Future<void> _playSuccessTts() async {
    try {
      if (state is! FinalizeState) return;

      final finalizeState = state as FinalizeState;
      final successText = '消息已发送，感谢您的使用';

      emit(finalizeState.copyWith(isPlayingSuccessTts: true));

      await _voiceService.speak(successText, sid: 0, speed: 1.0);

      emit(finalizeState.copyWith(isPlayingSuccessTts: false));
    } catch (e) {
      logger.e('Failed to play success TTS: $e');
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
    // 防止重复调用
    if (_isStoppingAsr) {
      logger.w('⚠️  PagerCubit: 已经在停止ASR过程中，跳过重复调用hangup');
      return;
    }

    _isStoppingAsr = true;

    try {
      // 清理资源
      _isRecording = false;
      try {
        await _asrEngine.stop();
      } catch (e) {
        logger.e('❌ 挂断时停止ASR引擎出错: $e');
        // 继续执行其他清理操作
      }
      await _asrResultSubscription?.cancel();
      await _asrVolumeSubscription?.cancel();
      _asrResultSubscription = null;
      _asrVolumeSubscription = null;

      // 清理波形处理器
      _waveformProcessor.clear();

      // 返回初始状态
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to hangup: $e');
      emit(PagerErrorState(message: '挂断失败：$e'));
    } finally {
      _isStoppingAsr = false;
    }
  }

  /// 取消当前操作
  /// 取消拨号 - 返回拨号准备状态
  Future<void> cancelDialing() async {
    // 防止重复调用
    if (_isStoppingAsr) {
      logger.w('⚠️  PagerCubit: 已经在停止ASR过程中，跳过重复调用cancelDialing');
      return;
    }

    _isStoppingAsr = true;

    try {
      _isRecording = false;
      try {
        await _asrEngine.stop();
      } catch (e) {
        logger.e('❌ 取消拨号时停止ASR引擎出错: $e');
        // 继续执行其他清理操作
      }
      await _asrResultSubscription?.cancel();
      await _asrVolumeSubscription?.cancel();
      _asrResultSubscription = null;
      _asrVolumeSubscription = null;
      await _voiceService.stop();

      // 清理波形处理器
      _waveformProcessor.clear();

      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to cancel dialing: $e');
      emit(PagerErrorState(message: '取消拨号失败：$e'));
    } finally {
      _isStoppingAsr = false;
    }
  }

  /// 添加 PCM 音频数据到波形处理器
  ///
  /// 在实时录音过程中调用此方法，持续收集音频数据
  void addAudioData(List<int> pcmData) {
    _waveformProcessor.addPcmData(pcmData);
  }

  @override
  Future<void> close() async {
    _isRecording = false;

    // 防止重复调用
    if (_isStoppingAsr) {
      logger.w('⚠️  PagerCubit: 已经在停止ASR过程中，跳过重复调用close');
      return super.close();
    }

    _isStoppingAsr = true;

    try {
      await _asrEngine.stop();
    } catch (e) {
      logger.e('❌ 关闭PagerCubit时停止ASR引擎出错: $e');
      // 继续执行其他清理操作
    }
    await _asrResultSubscription?.cancel();
    await _asrVolumeSubscription?.cancel();
    _asrResultSubscription = null;
    _asrVolumeSubscription = null;
    _waveformProcessor.clear();
    _voiceService.dispose();
    _isStoppingAsr = false;
    return super.close();
  }
}
