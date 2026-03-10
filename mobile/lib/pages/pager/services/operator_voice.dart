import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import '../models/operator_model.dart';
import '../../../core/voice/voice_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 台词阶段枚举
// ─────────────────────────────────────────────────────────────────────────────

/// 接线员台词阶段
///
/// 业务层只需指定阶段，具体台词随机选取和音色参数均由 [OperatorVoice] 内部处理。
enum OperatorLine {
  /// 接通时的问候语
  greeting,

  /// 询问目标用户 ID
  askTarget,

  /// 复诵确认目标 ID（需传 [param] = targetId）
  confirmId,

  /// 请求录入消息内容
  requestMessage,

  /// 目标用户不存在
  userNotFound,

  /// 消息发送成功
  successMessage,

  /// 询问是否继续发送
  askContinue,

  /// 随机短句（填充/闲聊）
  randomPhrase,
}

// ─────────────────────────────────────────────────────────────────────────────
// 播放后端抽象
// ─────────────────────────────────────────────────────────────────────────────

/// 台词播放后端
///
/// 当前实现为 TTS；未来可替换为预录制音频，只需实现此接口。
abstract interface class OperatorVoiceBackend {
  /// 播放指定文本（需根据接线员音色参数决定如何播放）
  Future<void> play(OperatorPersonality op, String text);

  /// 立即停止播放
  Future<void> stop();
}

/// TTS 后端（当前实现）
class TtsVoiceBackend implements OperatorVoiceBackend {
  final VoiceService _voice;

  const TtsVoiceBackend(this._voice);

  @override
  Future<void> play(OperatorPersonality op, String text) =>
      _voice.speak(text, sid: op.ttsId, speed: op.ttsSpeed);

  @override
  Future<void> stop() => _voice.stopSpeaking();
}

/// 预录制音频后端
///
/// 通过 [manifest.json] 将台词文本映射到对应的 asset 文件路径，
/// 使用 just_audio 播放。
///
/// manifest.json 格式（由 tools/generate_voices.py 生成）:
/// ```json
/// {
///   "version": 1,
///   "by_text": {
///     "您好，这里是 Bipupu 接线台。": "op_001/greeting_0.mp3",
///     ...
///   }
/// }
/// ```
class PrerecordedVoiceBackend implements OperatorVoiceBackend {
  final String assetBasePath;

  final AudioPlayer _player = AudioPlayer();
  Map<String, String>? _byText;
  bool _loaded = false;

  PrerecordedVoiceBackend({this.assetBasePath = 'assets/voices'});

  /// 懒加载 manifest.json
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('$assetBasePath/manifest.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _byText = Map<String, String>.from(
        (data['by_text'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
      );
      debugPrint('[PrerecordedVoice] manifest 加载完成，共 ${_byText!.length} 条');
    } catch (e) {
      debugPrint('[PrerecordedVoice] manifest 加载失败（将全部依赖 TTS）：$e');
      _byText = {};
    }
    _loaded = true;
  }

  /// 检查指定文本是否有对应预录制音频
  Future<bool> hasAudio(String text) async {
    await _ensureLoaded();
    return _byText?.containsKey(text) ?? false;
  }

