import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/voice/asr_engine.dart';
import '../../core/voice/tts_engine.dart';
import '../../core/services/im_service.dart';
import '../../core/voice/audio_resource_manager.dart';
import '../../core/utils/logger.dart';
import 'assistant_config.dart';
import 'package:audio_session/audio_session.dart';

/// 语音助手状态枚举
enum AssistantState { idle, listening, thinking, speaking }

/// 更细粒度的业务阶段，用于驱动引导式 UI 与进度条
enum AssistantPhase {
  idle,
  greeting,
  askRecipientId,
  confirmRecipientId,
  guideRecordMessage,
  recording,
  transcribing,
  confirmMessage,
  sending,
  sent,
  farewell,
  error,
}

/// 语音助手事件
class AssistantEvent {
  final AssistantState state;
  final String? text;
  final String? error;
  final bool isOperator; // 是否为操作员发出的文本

  AssistantEvent(this.state, {this.text, this.error, this.isOperator = false});
}

/// 语音助手控制器 - 重新聚合精简的服务层
class AssistantController extends ChangeNotifier {
  static final AssistantController _instance = AssistantController._internal();
  factory AssistantController() => _instance;

  AssistantController._internal();

  final ASREngine _asr = ASREngine();
  final TTSEngine _tts = TTSEngine();
  final ImService _imService = ImService();
  final AudioResourceManager _audioManager = AudioResourceManager();
  final AssistantConfig _config = AssistantConfig();

  final ValueNotifier<AssistantState> state = ValueNotifier(
    AssistantState.idle,
  );
  final ValueNotifier<AssistantPhase> phase = ValueNotifier<AssistantPhase>(
    AssistantPhase.idle,
  );

  String? _currentText;
  String? get currentText => _currentText;

  String? _currentRecipientId;
  String? get currentRecipientId => _currentRecipientId;

  AssistantPhase get currentPhase => phase.value;

  void setPhase(AssistantPhase p) {
    if (phase.value != p) {
      phase.value = p;
      notifyListeners();
    }
  }

  String _currentOperatorId = 'op_system'; // 默认操作员
  String get currentOperatorId => _currentOperatorId;

  StreamSubscription<String>? _asrSubscription;
  StreamSubscription? _audioInterruptionSub;
  StreamSubscription? _becomingNoisySub;

  final StreamController<AssistantEvent> _eventController =
      StreamController.broadcast();
  Stream<AssistantEvent> get onEvent => _eventController.stream;

  Stream<String> get onResult => _asr.onResult;
  Stream<double> get onVolume => _asr.onVolume;

