import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import '../core/utils/logger.dart';

class SpeechRecognitionService {
  sherpa.OnlineRecognizer? _recognizer;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    const modelDir = 'assets/models';
    const tokens = '$modelDir/tokens.txt';
    const encoder = '$modelDir/encoder-epoch-99-avg-1.int8.onnx';
    const decoder = '$modelDir/decoder-epoch-99-avg-1.onnx';
    const joiner = '$modelDir/joiner-epoch-99-avg-1.int8.onnx';

    try {
      // Copy assets to local storage so C++ can access them
      final tokensPath = await _copyAssetToLocal(tokens);
      final encoderPath = await _copyAssetToLocal(encoder);
      final decoderPath = await _copyAssetToLocal(decoder);
      final joinerPath = await _copyAssetToLocal(joiner);

      if (tokensPath == null ||
          encoderPath == null ||
          decoderPath == null ||
          joinerPath == null) {
        throw Exception(
          'Failed to copy one or more model files. Check logs for details.',
        );
      }

      final config = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: encoderPath,
            decoder: decoderPath,
            joiner: joinerPath,
          ),
          tokens: tokensPath,
          numThreads: 1,
          provider: 'cpu',
          debug: true,
          modelType: 'zipformer',
        ),
        feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
        enableEndpoint: true,
        rule1MinTrailingSilence: 2.4,
        rule2MinTrailingSilence: 1.2,
        rule3MinUtteranceLength: 20.0,
      );

      _recognizer = sherpa.OnlineRecognizer(config);
      _isInitialized = true;
      Logger.info('SpeechRecognitionService initialized successfully');
    } catch (e) {
      Logger.error('SpeechRecognitionService initialization failed', e);
      _isInitialized = false;
      rethrow;
    }
  }

  Future<String?> _copyAssetToLocal(String assetPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${directory.path}/$fileName');

      // Check if file exists and has content, but for development we might want to overwrite
      // to ensure we have the latest model.
      // if (await file.exists()) return file.path;

      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      Logger.info('Copied asset $assetPath to ${file.path}');
      return file.path;
    } catch (e) {
      Logger.error(
        'Failed to copy asset: $assetPath. Make sure it is declared in pubspec.yaml',
        e,
      );
      return null;
    }
  }

  sherpa.OnlineStream createStream() {
    if (!_isInitialized || _recognizer == null) {
      throw Exception('Recognizer not initialized');
    }
    return _recognizer!.createStream();
  }

  bool isReady(sherpa.OnlineStream stream) {
    return _recognizer!.isReady(stream);
  }

  void decode(sherpa.OnlineStream stream) {
    _recognizer!.decode(stream);
  }

  String getResult(sherpa.OnlineStream stream) {
    return _recognizer!.getResult(stream).text;
  }

  bool isEndpoint(sherpa.OnlineStream stream) {
    return _recognizer!.isEndpoint(stream);
  }

  void reset(sherpa.OnlineStream stream) {
    _recognizer!.reset(stream);
  }

  void dispose() {
    _recognizer?.free(); // Assuming free or dispose method exists, check API
    _isInitialized = false;
  }
}
