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

  AssistantEvent(this.state, {this.text, this.error});
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

  /// 手动设置业务阶段（UI 可以监听 `phase`）
  void setPhase(AssistantPhase p) {
    if (phase.value != p) {
      phase.value = p;
      notifyListeners();
    }
  }

  String _currentOperatorId = 'op_system'; // 默认操作员
  String get currentOperatorId => _currentOperatorId;

  StreamSubscription<String>? _asrSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription? _audioInterruptionSub;
  StreamSubscription? _becomingNoisySub;

  final StreamController<AssistantEvent> _eventController =
      StreamController.broadcast();
  Stream<AssistantEvent> get onEvent => _eventController.stream;

  // 兼容旧API
  Stream<String> get onResult => _eventController.stream
      .where((event) => event.text != null)
      .map((event) => event.text!);

  // 公开音量流用于波形显示
  Stream<double> get onVolume => _asr.onVolume;

  /// 初始化所有引擎
  Future<void> init() async {
    try {
      await _asr.init();
      await _tts.init();
      // 订阅系统音频中断与 noisy 事件
      try {
        final session = await AudioSession.instance;
        _audioInterruptionSub = session.interruptionEventStream.listen((event) {
          try {
            // interruption event has 'begin' boolean
            final begin = (event as dynamic).begin as bool? ?? true;
            if (begin) {
              // interruption began: stop listening or stop playback
              if (state.value == AssistantState.listening) {
                // stopListening will handle releasing resources
                stopListening().catchError((_) {});
              }
              // if speaking, cancel playback and release audio
              try {
                _audioRelease?.call();
              } catch (_) {}
              _audioRelease = null;
              _setState(AssistantState.idle);
              setPhase(AssistantPhase.error);
            } else {
              // interruption ended - nothing for now
            }
          } catch (_) {}
        });

        _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
          try {
            // e.g. headphones unplugged
            if (state.value == AssistantState.listening) {
              stopListening().catchError((_) {});
            }
            try {
              _audioRelease?.call();
            } catch (_) {}
            _audioRelease = null;
            _setState(AssistantState.idle);
          } catch (_) {}
        });
      } catch (e) {
        // audio_session may fail on some platforms; ignore
      }
      logger.i('AssistantController initialized');
    } catch (e) {
      logger.e('AssistantController init failed: $e');
      rethrow;
    }
  }

  VoidCallback? _audioRelease;
  bool _messageFirstMode = false;

  /// 开始语音监听
  ///
  /// 参数：
  /// - messageFirst: 是否为先录音后填ID的流程
  /// - acquireTimeout: 当音频资源不可用时，等待的最长时长（null = 无限等待）
  Future<void> startListening({
    bool messageFirst = false,
    Duration? acquireTimeout,
  }) async {
    if (state.value != AssistantState.idle) return;
    _messageFirstMode = messageFirst;

    try {
      _setState(AssistantState.listening);
      setPhase(AssistantPhase.recording);

      // 尝试快速获取音频资源（非阻塞），若失败则等待 acquire（可带超时）
      _audioRelease = await _audioManager.tryAcquire();
      if (_audioRelease == null) {
        _audioRelease = await _audioManager.acquire(timeout: acquireTimeout);
      }

      // 启动ASR
      await _asr.startRecording();

      // 监听结果
      _asrSubscription = _asr.onResult.listen((text) {
        _currentText = text;
        // 向外发布包含文本的事件，兼容旧API与UI同步
        _eventController.add(AssistantEvent(state.value, text: text));
        notifyListeners();
      });

      _volumeSubscription = _asr.onVolume.listen((volume) {
        // 可用于UI波形更新
      });
    } catch (e) {
      logger.e('Start listening failed: $e');
      _setState(AssistantState.idle);
      try {
        _audioRelease?.call();
      } catch (_) {}
      _audioRelease = null;
      rethrow;
    }
  }

  /// 停止监听并处理结果
  Future<void> stopListening() async {
    if (state.value != AssistantState.listening) return;

    try {
      await _asr.stop();
      _audioRelease?.call();
      _audioRelease = null;

      _asrSubscription?.cancel();
      _volumeSubscription?.cancel();

      if (_currentText?.isNotEmpty == true) {
        // 进入处理阶段
        setPhase(AssistantPhase.transcribing);
        await _processText(_currentText!);
        // 使用完后重置 message-first 模式
        _messageFirstMode = false;
      } else {
        _setState(AssistantState.idle);
        _messageFirstMode = false;
      }
    } catch (e) {
      logger.e('Stop listening failed: $e');
      _setState(AssistantState.idle);
      rethrow;
    }
  }

  /// 发送当前文本
  Future<void> send() async {
    if ((_currentText?.isEmpty ?? true) || _currentRecipientId == null) return;

    try {
      _setState(AssistantState.thinking);
      setPhase(AssistantPhase.sending);

      // 发送消息
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

  /// 重播最后的消息
  Future<void> replay() async {
    if (_currentText?.isEmpty ?? true) return;

    try {
      _setState(AssistantState.speaking);
      setPhase(AssistantPhase.sent);

      // 获取音频资源
      _audioRelease = await _audioManager.acquire();

      // 生成并播放TTS
      final audio = await _tts.generate(text: _currentText!);
      if (audio != null) {
        // 生成并播放TTS音频（尝试将生成结果转换为可播放的 WAV/PCM）
        await _playGeneratedAudio(audio);
      }

      _audioRelease?.call();
      _audioRelease = null;
      _setState(AssistantState.idle);
      setPhase(AssistantPhase.idle);
    } catch (e) {
      logger.e('Replay failed: $e');
      _audioRelease?.call();
      _audioRelease = null;
      _setState(AssistantState.idle);
      setPhase(AssistantPhase.error);
      rethrow;
    }
  }

  /// 设置接收者
  void setRecipient(String recipientId) {
    _currentRecipientId = recipientId;
    notifyListeners();

    // 如果当前处于等待填写接收者（比如 message-first 流程），
    // 触发确认提示但不阻塞调用者。
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

  /// 取消当前操作
  Future<void> cancel() async {
    await stopListening();
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
    // 简单的文本处理逻辑，可扩展NLP
    _setState(AssistantState.thinking);

    // 模拟处理延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 关键词识别和流程控制
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
      // 支持“先录音后填ID”的模式：若设置了 messageFirst，则把识别到的文本当作消息内容
      if (_messageFirstMode) {
        _currentText = text;
        setPhase(AssistantPhase.confirmMessage);
        await speakScript('confirmMessage', {'message': text});
        // 进入等待填入收信方ID的阶段
        setPhase(AssistantPhase.askRecipientId);
        _setState(AssistantState.idle);
      } else {
        // 如果还没有接收者ID，认为是接收者ID
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
      // 确认接收者ID，开始录制消息
      setPhase(AssistantPhase.guideRecordMessage);
      await speakScript('guideRecordMessage');
      _setState(AssistantState.idle);
    } else if (matchesKeyword(text, 'modify')) {
      // 修改接收者ID
      _currentRecipientId = null;
      setPhase(AssistantPhase.askRecipientId);
      await speakScript('askRecipientId');
      _setState(AssistantState.idle);
    } else {
      // 认为是消息内容
      setPhase(AssistantPhase.confirmMessage);
      await speakScript('confirmMessage', {'message': text});
      _setState(AssistantState.idle);
    }
  }

  /// 从文本中提取接收者ID（简化实现）
  String? _extractRecipientId(String text) {
    // 简单的数字提取逻辑
    final RegExp digitRegex = RegExp(r'\d+');
    final match = digitRegex.firstMatch(text);
    return match?.group(0);
  }

  /// 设置当前操作员
  void setOperator(String operatorId) {
    if (_config.getOperatorConfig(operatorId) != null) {
      _currentOperatorId = operatorId;
      notifyListeners();
    }
  }

  /// 获取当前操作员配置
  Map<String, dynamic>? getCurrentOperatorConfig() {
    return _config.getOperatorConfig(_currentOperatorId);
  }

  /// 播放操作员脚本
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
      await _speakText(script);
    }
  }

  /// 对外暴露的直接朗读文本接口（可指定说话人id和语速）
  Future<void> speakText(String text, {int sid = 0, double speed = 1.0}) async {
    if (text.isEmpty) return;

    try {
      _setState(AssistantState.speaking);

      // 获取音频资源
      final audioRelease = await _audioManager.acquire();

      // 生成并播放TTS
      final audio = await _tts.generate(text: text, sid: sid, speed: speed);
      if (audio != null) {
        await _playGeneratedAudio(audio);
      }

      audioRelease();
      _setState(AssistantState.idle);
    } catch (e) {
      logger.e('Speak text failed: $e');
      _setState(AssistantState.idle);
    }
  }

  /// 播放应用内音频资源（asset），并由 AssistantController 统一管理音频互斥
  Future<void> playAsset(String assetPath) async {
    if (assetPath.isEmpty) return;

    try {
      _setState(AssistantState.speaking);

      // 获取音频资源互斥锁
      final audioRelease = await _audioManager.acquire();

      final player = AudioPlayer();
      final Completer<void> played = Completer<void>();
      final sub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (!played.isCompleted) played.complete();
        }
      });

      try {
        // just_audio expects asset paths defined in pubspec; use setAsset
        await player.setAsset(assetPath);
        await player.play();
        await played.future;
      } catch (e) {
        logger.e('playAsset failed: $e');
      } finally {
        try {
          await player.stop();
        } catch (_) {}
        try {
          await player.dispose();
        } catch (_) {}
        try {
          await sub.cancel();
        } catch (_) {}
        // 释放资源
        try {
          audioRelease();
        } catch (_) {}
      }

      _setState(AssistantState.idle);
    } catch (e) {
      logger.e('playAsset failed: $e');
      _setState(AssistantState.idle);
    }
  }

  /// 检查文本是否匹配关键词
  bool matchesKeyword(String text, String keywordGroup) {
    return _config.matchesKeyword(text, keywordGroup);
  }

  /// 获取所有可用操作员
  List<String> getAvailableOperators() {
    return _config.getOperatorIds();
  }

  /// 语音播放文本（内部方法）
  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;

    try {
      _setState(AssistantState.speaking);

      // 获取音频资源
      final audioRelease = await _audioManager.acquire();

      // 生成并播放TTS
      final audio = await _tts.generate(
        text: text,
        sid: _getCurrentOperatorTtsSid(),
      );
      if (audio != null) {
        await _playGeneratedAudio(audio);
      }

      audioRelease();
      _setState(AssistantState.idle);
    } catch (e) {
      logger.e('Speak text failed: $e');
      _setState(AssistantState.idle);
    }
  }

  /// 获取当前操作员的TTS说话人ID
  int _getCurrentOperatorTtsSid() {
    final config = getCurrentOperatorConfig();
    return config?['ttsSid'] ?? 0;
  }

  /// 将生成的音频对象转换为 WAV（若需要）并播放。
  Future<void> _playGeneratedAudio(dynamic audio) async {
    if (audio == null) return;

    Uint8List? wavBytes;

    try {
      // case 1: audio already Uint8List (raw wav/pcm)
      if (audio is Uint8List) {
        wavBytes = audio;
      }

      // case 2: check common field names dynamically
      if (wavBytes == null) {
        try {
          final dynamic maybe = audio.pcm16 ?? audio.bytes ?? audio.data;
          if (maybe is Uint8List) {
            wavBytes = maybe;
          }
        } catch (_) {}
      }

      // case 3: convert float samples -> pcm16 + wav
      if (wavBytes == null) {
        try {
          final dynamic samples = audio.samples ?? audio.floatSamples;
          final int sampleRate =
              (audio.sampleRate ?? audio.samplingRate ?? 16000) as int;
          final int channels = (audio.channels ?? 1) as int;
          if (samples != null) {
            Float32List floatSamples;
            if (samples is Float32List) {
              floatSamples = samples;
            } else if (samples is List<double>) {
              floatSamples = Float32List.fromList(samples);
            } else if (samples is List) {
              floatSamples = Float32List.fromList(
                samples.map((e) => (e as num).toDouble()).toList(),
              );
            } else {
              floatSamples = Float32List(0);
            }

            if (floatSamples.isNotEmpty) {
              final pcm = Uint8List(floatSamples.length * 2);
              final bd = ByteData.view(pcm.buffer);
              for (var i = 0; i < floatSamples.length; i++) {
                var s = floatSamples[i];
                if (s > 1.0) s = 1.0;
                if (s < -1.0) s = -1.0;
                final int val = (s * 32767).toInt();
                bd.setInt16(i * 2, val, Endian.little);
              }
              wavBytes = _buildWav(pcm, sampleRate, channels);
            }
          }
        } catch (e, st) {
          logger.e('convert generated audio failed: $e\n$st');
        }
      }
    } catch (e, st) {
      logger.e('_playGeneratedAudio preparation failed: $e\n$st');
    }

    if (wavBytes == null) {
      // fallback to a short delay so caller still observes timing
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // write bytes to a temporary file and play via just_audio
    final dir = await getTemporaryDirectory();
    final tmp = File(
      '${dir.path}/bipupu_tts_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    try {
      await tmp.writeAsBytes(wavBytes);

      final player = AudioPlayer();
      final Completer<void> played = Completer<void>();
      final sub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (!played.isCompleted) played.complete();
        }
      });

      try {
        await player.setFilePath(tmp.path);
        await player.play();
        await played.future;
      } catch (e) {
        logger.e('playback failed: $e');
      } finally {
        try {
          await player.stop();
        } catch (_) {}
        try {
          await player.dispose();
        } catch (_) {}
        try {
          await sub.cancel();
        } catch (_) {}
      }
    } finally {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
    }
  }

  Uint8List _buildWav(Uint8List pcmBytes, int sampleRate, int channels) {
    final int byteRate = sampleRate * channels * 2;
    final int blockAlign = channels * 2;
    final int dataLen = pcmBytes.length;
    final int riffChunkSize = 36 + dataLen;

    final bytes = BytesBuilder();
    // RIFF header
    bytes.add(asciiEncode('RIFF'));
    bytes.add(_u32le(riffChunkSize));
    bytes.add(asciiEncode('WAVE'));

    // fmt subchunk
    bytes.add(asciiEncode('fmt '));
    bytes.add(_u32le(16)); // subchunk1 size
    bytes.add(_u16le(1)); // PCM
    bytes.add(_u16le(channels));
    bytes.add(_u32le(sampleRate));
    bytes.add(_u32le(byteRate));
    bytes.add(_u16le(blockAlign));
    bytes.add(_u16le(16)); // bits per sample

    // data subchunk
    bytes.add(asciiEncode('data'));
    bytes.add(_u32le(dataLen));
    bytes.add(pcmBytes);

    return bytes.toBytes();
  }

  List<int> asciiEncode(String s) => s.codeUnits;

  List<int> _u16le(int v) {
    final b = ByteData(2);
    b.setUint16(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  List<int> _u32le(int v) {
    final b = ByteData(4);
    b.setUint32(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  /// 清理（可在应用退出时调用）
  @override
  void dispose() {
    try {
      _audioInterruptionSub?.cancel();
    } catch (_) {}
    try {
      _becomingNoisySub?.cancel();
    } catch (_) {}
    try {
      _asrSubscription?.cancel();
    } catch (_) {}
    try {
      _volumeSubscription?.cancel();
    } catch (_) {}
    try {
      _eventController.close();
    } catch (_) {}
    super.dispose();
  }
}
