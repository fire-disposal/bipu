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
      if (_verboseLogging) logger.i('TTS model paths extracted: $paths');

      final config = _buildTtsConfig(paths);
      if (_verboseLogging) logger.i('TTS config built successfully');

      _tts = sherpa.OfflineTts(config);
      if (_verboseLogging) logger.i('Sherpa OfflineTts instance created');

      _isInitialized = true;
      if (_verboseLogging) logger.i('TTSEngine initialized successfully');
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
      if (_verboseLogging)
        logger.i('Extracted key: $extractedKey from $key, path: $p');
      paths[extractedKey] = p;
    }
    return paths;
  }

  sherpa.OfflineTtsConfig _buildTtsConfig(Map<String, String> paths) {
    if (_verboseLogging) logger.i('Building TTS config with paths: $paths');

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

    if (_verboseLogging) logger.i('VITS model config created successfully');

    final ruleFsts =
        '${paths[VoiceConfig.ttsPhone]},${paths[VoiceConfig.ttsDate]},${paths[VoiceConfig.ttsNumber]},${paths[VoiceConfig.ttsHeteronym]}';
    if (_verboseLogging) logger.i('Rule FSTs: $ruleFsts');

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
  }) async {
    if (!_isInitialized || _tts == null) {
      if (_verboseLogging) logger.i('TTS not initialized, calling init()');
      await init();
    }

    // 检查 _tts 是否成功初始化
    if (_tts == null) {
      logger.e('TTS engine not initialized properly after init() call');
      logger.e('_isInitialized: $_isInitialized, _tts: $_tts');
      return null;
    }

    try {
      if (_verboseLogging)
        logger.i('Generating TTS for text: "$text", sid: $sid, speed: $speed');
      return _tts!.generate(text: text, sid: sid, speed: speed);
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
