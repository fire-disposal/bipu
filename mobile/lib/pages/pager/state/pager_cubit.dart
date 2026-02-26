import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sound_stream/sound_stream.dart';
import '../../../core/network/api_client.dart';
import '../../../core/voice/voice_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/api/models/message_create.dart';
import '../../../core/api/models/message_type.dart';
import '../services/waveform_processor.dart';
import 'pager_state_machine.dart';

/// 拨号页面业务逻辑 Cubit
/// 管理三个状态的转换和业务流程
class PagerCubit extends Cubit<PagerState> {
  final ApiClient _apiClient;
  final VoiceService _voiceService;

  // 音频录制相关
  RecorderStream? _recorderStream;
  bool _isRecording = false;

  // 波形处理
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  // 状态管理
  String _currentTargetId = '';
  String _currentMessageContent = '';
  List<int> _currentWaveformData = [];

  PagerCubit({ApiClient? apiClient, VoiceService? voiceService})
    : _apiClient = apiClient ?? ApiClient.instance,
      _voiceService = voiceService ?? VoiceService(),
      super(const PagerInitialState());

  /// 初始化拨号准备状态
  Future<void> initializeDialingPrep() async {
    try {
      await _voiceService.init();
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to initialize dialing prep: $e');
      emit(PagerErrorState(message: '初始化失败: $e'));
    }
  }

  /// 更新目标ID
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
        emit(PagerErrorState(message: '请输入目标ID'));
        return;
      }

      _currentTargetId = targetId;

      // 转换到通话中状态
      emit(InCallState(targetId: targetId, operatorImageUrl: operatorImageUrl));

      // 播放引导台词
      await _playGuidanceTts();

      // 启动ASR语音转写
      await _startAsrTranscription();
    } catch (e) {
      logger.e('Failed to start dialing: $e');
      emit(PagerErrorState(message: '拨号失败: $e'));
    }
  }

  /// 播放引导台词 (TTS)
  Future<void> _playGuidanceTts() async {
    try {
      if (state is! InCallState) return;

      final guidanceText = '您好，请说出您要传达的消息';

      // 更新状态：TTS播放中
      final currentState = state as InCallState;
      emit(
        currentState.copyWith(currentTtsText: guidanceText, isTtsPlaying: true),
      );

      // 播放TTS
      await _voiceService.speak(guidanceText, sid: 0, speed: 1.0);

      // 更新状态：TTS播放完成
      emit(currentState.copyWith(isTtsPlaying: false));
    } catch (e) {
      logger.e('Failed to play guidance TTS: $e');
    }
  }

  /// 启动ASR语音转写
  Future<void> _startAsrTranscription() async {
    try {
      if (state is! InCallState) return;

      final currentState = state as InCallState;

      // 更新状态：ASR激活
      emit(currentState.copyWith(isAsrActive: true));

      // 初始化录音流
      _recorderStream = RecorderStream();
      await _recorderStream!.initialize();

      _isRecording = true;

      // 模拟ASR转写过程（实际应集成sherpa_onnx ASR引擎）
      // 这里使用简化的演示逻辑
      await _simulateAsrTranscription();
    } catch (e) {
      logger.e('Failed to start ASR transcription: $e');
      emit(PagerErrorState(message: 'ASR启动失败: $e'));
    }
  }

  /// 模拟ASR转写（演示用）
  /// 实际应用中应集成sherpa_onnx ASR引擎进行实时转写
  Future<void> _simulateAsrTranscription() async {
    try {
      if (state is! InCallState) return;

      final currentState = state as InCallState;

      // 模拟录音和转写过程
      // 在实际应用中，这里应该处理音频流并调用ASR模型
      await Future.delayed(const Duration(seconds: 2));

      // 模拟转写结果
      final mockTranscript = '我想发送一条消息';

      emit(
        currentState.copyWith(
          asrTranscript: mockTranscript,
          waveformData: _generateMockWaveform(),
        ),
      );

      // 模拟静默检测
      await Future.delayed(const Duration(seconds: 1));

      emit(currentState.copyWith(isSilenceDetected: true));

      // 停止ASR，转换到Finalize状态
      await _stopAsrAndFinalize(mockTranscript);
    } catch (e) {
      logger.e('Error in ASR transcription: $e');
    }
  }

  /// 生成模拟声纹数据
  List<double> _generateMockWaveform() {
    return List.generate(32, (i) => (i % 2 == 0 ? 0.3 : 0.7));
  }

  /// 停止ASR并转换到Finalize状态
  Future<void> _stopAsrAndFinalize(String transcript) async {
    try {
      _isRecording = false;
      await _recorderStream?.stop();

      _currentMessageContent = transcript;

      // 获取当前的波形数据用于UI显示
      final currentWaveform = _waveformProcessor.getCurrentWaveform();
      logger.i('Current waveform points: ${currentWaveform.length}');

      if (state is InCallState) {
        final inCallState = state as InCallState;

        // 转换到Finalize状态
        emit(
          FinalizeState(
            targetId: inCallState.targetId,
            messageContent: transcript,
          ),
        );
      }
    } catch (e) {
      logger.e('Failed to stop ASR: $e');
    }
  }

  /// 发送消息
  Future<void> sendMessage() async {
    try {
      if (state is! FinalizeState) return;

      final finalizeState = state as FinalizeState;

      if (finalizeState.messageContent.isEmpty) {
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

      // 调用API发送消息
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

      // 播放成功TTS
      await _playSuccessTts();

      // 显示挂断按钮
      emit(finalizeState.copyWith(showHangupButton: true));
    } catch (e) {
      logger.e('Failed to send message: $e');
      if (state is FinalizeState) {
        final finalizeState = state as FinalizeState;
        emit(
          finalizeState.copyWith(
            isSending: false,
            sendErrorMessage: '发送失败: $e',
          ),
        );
      }
    }
  }

  /// 播放成功TTS
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

  /// 挂断 - 返回拨号准备状态
  Future<void> hangup() async {
    try {
      // 清理资源
      _isRecording = false;
      await _recorderStream?.stop();

      // 返回初始状态
      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to hangup: $e');
      emit(PagerErrorState(message: '挂断失败: $e'));
    }
  }

  /// 取消当前操作
  Future<void> cancel() async {
    try {
      _isRecording = false;
      await _recorderStream?.stop();
      await _voiceService.stop();

      // 清理波形处理器
      _waveformProcessor.clear();

      emit(const DialingPrepState());
    } catch (e) {
      logger.e('Failed to cancel: $e');
      emit(PagerErrorState(message: '取消失败: $e'));
    }
  }

  /// 添加PCM音频数据到波形处理器
  ///
  /// 在实时录音过程中调用此方法，持续收集音频数据
  void addAudioData(List<int> pcmData) {
    _waveformProcessor.addPcmData(pcmData);
  }

  @override
  Future<void> close() async {
    _isRecording = false;
    await _recorderStream?.stop();
    _waveformProcessor.clear();
    _voiceService.dispose();
    return super.close();
  }
}
