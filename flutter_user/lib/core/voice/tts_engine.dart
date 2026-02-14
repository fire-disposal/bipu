import 'dart:async';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
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

      final modelFiles = {
        'tts/vits-aishell3.onnx': 'assets/models/tts/vits-aishell3.onnx',
        'tts/tokens.txt': 'assets/models/tts/tokens.txt',
        'tts/lexicon.txt': 'assets/models/tts/lexicon.txt',
        'tts/phone.fst': 'assets/models/tts/phone.fst',
        'tts/date.fst': 'assets/models/tts/date.fst',
        'tts/number.fst': 'assets/models/tts/number.fst',
        'tts/new_heteronym.fst': 'assets/models/tts/new_heteronym.fst',
      };

      await ModelManager.instance.ensureInitialized(modelFiles);

      final paths = <String, String>{};
      for (final key in modelFiles.keys) {
        final p = ModelManager.instance.getModelPath(key);
        if (p == null) throw Exception('ModelManager failed to prepare $key');
        paths[key.split('/').last.split('.').first] = p;
      }

      final vits = sherpa.OfflineTtsVitsModelConfig(
        model: paths['vits-aishell3']!,
        lexicon: paths['lexicon']!,
        tokens: paths['tokens']!,
      );

      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: vits,
          numThreads: 1,
          debug: false,
        ),
        ruleFsts:
            '${paths['phone']},${paths['date']},${paths['number']},${paths['new_heteronym']}',
      );

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

  Future<sherpa.GeneratedAudio?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
  }) async {
    if (!_isInitialized || _tts == null) {
      await init();
    }
    try {
      final audio = _tts!.generate(text: text, sid: sid, speed: speed);
      return audio;
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