  @override
  Future<void> play(OperatorPersonality op, String text) async {
    await _ensureLoaded();

    final relPath = _byText?[text];
    if (relPath == null) {
      debugPrint(
        '[PrerecordedVoice] 无预录制文件，跳过："${text.substring(0, text.length.clamp(0, 20))}…"',
      );
      return;
    }

    final assetPath = '$assetBasePath/$relPath';
    debugPrint('[PrerecordedVoice] 播放：$assetPath');

    try {
      await _player.setAudioSource(AudioSource.asset(assetPath));
      await _player.play();

      await _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      debugPrint('[PrerecordedVoice] 播放超时，强制停止');
    } catch (e) {
      debugPrint('[PrerecordedVoice] 播放失败：$e');
    } finally {
      await _player.stop();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// 释放 AudioPlayer 资源（OperatorVoice 生命周期结束时调用）
  Future<void> dispose() async {
    await _player.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FallbackVoiceBackend
// ─────────────────────────────────────────────────────────────────────────────

/// 降级后端：优先播放预录制音频，无对应文件时自动 fallback 到 TTS。
///
/// 适合过渡期：部分台词已预录，动态台词（如 confirmId）仍走 TTS。
///
/// ```dart
/// final backend = FallbackVoiceBackend(
///   prerecorded: PrerecordedVoiceBackend(),
///   tts: TtsVoiceBackend(_voice),
/// );
/// ```
class FallbackVoiceBackend implements OperatorVoiceBackend {
  final PrerecordedVoiceBackend prerecorded;
  final TtsVoiceBackend tts;

  const FallbackVoiceBackend({required this.prerecorded, required this.tts});

  @override
  Future<void> play(OperatorPersonality op, String text) async {
    if (await prerecorded.hasAudio(text)) {
      await prerecorded.play(op, text);
    } else {
      debugPrint(
        '[FallbackVoice] 无预录制，转 TTS："${text.substring(0, text.length.clamp(0, 20))}…"',
      );
      await tts.play(op, text);
    }
  }

  @override
  Future<void> stop() async {
    await prerecorded.stop();
    await tts.stop();
  }

  Future<void> dispose() async {
    await prerecorded.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OperatorVoice - 业务层对接口
// ─────────────────────────────────────────────────────────────────────────────

/// 接线员台词播放器
///
/// 封装台词随机选取、接线员音色参数、以及播放后端，让业务层只关心"播哪个阶段"。
///
/// ```dart
/// // 创建（PagerVM 持有）
/// final _operatorVoice = OperatorVoice(
///   operator: _operator,
///   backend: TtsVoiceBackend(_voice),
/// );
///
/// // 播放
/// final text = await _operatorVoice.say(OperatorLine.greeting, onText: (t) {
///   _currentDialogue = t;
///   notifyListeners();
/// });
///
/// // confirmId 示例（并行 API 请求时使用 onText 提前显示文字）
/// await Future.wait([
///   _operatorVoice.say(OperatorLine.confirmId, param: targetId, onText: (t) {
///     _currentDialogue = t;
///     notifyListeners();
///   }),
///   apiCallFuture,
/// ]);
/// ```
class OperatorVoice {
  OperatorPersonality _operator;
  final OperatorVoiceBackend _backend;

  OperatorVoice({
    required OperatorPersonality operator,
    required OperatorVoiceBackend backend,
  }) : _operator = operator,
       _backend = backend;

  /// 切换当前接线员（例如用户手动选择后调用）
  void setOperator(OperatorPersonality op) {
    _operator = op;
  }

  /// 播放指定台词阶段。
  ///
  /// - [param] 对 [OperatorLine.confirmId] 为必传的 targetId 字符串。
  /// - [onText] 在播放**开始前**同步回调已选定的台词文本，可用于 UI 提前显示。
  ///
  /// 返回实际播放的台词文本。
  Future<String> say(
    OperatorLine line, {
    String? param,
    void Function(String text)? onText,
  }) async {
    final text = resolve(line, param: param);
    onText?.call(text);
    await _backend.play(_operator, text);
    return text;
  }

  /// 仅解析台词文本，不播放。
  ///
  /// 适用于需要提前知道台词内容（如并行显示与播放）的场景。
  String resolve(OperatorLine line, {String? param}) {
    final d = _operator.dialogues;
    return switch (line) {
      OperatorLine.greeting => d.getGreeting(),
      OperatorLine.askTarget => d.getAskTarget(),
      OperatorLine.confirmId => d.getConfirmId(param ?? ''),
      OperatorLine.requestMessage => d.getRequestMessage(),
      OperatorLine.userNotFound => d.getUserNotFound(),
      OperatorLine.successMessage => d.getSuccessMessage(),
      OperatorLine.askContinue => d.getAskContinue(),
      OperatorLine.randomPhrase => d.getRandomPhrase(),
    };
  }

  /// 停止当前播放
  Future<void> stop() => _backend.stop();
}