  Future<void> init() async {
    try {
      await _asr.init();
      await _tts.init();

      final session = await AudioSession.instance;
      _audioInterruptionSub = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _handleInterruption();
        }
      });

      _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
        _handleInterruption();
      });

      logger.i('AssistantController initialized');
    } catch (e) {
      logger.e('AssistantController init failed: $e');
      rethrow;
    }
  }

  void _handleInterruption() {
    if (state.value == AssistantState.listening) {
      stopListening().catchError((_) {});
    }
    _audioRelease?.call();
    _audioRelease = null;
    _setState(AssistantState.idle);
    setPhase(AssistantPhase.error);
  }

  VoidCallback? _audioRelease;
  bool _messageFirstMode = false;

  Future<void> startListening({
    bool messageFirst = false,
    Duration? acquireTimeout,
  }) async {
    if (state.value != AssistantState.idle) return;
    _messageFirstMode = messageFirst;

    try {
      _setState(AssistantState.listening);
      setPhase(AssistantPhase.recording);

      _audioRelease = await _audioManager.tryAcquire();
      if (_audioRelease == null) {
        _audioRelease = await _audioManager.acquire(timeout: acquireTimeout);
      }

      await _asr.startRecording();

      _asrSubscription = _asr.onResult.listen((text) {
        _currentText = text;
        _eventController.add(AssistantEvent(state.value, text: text));
        notifyListeners();
      });
    } catch (e) {
      logger.e('Start listening failed: $e');
      _setState(AssistantState.idle);
      _audioRelease?.call();
      _audioRelease = null;
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (state.value != AssistantState.listening) return;

    try {
      final finalResult = await _asr.stop();
      _audioRelease?.call();
      _audioRelease = null;

      await _asrSubscription?.cancel();
      _asrSubscription = null;

      if (finalResult.isNotEmpty) {
        _currentText = finalResult;
        setPhase(AssistantPhase.transcribing);
        await _processText(finalResult);
      } else {
        _setState(AssistantState.idle);
      }
      _messageFirstMode = false;
    } catch (e) {
      logger.e('Stop listening failed: $e');
      _setState(AssistantState.idle);
      rethrow;
    }
  }

  Future<void> send() async {
    if ((_currentText?.isEmpty ?? true) || _currentRecipientId == null) return;

    try {
      _setState(AssistantState.thinking);
      setPhase(AssistantPhase.sending);

      await _imService.messageApi.sendMessage(
        receiverId: _currentRecipientId!,
        content: _currentText!,
        msgType: 'USER_POSTCARD',
      );

      _currentText = null;
      setPhase(AssistantPhase.sent);
      _setState(AssistantState.idle);
      notifyListeners();
    } catch (e) {
      logger.e('Send failed: $e');
      setPhase(AssistantPhase.error);
      _setState(AssistantState.idle);
      rethrow;
    }
  }

  Future<void> replay() async {
    if (_currentText?.isEmpty ?? true) return;
    await _speakText(_currentText!);
  }

  void setRecipient(String recipientId) {
    _currentRecipientId = recipientId;
    notifyListeners();

    if (_currentRecipientId?.isNotEmpty == true &&
        phase.value == AssistantPhase.askRecipientId) {
      Future.microtask(() async {
        setPhase(AssistantPhase.confirmRecipientId);
        await speakScript('confirmRecipientId', {
          'recipientId': _currentRecipientId!,
        });
      });
    }
  }

  Future<void> cancel() async {
    if (state.value == AssistantState.listening) {
      await _asr.stop();
    }
    _audioRelease?.call();
    _audioRelease = null;
    _currentText = null;
    _setState(AssistantState.idle);
    setPhase(AssistantPhase.idle);
    notifyListeners();
  }

  void _setState(AssistantState newState) {
    if (state.value != newState) {
      state.value = newState;
      _eventController.add(AssistantEvent(newState, text: _currentText));
      notifyListeners();
    }
  }

  Future<void> _processText(String text) async {
    _setState(AssistantState.thinking);
    await Future.delayed(const Duration(milliseconds: 500));

    if (matchesKeyword(text, 'cancel')) {
      await speakScript('farewell');
      await cancel();
    } else if (matchesKeyword(text, 'send')) {
      await send();
    } else if (matchesKeyword(text, 'rerecord')) {
      await speakScript('guideRecordMessage');
      _currentText = null;
      setPhase(AssistantPhase.guideRecordMessage);
      _setState(AssistantState.idle);
    } else if (_currentRecipientId == null) {
      if (_messageFirstMode) {
        _currentText = text;
        setPhase(AssistantPhase.confirmMessage);
        await speakScript('confirmMessage', {'message': text});
        setPhase(AssistantPhase.askRecipientId);
        _setState(AssistantState.idle);
      } else {
        _currentRecipientId = _extractRecipientId(text);
        if (_currentRecipientId != null) {
          setPhase(AssistantPhase.confirmRecipientId);
          await speakScript('confirmRecipientId', {
            'recipientId': _currentRecipientId!,
          });
        } else {
          setPhase(AssistantPhase.askRecipientId);
          await speakScript('clarify');
        }
        _setState(AssistantState.idle);
      }
    } else if (matchesKeyword(text, 'confirm')) {
      setPhase(AssistantPhase.guideRecordMessage);
      await speakScript('guideRecordMessage');
      _setState(AssistantState.idle);
    } else if (matchesKeyword(text, 'modify')) {
      _currentRecipientId = null;
      setPhase(AssistantPhase.askRecipientId);
      await speakScript('askRecipientId');
      _setState(AssistantState.idle);
    } else {
      setPhase(AssistantPhase.confirmMessage);
      await speakScript('confirmMessage', {'message': text});
      _setState(AssistantState.idle);
    }
  }

  String? _extractRecipientId(String text) {
    final RegExp digitRegex = RegExp(r'\d+');
    final match = digitRegex.firstMatch(text);
    return match?.group(0);
  }

  void setOperator(String operatorId) {
    if (_config.getOperatorConfig(operatorId) != null) {
      _currentOperatorId = operatorId;
      notifyListeners();
    }
  }

  Map<String, dynamic>? getCurrentOperatorConfig() {
    return _config.getOperatorConfig(_currentOperatorId);
  }

  Future<void> speakScript(
    String scriptKey, [
    Map<String, String>? params,
  ]) async {
    final script = _config.getOperatorScript(
      _currentOperatorId,
      scriptKey,
      params,
    );
    if (script.isNotEmpty) {
      // 立即发布文本事件，不等待 TTS 合成
      _eventController.add(
        AssistantEvent(state.value, text: script, isOperator: true),
      );

      // 异步尝试播放 TTS，不阻塞交互逻辑
      unawaited(
        _speakText(script).catchError((e) {
          logger.e('TTS playback failed in speakScript: $e');
        }),
      );
    }
  }

  Future<void> speakText(String text, {int sid = 0, double speed = 1.0}) async {
    if (text.isEmpty) return;
    // 立即发布文本事件
    _eventController.add(
      AssistantEvent(state.value, text: text, isOperator: true),
    );
    // 异步尝试播放
    unawaited(
      _speakText(text, sid: sid, speed: speed).catchError((e) {
        logger.e('TTS playback failed in speakText: $e');
      }),
    );
  }

  Future<void> _speakText(String text, {int? sid, double speed = 1.0}) async {
    try {
      _setState(AssistantState.speaking);
      final release = await _audioManager.acquire();

      try {
        final targetSid = sid ?? _getCurrentOperatorTtsSid();
        final result = await _tts.generate(
          text: text,
          sid: targetSid,
          speed: speed,
        );

        if (result != null) {
          final pcm = result.toPCM16();
          if (pcm != null) {
            final wav = _buildWav(pcm, 16000, 1);
            await _playWav(wav);
          }
        }
      } finally {
        release();
        _setState(AssistantState.idle);
      }
    } catch (e) {
      logger.e('Internal _speakText failed: $e');
      _setState(AssistantState.idle);
      // 不再向上抛出异常，确保不中断调用者的逻辑
    }
  }

  int _getCurrentOperatorTtsSid() {
    final config = getCurrentOperatorConfig();
    return config?['ttsSid'] ?? 0;
  }

  Future<void> _playWav(Uint8List wavBytes) async {
    final dir = await getTemporaryDirectory();
    final tmp = File(
      '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await tmp.writeAsBytes(wavBytes);

    final player = AudioPlayer();
    try {
      await player.setFilePath(tmp.path);
      await player.play();
      // Wait for completion
      await player.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      );
    } finally {
      await player.dispose();
      if (await tmp.exists()) await tmp.delete();
    }
  }

  Uint8List _buildWav(Uint8List pcmBytes, int sampleRate, int channels) {
    final int byteRate = sampleRate * channels * 2;
    final int blockAlign = channels * 2;
    final int dataLen = pcmBytes.length;
    final int riffChunkSize = 36 + dataLen;

    final bytes = BytesBuilder();
    bytes.add('RIFF'.codeUnits);
    bytes.add(_u32le(riffChunkSize));
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    bytes.add(_u32le(16));
    bytes.add(_u16le(1));
    bytes.add(_u16le(channels));
    bytes.add(_u32le(sampleRate));
    bytes.add(_u32le(byteRate));
    bytes.add(_u16le(blockAlign));
    bytes.add(_u16le(16));
    bytes.add('data'.codeUnits);
    bytes.add(_u32le(dataLen));
    bytes.add(pcmBytes);

    return bytes.toBytes();
  }

  Uint8List _u16le(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  Uint8List _u32le(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  bool matchesKeyword(String text, String keywordGroup) {
    return _config.matchesKeyword(text, keywordGroup);
  }

  @override
  void dispose() {
    _audioInterruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    _asrSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}
