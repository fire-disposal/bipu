import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/im_service.dart';
import '../../../core/utils/logger.dart';
import '../services/waveform_processor.dart';
import '../services/operator_service.dart';
import '../models/operator_model.dart';
import '../pager_assistant.dart';
import 'pager_state_machine.dart';

/// 拨号页面业务逻辑 Cubit
///
/// 新流程（接通后全程在 [ConnectedState] 内完成）：
///   greeting → enteringTarget → inputtingMessage → reviewing → sending → sentSuccess
///   ↑___________________________continueToNextRecipient____________________________↑
class PagerCubit extends Cubit<PagerState> {
  final ApiClient _apiClient;
  final ImService _imService;
  final PagerAssistant _voiceAssistant;
  final OperatorService _operatorService;

  /// PCM 包络处理器——仅用于录音完成后随消息发送波形数据
  final WaveformProcessor _waveformProcessor = WaveformProcessor();

  List<int> _currentWaveformData = [];

  /// 防重入：confirmInCallTargetId 正在执行中
  bool _isConfirming = false;

  /// 防重入：startDialing 正在执行中
  bool _isDialing = false;

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

  // ──────────────────────────────────────────────
  //  工具方法
  // ──────────────────────────────────────────────

  /// 限制台词历史长度，防止无限增长
  List<String> _appendSpeech(
    List<String> history,
    String text, [
    int max = 50,
  ]) {
    final list = [...history, text];
    return list.length <= max ? list : list.sublist(list.length - max);
  }

  /// 安全更新 ConnectedState
  void _update(void Function(ConnectedState cs) fn) {
    if (state is ConnectedState) fn(state as ConnectedState);
  }

  /// 获取当前 ConnectedState（若不在接通状态则返回 null）
  ConnectedState? get _cs =>
      state is ConnectedState ? state as ConnectedState : null;

  // ──────────────────────────────────────────────
  //  拨号准备
  // ──────────────────────────────────────────────

  /// 初始化拨号准备状态（随机选择接线员）
  Future<void> initializeDialingPrep() async {
    try {
      await _operatorService.init();
      final op = _operatorService.getRandomOperator();
      logger.i('PagerCubit: 随机选择接线员 - ${op.name}');
      emit(DialingPrepState(currentOperator: op));
      // 🔥 后台预热语音服务（fire-and-forget）
      // 用户在准备页浏览时即开始加载 TTS/ASR ONNX 模型，
      // 使后续的连接动效不因模型加载而冻结
      unawaited(_voiceAssistant.init());
    } catch (e) {
      logger.e('initializeDialingPrep failed: $e');
      emit(PagerErrorState(message: '初始化失败：$e'));
    }
  }

  /// 手动选择接线员
  void selectOperator(OperatorPersonality op) {
    if (state is DialingPrepState) {
      emit((state as DialingPrepState).copyWith(currentOperator: op));
      logger.i('PagerCubit: 用户选择接线员 - ${op.name}');
    }
  }

  // ──────────────────────────────────────────────
  //  连接与问候
  // ──────────────────────────────────────────────

  /// 开始连接（由拨号准备页面触发）
  Future<void> startDialing() async {
    if (_isDialing) return;
    _isDialing = true;
    try {
      // 提前确定接线员，使连接页能立即显示接线员名称
      OperatorPersonality? op;
      if (state is DialingPrepState) {
        op = (state as DialingPrepState).currentOperator;
      }
      op ??= _operatorService.getRandomOperator();
      _voiceAssistant.updateOperator(op);

      emit(ConnectingState(currentOperator: op));
      logger.i('PagerCubit: 进入连接中状态，接线员 = ${op.name}');

      // 并行：展示连接动画（最少 2 秒）+ 初始化语音服务
      // 若已在 initializeDialingPrep 预热，init() 几乎立即返回，
      // Future.wait 仅等待 2 秒动画时间，连接动效全程流畅。
      await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        _voiceAssistant.init(),
      ]);

      logger.i('PagerCubit: 语音服务就绪，接线员 = ${op.name}');

      // 进入接通状态
      emit(ConnectedState(operator: op, phase: InCallPhase.greeting));

      // 🔑 让 Flutter 先渲染 InCallPage 首帧，
      // 再执行 TTS 合成（同步 ONNX 推理会短暂占用 Dart isolate）
      await Future.delayed(Duration.zero);
      if (state is! ConnectedState) return;

