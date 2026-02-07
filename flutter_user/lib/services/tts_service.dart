import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import '../core/utils/logger.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

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

      // TODO: Extract these to a configuration file or remote config if needed
      const modelDir = 'assets/models/tts';
      const modelFiles = {
        'model': '$modelDir/vits-aishell3.onnx',
        'tokens': '$modelDir/tokens.txt',
        'lexicon': '$modelDir/lexicon.txt',
        'phoneFst': '$modelDir/phone.fst',
        'dateFst': '$modelDir/date.fst',
        'numberFst': '$modelDir/number.fst',
        'newHeteronymFst': '$modelDir/new_heteronym.fst',
      };

      // 2. Copy assets to local storage so C++ can access them
      final paths = <String, String>{};

      for (final entry in modelFiles.entries) {
        final path = await _copyAssetToLocal(entry.value);
        if (path == null) {
          throw Exception('Failed to load critical asset: ${entry.value}');
        }
        paths[entry.key] = path;
      }

      final vits = sherpa.OfflineTtsVitsModelConfig(
        model: paths['model']!,
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
            '${paths['phoneFst']},${paths['dateFst']},${paths['numberFst']},${paths['newHeteronymFst']}',
      );

      _tts = sherpa.OfflineTts(config);

      _isInitialized = true;
      logger.i('TtsService initialized successfully');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e(
        'TtsService initialization failed.',
        error: e,
        stackTrace: stackTrace,
      );
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<String?> _copyAssetToLocal(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      final appDir = await getApplicationSupportDirectory();
      final modelCacheDir = Directory('${appDir.path}/models/tts');
      if (!await modelCacheDir.exists()) {
        await modelCacheDir.create(recursive: true);
      }

      final fileName = assetPath.split('/').last;
      final localPath = '${modelCacheDir.path}/$fileName';
      final file = File(localPath);

      // Integrity check
      if (await file.exists()) {
        final existingSize = await file.length();
        if (existingSize == bytes.length) {
          return localPath;
        }
      }

      await file.writeAsBytes(bytes, flush: true);
      return localPath;
    } catch (e) {
      logger.e('Failed to copy asset $assetPath: $e');
      return null;
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
      // OfflineTts.generate is a synchronous FFI call that might be heavy
      // We wrap it in a try-catch to ensure UI doesn't crash on model errors
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
