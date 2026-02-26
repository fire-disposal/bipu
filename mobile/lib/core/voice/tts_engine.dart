import 'dart:async';
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
      logger.i('TTSEngine initialized successfully');
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
      if (p == null) throw Exception('ModelManager failed to prepare $key');
      paths[key.split('/').last.split('.').first] = p;
    }
    return paths;
  }

  sherpa.OfflineTtsConfig _buildTtsConfig(Map<String, String> paths) {
    final vits = sherpa.OfflineTtsVitsModelConfig(
      model: paths[VoiceConfig.ttsModel]!,
      lexicon: paths[VoiceConfig.ttsLexicon]!,
      tokens: paths[VoiceConfig.ttsTokens]!,
    );

    return sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: vits,
        numThreads: VoiceConfig.ttsNumThreads,
        debug: VoiceConfig.ttsDebug,
      ),
      ruleFsts:
          '${paths[VoiceConfig.ttsPhone]},${paths[VoiceConfig.ttsDate]},${paths[VoiceConfig.ttsNumber]},${paths[VoiceConfig.ttsHeteronym]}',
    );
  }

  Future<sherpa.GeneratedAudio?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
  }) async {
    if (!_isInitialized || _tts == null) {
      await init();
    }
    try {
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
