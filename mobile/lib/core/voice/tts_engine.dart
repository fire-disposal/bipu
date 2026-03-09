import 'dart:async';
import 'package:flutter/foundation.dart';
import 'model_manager.dart';
import 'voice_config.dart';
import 'tts_isolate.dart';
import '../utils/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TTSEngine — 统一 TTS 接口，内部委托给后台 Isolate
//
//  核心改变（相比旧版）：
//    - 不再在主 Isolate 持有 sherpa.OfflineTts 对象
//    - generate() 在后台 Isolate 执行 ONNX 推理，主线程完全异步等待
//    - generate() 返回类型 sherpa.GeneratedAudio? → List<int>?（PCM bytes）
//      调用方（VoiceService）无需再调用 _convertAudioToBytes()
// ─────────────────────────────────────────────────────────────────────────────

class TTSEngine {
  static final TTSEngine _instance = TTSEngine._internal();
  factory TTSEngine() => _instance;
  TTSEngine._internal();

  final TtsIsolateRunner _worker = TtsIsolateRunner();

  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  static const bool _verboseLogging = kDebugMode;

  bool get isInitialized => _isInitialized;

  /// 初始化：提取模型文件路径，启动后台 Isolate，在其中加载 ONNX 模型。
  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      // ① 确保模型文件已从 assets 解压到文件系统
      await ModelManager.instance.ensureInitialized(VoiceConfig.ttsModelFiles);

      // ② 提取文件系统绝对路径（语义化 key，解耦对具体文件名的依赖）
      final paths = _extractModelPaths();

      // ③ 启动后台 Isolate，在其中完成 sherpa.OfflineTts 初始化
      await _worker.spawn(
        modelPaths: paths,
        numThreads: VoiceConfig.ttsNumThreads,
        debug: VoiceConfig.ttsDebug,
      );

      _isInitialized = true;
      _initCompleter!.complete();
      logger.i('✅ TTSEngine 初始化完成（后台 Isolate 模式）');
    } catch (e, st) {
      logger.e('TTSEngine 初始化失败', error: e, stackTrace: st);
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  /// 生成 TTS 音频（在后台 Isolate 中执行，主线程不阻塞）。
  ///
  /// 返回 16-bit little-endian PCM bytes（24 kHz 单声道），失败时返回 null。
  Future<List<int>?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) await init();
    if (!_worker.isReady) {
      logger.e('TTSEngine.generate: Isolate 未就绪');
      return null;
    }

    if (_verboseLogging) {
      logger.i('TTSEngine.generate: "$text" sid=$sid spd=$speed');
    }

    final result = await _worker.generate(
      text: text,
      sid: sid,
      speed: speed,
      timeout: timeout,
    );

    if (result == null) {
      logger.w('TTSEngine.generate: 失败或超时 "$text"');
    }
    return result;
  }

  /// 释放后台 Isolate 及 native 资源。
  void dispose() {
    _worker.dispose();
    _isInitialized = false;
    _initCompleter = null;
  }

  // ─── 内部工具 ──────────────────────────────────────────────────────────────

  /// 将 VoiceConfig.ttsModelFiles 解析为文件系统绝对路径，
  /// 使用语义化 key 供后台 Isolate 构建 sherpa 配置时使用。
  Map<String, String> _extractModelPaths() {
    String req(String assetKey) {
      final p = ModelManager.instance.getModelPath(assetKey);
      if (p == null) throw Exception('ModelManager: $assetKey 未就绪');
      return p;
    }

    return {
      'onnx': req('tts/vits-zh-hf-fanchen-C.onnx'),
      'tokens': req('tts/tokens.txt'),
      'lexicon': req('tts/lexicon.txt'),
      'phone': req('tts/phone.fst'),
      'date': req('tts/date.fst'),
      'number': req('tts/number.fst'),
      'heteronym': req('tts/new_heteronym.fst'),
    };
  }
}