      await _runGreetingFlow(op);
    } catch (e) {
      logger.e('startDialing failed: $e');
      emit(PagerErrorState(message: '连接失败：$e'));
    } finally {
      _isDialing = false;
    }
  }

  /// 问候流程：问候语 → 询问目标 ID
  Future<void> _runGreetingFlow(OperatorPersonality op) async {
    // ① 问候语
    final greeting = op.dialogues.getGreeting();
    _update(
      (cs) => emit(
        cs.copyWith(
          operatorCurrentSpeech: greeting,
          operatorSpeechHistory: _appendSpeech(
            cs.operatorSpeechHistory,
            greeting,
          ),
        ),
      ),
    );
    // 先让气泡文本渲染到屏幕，再开始 TTS 合成
    await Future.delayed(Duration.zero);
    if (state is! ConnectedState) return;

    await _voiceAssistant.respond(greeting);
    if (state is! ConnectedState) return;

    // ② 询问目标用户 ID，同时切换到输入阶段
    final askTarget = op.dialogues.getAskTarget();
    _update(
      (cs) => emit(
        cs.copyWith(
          phase: InCallPhase.enteringTarget,
          operatorCurrentSpeech: askTarget,
          operatorSpeechHistory: _appendSpeech(
            cs.operatorSpeechHistory,
            askTarget,
          ),
        ),
      ),
    );
    // 先让阶段切换动画渲染，再开始 TTS
    await Future.delayed(Duration.zero);
    if (state is! ConnectedState) return;

    await _voiceAssistant.respond(askTarget);
  }

  // ──────────────────────────────────────────────
  //  目标 ID 输入
  // ──────────────────────────────────────────────

  /// 更新数字键盘输入的目标 ID
  void updateInCallTargetId(String id) {
    _update((cs) => emit(cs.copyWith(targetId: id, clearError: true)));
  }

  /// 确认目标 ID，检查用户是否存在，成功则进入消息录入阶段
  Future<void> confirmInCallTargetId() async {
    if (_isConfirming) return;
    final cs = _cs;
    if (cs == null || cs.targetId.trim().isEmpty) return;
    _isConfirming = true;
    // 立刻向 UI 反馈“确认中”状态：禁用按鈕和键盘、显示加载展示
    emit(cs.copyWith(isConfirming: true, clearError: true));
    try {
      final targetId = cs.targetId.trim();
      final op = cs.operator;

      // 接线员播报确认台词
      final confirmText = op.dialogues.getConfirmId(targetId);
      emit(
        cs.copyWith(
          operatorCurrentSpeech: confirmText,
          operatorSpeechHistory: _appendSpeech(
            cs.operatorSpeechHistory,
            confirmText,
          ),
        ),
      );
      await _voiceAssistant.respond(confirmText);
      if (state is! ConnectedState) return;

      // 检查用户是否存在
      try {
        await _apiClient.api.users.getApiUsersUsersBipupuId(bipupuId: targetId);
        logger.i('PagerCubit: 目标用户存在 - $targetId');

        // 成功 → 进入消息录入阶段
        final askMsg = op.dialogues.getRequestMessage();
        _update(
          (current) => emit(
            current.copyWith(
              phase: InCallPhase.inputtingMessage,
              operatorCurrentSpeech: askMsg,
              operatorSpeechHistory: _appendSpeech(
                current.operatorSpeechHistory,
                askMsg,
              ),
            ),
          ),
        );
        if (state is! ConnectedState) return; // hangup 可能在 API 异步间隙期间被调用
        await _voiceAssistant.respond(askMsg);
      } catch (e) {
        logger.w('PagerCubit: 目标用户不存在 - $targetId');

        // 失败 → 接线员提示，重置回 ID 输入
        final notFound = op.dialogues.getUserNotFound();
        _update(
          (current) => emit(
            current.copyWith(
              operatorCurrentSpeech: notFound,
              operatorSpeechHistory: _appendSpeech(
                current.operatorSpeechHistory,
                notFound,
              ),
              errorMessage: '该用户不存在，请重新输入 ID',
            ),
          ),
        );
        if (state is! ConnectedState) return; // hangup 可能在 API 异步间隙期间被调用
        await _voiceAssistant.respond(notFound);
        if (state is! ConnectedState) return;

        _update(
          (current) => emit(
            current.copyWith(phase: InCallPhase.enteringTarget, targetId: ''),
          ),
        );
      }
    } finally {
      _isConfirming = false;
      // 无论成功还是失败，确保 UI 展示不再处于加载态
      if (state is ConnectedState) {
        final cur = state as ConnectedState;
        if (cur.isConfirming) {
          emit(cur.copyWith(isConfirming: false));
        }
      }
    }
  }

  // ──────────────────────────────────────────────
  //  消息录入（语音 / 文字）
  // ──────────────────────────────────────────────

  /// 用户触发：开始语音录入
  Future<void> startVoiceRecording() async {
    if (state is! ConnectedState) return;
    // 打断正在播放的 TTS
    await _voiceAssistant.stopSpeaking();
    _waveformProcessor.clear();
    await _executeVoiceRecording();
  }

  /// 内部：执行录音识别流程
  Future<void> _executeVoiceRecording() async {
    try {
      _update(
        (cs) => emit(
          cs.copyWith(isRecording: false, asrTranscript: '', clearError: true),
        ),
      );

      final userText = await _voiceAssistant.recordAndRecognize(
        maxDuration: const Duration(seconds: 30),
        onInterimResult: (interim) {
          _update((cs) => emit(cs.copyWith(asrTranscript: interim)));
        },
        onStarted: () {
          _update((cs) => emit(cs.copyWith(isRecording: true)));
        },
      );

      if (userText.isEmpty) {
        logger.w('PagerCubit: 未识别到语音输入');
        _update(
          (cs) => emit(cs.copyWith(isRecording: false, asrTranscript: '')),
        );
        return;
      }

      // 识别成功 → 进入确认阶段
      logger.i('PagerCubit: 语音识别成功 "$userText"');
      _update(
        (cs) => emit(
          cs.copyWith(
            isRecording: false,
            asrTranscript: '',
            messageContent: userText,
            phase: InCallPhase.reviewing,
          ),
        ),
      );
    } catch (e) {
      logger.e('_executeVoiceRecording error: $e');
      _update((cs) => emit(cs.copyWith(isRecording: false, asrTranscript: '')));
    }
  }

  /// 用户触发：手动结束当前录音（提前停止）
  void finishAsrRecording() {
    if (state is ConnectedState) _voiceAssistant.signalStop();
  }

  /// 用户触发：切换到文字输入模式（直接进入确认阶段，内容为当前 ASR 临时结果）
  Future<void> switchToTextInput() async {
    if (state is! ConnectedState) return;
    final cs = state as ConnectedState;
    final draft = cs.asrTranscript;
    // 停止录音和 TTS（顺序先发信号停录音，再停 TTS）
    _voiceAssistant.signalStop();
    await _voiceAssistant.stopSpeaking();
    // 停止后再检查状态，慢速设备可能在期间挂断
    if (state is! ConnectedState) return;
    emit(
      (state as ConnectedState).copyWith(
        phase: InCallPhase.reviewing,
        messageContent: draft,
        isRecording: false,
        asrTranscript: '',
      ),
    );
  }

  /// 从确认面板返回重新录音
  Future<void> backToVoiceInput() async {
    // 先停止任何待播的 TTS（例如错误提示语音）
    await _voiceAssistant.stopSpeaking();
    _update(
      (cs) => emit(
        cs.copyWith(
          phase: InCallPhase.inputtingMessage,
          messageContent: '',
          asrTranscript: '',
        ),
      ),
    );
  }

  /// 更新编辑中的消息内容（文字输入回调）
  void updateMessageContent(String content) {
    _update((cs) => emit(cs.copyWith(messageContent: content)));
  }

  // ──────────────────────────────────────────────
  //  发送消息
  // ──────────────────────────────────────────────

  /// 确认并发送消息
  Future<void> sendMessage() async {
    final cs = _cs;
    if (cs == null || cs.messageContent.trim().isEmpty) return;

    emit(cs.copyWith(phase: InCallPhase.sending, isSending: true));
    logger.i('PagerCubit: 发送消息 → "${cs.messageContent}" → ${cs.targetId}');

    try {
      _currentWaveformData = _waveformProcessor.finalize();
      final result = await _imService.sendMessage(
        receiverId: cs.targetId,
        content: cs.messageContent.trim(),
        messageType: 'VOICE',
        waveform: _currentWaveformData.isEmpty ? null : _currentWaveformData,
      );

      if (result != null) {
        logger.i('PagerCubit: 消息发送成功');

        final record = SendRecord(
          targetId: cs.targetId,
          content: cs.messageContent.trim(),
          sentAt: DateTime.now(),
        );
        final successText = cs.operator.dialogues.getSuccessMessage();

        _update(
          (current) => emit(
            current.copyWith(
              phase: InCallPhase.sentSuccess,
              isSending: false,
              sentHistory: [...current.sentHistory, record],
              operatorCurrentSpeech: successText,
              operatorSpeechHistory: _appendSpeech(
                current.operatorSpeechHistory,
                successText,
              ),
            ),
          ),
        );

        // 播放成功 TTS
        await _voiceAssistant.respond(successText);
        if (state is! ConnectedState) return;

        // 接线员询问是否继续
        final askContinue = cs.operator.dialogues.getAskContinue();
        _update(
          (current) => emit(
            current.copyWith(
              operatorCurrentSpeech: askContinue,
              operatorSpeechHistory: _appendSpeech(
                current.operatorSpeechHistory,
                askContinue,
              ),
            ),
          ),
        );
        await _voiceAssistant.respond(askContinue);

        // 计录接线员对话次数
        await _operatorService.incrementConversationCount(cs.operator.id);

        // 首次完成通话就解锁该接线员图鉴
        final wasNewlyUnlocked = await _operatorService.unlockOperator(
          cs.operator.id,
        );
        if (wasNewlyUnlocked) {
          // 短暂 emit 解锁状态，触发 PagerPage BlocListener 展示解锁弹窗
          // （buildWhen 保证底层 body 不被重建）
          logger.i('PagerCubit: 解锁接线员 ${cs.operator.name}');
          final updatedOp = _operatorService.getOperatorById(cs.operator.id)!;
          emit(
            OperatorUnlockedState(
              operator: updatedOp,
              unlockMessage: '恭喜！您已解锁接线员 ${updatedOp.name}！',
            ),
          );
        }
      } else {
        logger.w('PagerCubit: 消息发送失败（result == null）');
        _update(
          (current) => emit(
            current.copyWith(
              phase: InCallPhase.reviewing,
              isSending: false,
              errorMessage: '发送失败，请重试',
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('sendMessage failed: $e');
      _update(
        (current) => emit(
          current.copyWith(
            phase: InCallPhase.reviewing,
            isSending: false,
            errorMessage: '发送异常：$e',
          ),
        ),
      );
    }
  }

  /// 继续向下一个人发送（sentSuccess → enteringTarget）
  Future<void> continueToNextRecipient() async {
    final cs = _cs;
    if (cs == null) return;
    logger.i('PagerCubit: 用户选择继续发送给另一人');

    // 停止当前可能在播放的提示语音
    await _voiceAssistant.stopSpeaking();
    if (state is! ConnectedState) return;

    final askTarget = cs.operator.dialogues.getAskTarget();
    emit(
      cs.copyWith(
        phase: InCallPhase.enteringTarget,
        targetId: '',
        messageContent: '',
        operatorCurrentSpeech: askTarget,
        operatorSpeechHistory: _appendSpeech(
          cs.operatorSpeechHistory,
          askTarget,
        ),
      ),
    );
    if (state is! ConnectedState) return;
    await _voiceAssistant.respond(askTarget);
  }

  // ──────────────────────────────────────────────
  //  挂断 / 取消
  // ──────────────────────────────────────────────

  /// 挂断通话（随时可调用），清理资源并回到拨号准备
  Future<void> hangup() async {
    logger.i('PagerCubit: 挂断通话');
    try {
      await _voiceAssistant.stopSpeaking();
      await _voiceAssistant.stopRecording();
      _waveformProcessor.clear();
      _currentWaveformData.clear();
      await initializeDialingPrep();
    } catch (e) {
      logger.e('hangup failed: $e');
      emit(PagerErrorState(message: '挂断失败：$e'));
    }
  }

  /// 取消连接中状态（ConnectingPage 挂断按钮触发）
  Future<void> cancelDialing() async => hangup();

  // ──────────────────────────────────────────────
  //  生命周期
  // ──────────────────────────────────────────────

  @override
  Future<void> close() async {
    logger.i('PagerCubit: 销毁，清理资源');
    try {
      await _voiceAssistant.stopSpeaking();
      await _voiceAssistant.stopRecording();
      await _voiceAssistant.dispose();
      _waveformProcessor.clear();
      _currentWaveformData.clear();
    } catch (e) {
      logger.e('close error: $e');
    }
    return super.close();
  }

  // ──────────────────────────────────────────────
  //  诊断
  // ──────────────────────────────────────────────

  /// 暴露给外部（如图鉴页面）使用同一 OperatorService 实例
  OperatorService get operatorService => _operatorService;

  OperatorPersonality? getCurrentOperator() {
    if (state is DialingPrepState)
      return (state as DialingPrepState).currentOperator;
    if (state is ConnectedState) return (state as ConnectedState).operator;
    return null;
  }

  List<String> getOperatorSpeechHistory() {
    if (state is ConnectedState)
      return (state as ConnectedState).operatorSpeechHistory;
    return [];
  }
}
