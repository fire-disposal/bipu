import 'package:equatable/equatable.dart';
import '../models/operator_model.dart';
import '../services/text_processor.dart';

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
  final OperatorPersonality? currentOperator; // 当前选择的接线员

  const DialingPrepState({
    this.targetId = '',
    this.selectedContactName,
    this.isLoading = false,
    this.errorMessage,
    this.currentOperator,
  });

  DialingPrepState copyWith({
    String? targetId,
    String? selectedContactName,
    bool? isLoading,
    String? errorMessage,
    OperatorPersonality? currentOperator,
  }) {
    return DialingPrepState(
      targetId: targetId ?? this.targetId,
      selectedContactName: selectedContactName ?? this.selectedContactName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentOperator: currentOperator ?? this.currentOperator,
    );
  }

  @override
  List<Object?> get props => [
    targetId,
    selectedContactName,
    isLoading,
    errorMessage,
    currentOperator,
  ];
}

/// 状态2: 通话中 (In-Call Experience)
/// 显示虚拟接线员立绘，播放TTS，进行ASR语音转写
class InCallState extends PagerState {
  final String targetId;
  final String operatorImageUrl; // 虚拟接线员立绘URL或Asset路径
  final String asrTranscript; // 实时转写文本（用户输入）
  final List<double> waveformData; // 声纹动效数据 (0-1范围)
  final bool isSilenceDetected; // 是否检测到静默
  final OperatorPersonality? operator; // 当前接线员人格

  // ✅ 新增：接线员台词相关字段
  final String operatorCurrentSpeech; // 接线员当前说的台词
  final List<String> operatorSpeechHistory; // 接线员历史台词列表
  final bool isWaitingForUserInput; // 是否等待用户输入

  const InCallState({
    required this.targetId,
    this.operatorImageUrl = '',
    this.asrTranscript = '',
    this.waveformData = const [],
    this.isSilenceDetected = false,
    this.operator,
    this.operatorCurrentSpeech = '',
    this.operatorSpeechHistory = const [],
    this.isWaitingForUserInput = false,
  });

  InCallState copyWith({
    String? targetId,
    String? operatorImageUrl,
    String? asrTranscript,
    List<double>? waveformData,
    bool? isSilenceDetected,
    OperatorPersonality? operator,
    String? operatorCurrentSpeech,
    List<String>? operatorSpeechHistory,
    bool? isWaitingForUserInput,
  }) {
    return InCallState(
      targetId: targetId ?? this.targetId,
      operatorImageUrl: operatorImageUrl ?? this.operatorImageUrl,
      asrTranscript: asrTranscript ?? this.asrTranscript,
      waveformData: waveformData ?? this.waveformData,
      isSilenceDetected: isSilenceDetected ?? this.isSilenceDetected,
      operator: operator ?? this.operator,
      operatorCurrentSpeech:
          operatorCurrentSpeech ?? this.operatorCurrentSpeech,
      operatorSpeechHistory:
          operatorSpeechHistory ?? this.operatorSpeechHistory,
      isWaitingForUserInput:
          isWaitingForUserInput ?? this.isWaitingForUserInput,
    );
  }

  @override
  List<Object?> get props => [
    targetId,
    operatorImageUrl,
    asrTranscript,
    waveformData,
    isSilenceDetected,
    operator,
    operatorCurrentSpeech,
    operatorSpeechHistory,
    isWaitingForUserInput,
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
  final OperatorPersonality? operator; // 当前接线员人格
  final bool isEditing; // 是否处于编辑模式
  final TextProcessingResult? textProcessingResult; // 编辑的文本处理结果
  final bool isNewlyUnlocked; // 该接线员是否首次完成对话（用于解锁提示）
  final List<String> operatorSpeechHistory; // ✅ 新增：接线员历史台词

  const FinalizeState({
    required this.targetId,
    this.messageContent = '',
    this.isSending = false,
    this.sendSuccess = false,
    this.sendErrorMessage,
    this.showHangupButton = false,
    this.isPlayingSuccessTts = false,
    this.operator,
    this.isEditing = false,
    this.textProcessingResult,
    this.isNewlyUnlocked = false,
    this.operatorSpeechHistory = const [],
  });

  FinalizeState copyWith({
    String? targetId,
    String? messageContent,
    bool? isSending,
    bool? sendSuccess,
    String? sendErrorMessage,
    bool? showHangupButton,
    bool? isPlayingSuccessTts,
    OperatorPersonality? operator,
    bool? isEditing,
    TextProcessingResult? textProcessingResult,
    bool? isNewlyUnlocked,
    List<String>? operatorSpeechHistory,
  }) {
    return FinalizeState(
      targetId: targetId ?? this.targetId,
      messageContent: messageContent ?? this.messageContent,
      isSending: isSending ?? this.isSending,
      sendSuccess: sendSuccess ?? this.sendSuccess,
      sendErrorMessage: sendErrorMessage,
      showHangupButton: showHangupButton ?? this.showHangupButton,
      isPlayingSuccessTts: isPlayingSuccessTts ?? this.isPlayingSuccessTts,
      operator: operator ?? this.operator,
      isEditing: isEditing ?? this.isEditing,
      textProcessingResult: textProcessingResult ?? this.textProcessingResult,
      isNewlyUnlocked: isNewlyUnlocked ?? this.isNewlyUnlocked,
      operatorSpeechHistory:
          operatorSpeechHistory ?? this.operatorSpeechHistory,
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
    operator,
    isEditing,
    textProcessingResult,
    isNewlyUnlocked,
    operatorSpeechHistory,
  ];
}

/// 操作员解锁提示状态
class OperatorUnlockedState extends PagerState {
  final OperatorPersonality operator;
  final String unlockMessage;

  const OperatorUnlockedState({
    required this.operator,
    this.unlockMessage = '恭喜！你已解锁新的接线员',
  });

  @override
  List<Object?> get props => [operator, unlockMessage];
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
