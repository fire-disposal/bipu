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

    // TODO: Extract these to a configuration file or remote config if needed
    const modelDir = 'assets/models';
    const modelFiles = {
      'tokens': '$modelDir/tokens.txt',
      'encoder': '$modelDir/encoder-epoch-99-avg-1.int8.onnx',
      'decoder': '$modelDir/decoder-epoch-99-avg-1.onnx',
      'joiner': '$modelDir/joiner-epoch-99-avg-1.int8.onnx',
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
    } catch (e, stackTrace) {
      Logger.error(
        'SpeechRecognitionService initialization failed.\n'
        'Checklist:\n'
        '1. Do assets/models/* files exist?\n'
        '2. Are they listed in pubspec.yaml under assets?\n'
        '3. Did you run "flutter pub get"?',
        e,
        stackTrace,
      );
      _isInitialized = false;
      rethrow;
    }
  }

  Future<String?> _copyAssetToLocal(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${directory.path}/$fileName');

      // Check if file exists and verify integrity/updates by size
      // This allows updating models by simply replacing assets and rebuilding,
      // even if the filename remains the same.
      if (await file.exists()) {
        final existingSize = await file.length();
        if (existingSize == data.lengthInBytes) {
          Logger.info(
            'Asset $assetPath already exists and size matches. Skipping copy.',
          );
          return file.path;
        }
        Logger.info(
          'Asset $assetPath exists but size mismatch. Overwriting...',
        );
      }

      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true, // Ensure write is committed to disk
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

  /// Starts listening to the microphone.
  Future<void> startRecording() async {
    if (!_isInitialized) {
      Logger.error('SpeechService not initialized. Call init() first.');
      return;
    }

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission denied');
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
    await _recorder.stop();
    _stopCurrentStream();
    _audioSubscription?.cancel();
    _audioSubscription = null;
  }

  void _stopCurrentStream() {
    if (_stream != null) {
      _stream!.free();
      _stream = null;
    }
  }

  void _processAudioData(List<int> data) {
    if (_stream == null || _recognizer == null) return;

    try {
      final samples = _convertBytesToFloat(data);
      _stream!.acceptWaveform(samples: samples, sampleRate: 16000);

      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }

      final currentSegment = _recognizer!.getResult(_stream!).text;

      // Emit full text: committed buffer + current active segment
      final fullText = _sessionBuffer.toString() + currentSegment;
      _resultController.add(fullText);

      if (_recognizer!.isEndpoint(_stream!)) {
        if (currentSegment.isNotEmpty) {
          _sessionBuffer.write(currentSegment);
          // Add punctuation or space if needed? Sherpa usually does good, but let's ensure separation
          // _sessionBuffer.write(' ');
        }
        _recognizer!.reset(_stream!);
      }
    } catch (e) {
      Logger.error('Error during speech recognition processing', e);
    }
  }

  // Convert 16-bit PCM bytes to float samples
  Float32List _convertBytesToFloat(List<int> bytes) {
    // Ensure we have an even number of bytes for 16-bit samples
    final len = bytes.length;
    if (len % 2 != 0) {
      // Handle odd byte length if necessary, simplistic approach: drop last byte
      // Or usually sound_stream guarantees it?
      // For safety:
      return _convertBytesToFloat(bytes.sublist(0, len - 1));
    }

    final int16List = Int16List.view(Uint8List.fromList(bytes).buffer);
    final float32List = Float32List(int16List.length);
    for (var i = 0; i < int16List.length; i++) {
      float32List[i] = int16List[i] / 32768.0;
    }
    return float32List;
  }

  void dispose() {
    stop();
    _recognizer?.free();
    _recognizer = null;
    _isInitialized = false;
    _resultController.close();
  }
}
