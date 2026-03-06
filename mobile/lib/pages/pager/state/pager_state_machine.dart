import 'package:equatable/equatable.dart';
import '../models/operator_model.dart';

/// 拨号页面的状态机定义
/// 接通后由 [ConnectedState] + [InCallPhase] 驱动，无需多个独立页面
abstract class PagerState extends Equatable {
  const PagerState();

  @override
  List<Object?> get props => [];
}

// ──────────────────────────────────────────────
//  接通前：准备 / 连接中
// ──────────────────────────────────────────────

/// 初始状态
class PagerInitialState extends PagerState {
  const PagerInitialState();
}

/// 拨号准备状态（仅选择接线员，目标号码在接通后由接线员引导输入）
class DialingPrepState extends PagerState {
  final bool isLoading;
  final String? errorMessage;
  final OperatorPersonality? currentOperator;

  const DialingPrepState({
    this.isLoading = false,
    this.errorMessage,
    this.currentOperator,
  });

  DialingPrepState copyWith({
    bool? isLoading,
    String? errorMessage,
    OperatorPersonality? currentOperator,
  }) {
    return DialingPrepState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentOperator: currentOperator ?? this.currentOperator,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, currentOperator];
}

/// 连接中状态（显示拨号动画 + 初始化语音服务）
class ConnectingState extends PagerState {
  final OperatorPersonality? currentOperator;

  const ConnectingState({this.currentOperator});

  @override
  List<Object?> get props => [currentOperator];
}

// ──────────────────────────────────────────────
//  接通后：统一状态 ConnectedState + InCallPhase
// ──────────────────────────────────────────────

/// 接通后的交互阶段（子状态枚举）
enum InCallPhase {
  /// 接线员问候中，用户聆听
  greeting,

  /// 用户通过数字键盘输入目标用户 ID
  enteringTarget,

  /// 用户通过语音/键盘录入消息内容
  inputtingMessage,

  /// 用户确认 / 编辑消息内容（预览面板）
  reviewing,

  /// 消息发送进行中
  sending,

  /// 消息发送成功，等待用户决定是否继续
  sentSuccess,
}

/// 本次通话内单条发送记录
class SendRecord extends Equatable {
  final String targetId;
  final String content;
  final DateTime sentAt;

  const SendRecord({
    required this.targetId,
    required this.content,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [targetId, content, sentAt];
}

/// 已接通状态（整合原 InCallState + FinalizeState）
///
/// 通过 [phase] 区分当前交互子阶段，全程保持接线员立绘与台词区可见。
class ConnectedState extends PagerState {
  /// 当前接线员
  final OperatorPersonality operator;

  /// 当前交互阶段
  final InCallPhase phase;

  /// 当前目标用户 ID（enteringTarget 阶段填入）
  final String targetId;

  /// 当前消息内容（inputtingMessage / reviewing / sending 阶段）
  final String messageContent;

  /// ASR 是否正在工作（麦克风激活）
  final bool isRecording;

  /// 实时音量波形数据
  final List<double> waveformData;

  /// ASR 实时中间识别结果
  final String asrTranscript;

  /// 是否正在发送消息
  final bool isSending;

  /// 当前操作的错误消息
  final String? errorMessage;

  /// 接线员台词历史（用于气泡流显示）
  final List<String> operatorSpeechHistory;

  /// 接线员当前正在说的台词（最新一条）
  final String operatorCurrentSpeech;

  /// 本次通话内已成功发送的记录列表
  final List<SendRecord> sentHistory;

  const ConnectedState({
    required this.operator,
    this.phase = InCallPhase.greeting,
    this.targetId = '',
    this.messageContent = '',
    this.isRecording = false,
    this.waveformData = const [],
    this.asrTranscript = '',
    this.isSending = false,
    this.errorMessage,
    this.operatorSpeechHistory = const [],
    this.operatorCurrentSpeech = '',
    this.sentHistory = const [],
  });

  ConnectedState copyWith({
    OperatorPersonality? operator,
    InCallPhase? phase,
    String? targetId,
    String? messageContent,
    bool? isRecording,
    List<double>? waveformData,
    String? asrTranscript,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
    List<String>? operatorSpeechHistory,
    String? operatorCurrentSpeech,
    List<SendRecord>? sentHistory,
  }) {
    return ConnectedState(
      operator: operator ?? this.operator,
      phase: phase ?? this.phase,
      targetId: targetId ?? this.targetId,
      messageContent: messageContent ?? this.messageContent,
      isRecording: isRecording ?? this.isRecording,
      waveformData: waveformData ?? this.waveformData,
      asrTranscript: asrTranscript ?? this.asrTranscript,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      operatorSpeechHistory:
          operatorSpeechHistory ?? this.operatorSpeechHistory,
      operatorCurrentSpeech:
          operatorCurrentSpeech ?? this.operatorCurrentSpeech,
      sentHistory: sentHistory ?? this.sentHistory,
    );
  }

  @override
  List<Object?> get props => [
    operator,
    phase,
    targetId,
    messageContent,
    isRecording,
    waveformData,
    asrTranscript,
    isSending,
    errorMessage,
    operatorSpeechHistory,
    operatorCurrentSpeech,
    sentHistory,
  ];
}

// ──────────────────────────────────────────────
//  通用状态
// ──────────────────────────────────────────────

/// 接线员解锁提示状态
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
