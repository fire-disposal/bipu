import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/logger.dart';

class SpeechRecognitionService {
  static final SpeechRecognitionService _instance =
      SpeechRecognitionService._internal();

  factory SpeechRecognitionService() => _instance;

  SpeechRecognitionService._internal();

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  StreamSubscription? _audioSubscription;
  final RecorderStream _recorder = RecorderStream();

  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  final _resultController = StreamController<String>.broadcast();

  // Buffer to hold the accumulated text across endpoints
  final StringBuffer _sessionBuffer = StringBuffer();

  bool get isInitialized => _isInitialized;
  Stream<String> get onResult => _resultController.stream;

  /// Returns the current full text (committed session + current stream)
  String get currentText => _sessionBuffer.toString();

  /// Clears the session buffer
  void clearBuffer() {
    _sessionBuffer.clear();
    _resultController.add("");
  }

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      sherpa.initBindings();

      // TODO: Extract these to a configuration file or remote config if needed
      const modelDir = 'assets/models/asr';
      const modelFiles = {
        'tokens': '$modelDir/tokens.txt',
        'encoder': '$modelDir/encoder-epoch-99-avg-1.int8.onnx',
        'decoder': '$modelDir/decoder-epoch-99-avg-1.onnx',
        'joiner': '$modelDir/joiner-epoch-99-avg-1.int8.onnx',
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

      final config = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: paths['encoder']!,
            decoder: paths['decoder']!,
            joiner: paths['joiner']!,
          ),
          tokens: paths['tokens']!,
          numThreads: 1,
          provider: 'cpu',
          debug: false,
          modelType: 'zipformer',
        ),
        feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
        enableEndpoint: true,
        rule1MinTrailingSilence: 2.4,
        rule2MinTrailingSilence: 1.2,
        rule3MinUtteranceLength: 20.0,
      );

      _recognizer = sherpa.OnlineRecognizer(config);

      // Initialize the audio recorder
      await _recorder.initialize();

      _isInitialized = true;
      Logger.info('SpeechRecognitionService initialized successfully');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      Logger.error(
        'SpeechRecognitionService initialization failed.',
        e,
        stackTrace,
      );
      _isInitialized = false;
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
      final modelCacheDir = Directory('${appDir.path}/models/asr');
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
      Logger.error('Failed to copy asset $assetPath: $e');
      return null;
    }
  }

  /// Starts listening to the microphone.
  Future<void> startRecording() async {
    if (!_isInitialized) {
      await init();
    }

    final status = await Permission.microphone.request();
    if (status.isDenied) {
      throw Exception('Microphone permission denied');
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
      throw Exception(
        'Microphone permission permanently denied. Please enable it in settings.',
      );
    }

    startListening(_recorder.audioStream);
    await _recorder.start();
  }

  /// Starts listening to the provided audio stream.
  /// The audio stream is expected to be a stream of bytes (Int16 PCM).
  void startListening(Stream<List<int>> audioStream) {
    if (!_isInitialized || _recognizer == null) {
      Logger.error('SpeechService not initialized. Call init() first.');
      return;
    }

    _stopCurrentStream();
    _stream = _recognizer!.createStream();

    _audioSubscription = audioStream.listen(
      (data) {
        _processAudioData(data);
      },
      onError: (e) {
        Logger.error('Error in audio stream', e);
        stop();
      },
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    try {
      await _recorder.stop();
    } catch (e) {
      Logger.error('Error stopping recorder', e);
    }
    _stopCurrentStream();
    _audioSubscription?.cancel();
    _audioSubscription = null;
  }

  void _stopCurrentStream() {
    if (_stream != null) {
      try {
        _stream!.free();
      } catch (e) {
        Logger.error('Error freeing stream', e);
      }
      _stream = null;
    }
  }

  void _processAudioData(List<int> data) {
    if (!_isInitialized || _stream == null || _recognizer == null) return;

    try {
      final Uint8List bytes = data is Uint8List
          ? data
          : Uint8List.fromList(data);
      final samples = _convertBytesToFloat(bytes);
      if (samples.isEmpty) return;

      _stream!.acceptWaveform(samples: samples, sampleRate: 16000);

      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }

      final result = _recognizer!.getResult(_stream!);
      final currentSegment = result.text;

      // Emit full text: committed buffer + current active segment
      final fullText = _sessionBuffer.toString() + currentSegment;
      _resultController.add(fullText);

      if (_recognizer!.isEndpoint(_stream!)) {
        if (currentSegment.isNotEmpty) {
          _sessionBuffer.write(currentSegment);
        }
        _recognizer!.reset(_stream!);
      }
    } catch (e, stackTrace) {
      Logger.error('Error during speech recognition processing', e, stackTrace);
    }
  }

  // Convert 16-bit PCM bytes to float samples
  Float32List _convertBytesToFloat(Uint8List bytes) {
    // Ensure we have an even number of bytes for 16-bit samples
    final len = bytes.length;
    final sampleCount = len ~/ 2;
    if (sampleCount == 0) return Float32List(0);

    // Optimized conversion using ByteData to avoid Int16List alignment issues
    final byteData = ByteData.sublistView(bytes);
    final float32List = Float32List(sampleCount);

    for (var i = 0; i < sampleCount; i++) {
      // Int16 PCM to Float [-1.0, 1.0]
      // Try-catch inside loop is usually slow, but getInt16 should be safe here
      // since we checked sampleCount.
      final intValue = byteData.getInt16(i * 2, Endian.little);
      float32List[i] = intValue / 32768.0;
    }
    return float32List;
  }

  void dispose() {
    _isInitialized = false;
    stop();
    _recognizer?.free();
    _recognizer = null;
    _resultController.close();
  }
}
