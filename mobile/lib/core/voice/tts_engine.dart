import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import 'voice_config.dart';
import '../utils/logger.dart';

class TTSEngine {
  static final TTSEngine _instance = TTSEngine._internal();

  factory TTSEngine() => _instance;

  TTSEngine._internal();

  sherpa.OfflineTts? _tts;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  static const bool _verboseLogging = kDebugMode;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      sherpa.initBindings();

      await ModelManager.instance.ensureInitialized(VoiceConfig.ttsModelFiles);

      final paths = _extractModelPaths(VoiceConfig.ttsModelFiles);
      final config = _buildTtsConfig(paths);

      _tts = sherpa.OfflineTts(config);
      _isInitialized = true;
      logger.i('✅ TTSEngine 初始化完成');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e(
        'TTSEngine initialization failed.',
        error: e,
        stackTrace: stackTrace,
      );
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Map<String, String> _extractModelPaths(Map<String, String> modelFiles) {
    final paths = <String, String>{};
    for (final key in modelFiles.keys) {
      final p = ModelManager.instance.getModelPath(key);
      if (p == null) {
        logger.e('ModelManager failed to prepare model: $key');
        throw Exception('ModelManager failed to prepare $key');
      }
      final extractedKey = key.split('/').last.split('.').first;
      paths[extractedKey] = p;
    }
    return paths;
  }

  sherpa.OfflineTtsConfig _buildTtsConfig(Map<String, String> paths) {
    // 检查必需的路径是否存在
    final requiredKeys = [
      VoiceConfig.ttsModel,
      VoiceConfig.ttsLexicon,
      VoiceConfig.ttsTokens,
    ];
    for (final key in requiredKeys) {
      if (!paths.containsKey(key)) {
        logger.e('Missing required TTS model key: $key');
        logger.e('Available keys: ${paths.keys.toList()}');
        throw Exception('Missing required TTS model key: $key');
      }
    }

    final vits = sherpa.OfflineTtsVitsModelConfig(
      model: paths[VoiceConfig.ttsModel]!,
      lexicon: paths[VoiceConfig.ttsLexicon]!,
      tokens: paths[VoiceConfig.ttsTokens]!,
    );

    final ruleFsts =
        '${paths[VoiceConfig.ttsPhone]},${paths[VoiceConfig.ttsDate]},${paths[VoiceConfig.ttsNumber]},${paths[VoiceConfig.ttsHeteronym]}';

    return sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: vits,
        numThreads: VoiceConfig.ttsNumThreads,
        debug: VoiceConfig.ttsDebug,
      ),
      ruleFsts: ruleFsts,
    );
  }

  Future<sherpa.GeneratedAudio?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized || _tts == null) {
      await init();
    }

    // 检查 _tts 是否成功初始化
    if (_tts == null) {
      logger.e('TTS engine not initialized properly after init() call');
      logger.e('_isInitialized: $_isInitialized, _tts: $_tts');
      return null;
    }

    try {
      if (_verboseLogging) {
        logger.i('Generating TTS for text: "$text", sid: $sid, speed: $speed');
      }

      // OfflineTts.generate() 是同步方法，在 Future 中执行以便应用超时保护
      final generationFuture = Future.microtask(
        () => _tts!.generate(text: text, sid: sid, speed: speed),
      );

      return await generationFuture.timeout(timeout);
    } on TimeoutException {
      logger.e('TTS generation timeout after ${timeout.inSeconds}s: "$text"');
      return null;
    } catch (e, stackTrace) {
      logger.e('Error generating TTS: $e\n$stackTrace');
      return null;
    }
  }

  void dispose() {
    _tts?.free();
    _tts = null;
    _isInitialized = false;
  }
}
