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

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

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

    try {
      // 1. Validate assets existence in bundle (fail fast)
      // Note: rootBundle.load will throw if asset is missing, which is caught below.

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
      Logger.info('TtsService initialized successfully');
    } catch (e, stackTrace) {
      Logger.error(
        'TtsService initialization failed.\n'
        'Checklist:\n'
        '1. Do TTS model files exist in assets/models/?\n'
        '2. Ensure model.onnx, tokens.txt, lexicon.txt are present.\n'
        'Error: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<String?> _copyAssetToLocal(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final localPath = '${tempDir.path}/$fileName';

      final file = File(localPath);
      await file.writeAsBytes(bytes);

      return localPath;
    } catch (e) {
      Logger.error('Failed to copy asset $assetPath: $e');
      return null;
    }
  }

  Future<sherpa.GeneratedAudio?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
  }) async {
    if (!_isInitialized || _tts == null) {
      Logger.error('TtsService not initialized. Call init() first.');
      return null;
    }

    try {
      final audio = _tts!.generate(text: text, sid: sid, speed: speed);
      return audio;
    } catch (e, stackTrace) {
      Logger.error('Error generating TTS: $e\n$stackTrace');
      return null;
    }
  }

  void dispose() {
    _tts?.free();
    _tts = null;
    _isInitialized = false;
  }
}
