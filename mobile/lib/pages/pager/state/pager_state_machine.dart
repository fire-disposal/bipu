import 'package:equatable/equatable.dart';

/// 拨号页面的状态机定义
/// 定义了三个主要状态及其转换逻辑

/// 拨号状态基类
abstract class PagerState extends Equatable {
  const PagerState();

  @override
  List<Object?> get props => [];
}

/// 状态1: 拨号准备 (Dialing Prep)
/// 用户输入目标ID，选择联系人，准备拨号
class DialingPrepState extends PagerState {
  final String targetId;
  final String? selectedContactName;
  final bool isLoading;
  final String? errorMessage;

  const DialingPrepState({
    this.targetId = '',
    this.selectedContactName,
    this.isLoading = false,
    this.errorMessage,
  });

  DialingPrepState copyWith({
    String? targetId,
    String? selectedContactName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DialingPrepState(
      targetId: targetId ?? this.targetId,
      selectedContactName: selectedContactName ?? this.selectedContactName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    targetId,
    selectedContactName,
    isLoading,
    errorMessage,
  ];
}

/// 状态2: 通话中 (In-Call Experience)
/// 显示虚拟接线员立绘，播放TTS，进行ASR语音转写
class InCallState extends PagerState {
  final String targetId;
  final String operatorImageUrl; // 虚拟接线员立绘URL或Asset路径
  final String currentTtsText; // 当前播放的TTS文本
  final bool isTtsPlaying;
  final bool isAsrActive; // ASR是否正在录音
  final String asrTranscript; // 实时转写文本
  final List<double> waveformData; // 声纹动效数据 (0-1范围)
  final bool isSilenceDetected; // 是否检测到静默

  const InCallState({
    required this.targetId,
    this.operatorImageUrl = '',
    this.currentTtsText = '',
    this.isTtsPlaying = false,
    this.isAsrActive = false,
    this.asrTranscript = '',
    this.waveformData = const [],
    this.isSilenceDetected = false,
  });

  InCallState copyWith({
    String? targetId,
    String? operatorImageUrl,
    String? currentTtsText,
    bool? isTtsPlaying,
    bool? isAsrActive,
    String? asrTranscript,
    List<double>? waveformData,
    bool? isSilenceDetected,
  }) {
    return InCallState(
      targetId: targetId ?? this.targetId,
      operatorImageUrl: operatorImageUrl ?? this.operatorImageUrl,
      currentTtsText: currentTtsText ?? this.currentTtsText,
      isTtsPlaying: isTtsPlaying ?? this.isTtsPlaying,
      isAsrActive: isAsrActive ?? this.isAsrActive,
      asrTranscript: asrTranscript ?? this.asrTranscript,
      waveformData: waveformData ?? this.waveformData,
      isSilenceDetected: isSilenceDetected ?? this.isSilenceDetected,
    );
  }

  @override
  List<Object?> get props => [
    targetId,
    operatorImageUrl,
    currentTtsText,
    isTtsPlaying,
    isAsrActive,
    asrTranscript,
    waveformData,
    isSilenceDetected,
  ];
}

/// 状态3: 发送与结束 (Finalize)
/// 显示"发送"按钮，发送消息后播放成功TTS，显示"挂断"按钮
class FinalizeState extends PagerState {
  final String targetId;
  final String messageContent; // 要发送的消息内容
  final bool isSending; // 是否正在发送
  final bool sendSuccess; // 是否发送成功
  final String? sendErrorMessage;
  final bool showHangupButton; // 是否显示挂断按钮
  final bool isPlayingSuccessTts; // 是否正在播放成功TTS

  const FinalizeState({
    required this.targetId,
    this.messageContent = '',
    this.isSending = false,
    this.sendSuccess = false,
    this.sendErrorMessage,
    this.showHangupButton = false,
    this.isPlayingSuccessTts = false,
  });

  FinalizeState copyWith({
    String? targetId,
    String? messageContent,
    bool? isSending,
    bool? sendSuccess,
    String? sendErrorMessage,
    bool? showHangupButton,
    bool? isPlayingSuccessTts,
  }) {
    return FinalizeState(
      targetId: targetId ?? this.targetId,
      messageContent: messageContent ?? this.messageContent,
      isSending: isSending ?? this.isSending,
      sendSuccess: sendSuccess ?? this.sendSuccess,
      sendErrorMessage: sendErrorMessage,
      showHangupButton: showHangupButton ?? this.showHangupButton,
      isPlayingSuccessTts: isPlayingSuccessTts ?? this.isPlayingSuccessTts,
    );
  }

  @override
  List<Object?> get props => [
    targetId,
    messageContent,
    isSending,
    sendSuccess,
    sendErrorMessage,
    showHangupButton,
    isPlayingSuccessTts,
  ];
}

/// 错误状态
class PagerErrorState extends PagerState {
  final String message;
  final String? code;

  const PagerErrorState({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// 初始状态
class PagerInitialState extends PagerState {
  const PagerInitialState();
}
