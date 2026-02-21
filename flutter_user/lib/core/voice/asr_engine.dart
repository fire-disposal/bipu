import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import '../utils/logger.dart';

class ASRError {
  final String message;
  final StackTrace? stackTrace;
  ASRError(this.message, [this.stackTrace]);
  @override
  String toString() => 'ASRError: $message';
}

class ASREngine {
  ASREngine._internal();
  static final ASREngine _instance = ASREngine._internal();
  factory ASREngine() => _instance;

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  bool _isDisposing = false;
  bool _isRecording = false;

  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _recorderSub;

  final StreamController<String> _resultController =
      StreamController.broadcast();
  Stream<String> get onResult => _resultController.stream;

  final StreamController<double> _volumeController =
      StreamController.broadcast();
  Stream<double> get onVolume => _volumeController.stream;

  final StreamController<ASRError> _errorController =
      StreamController.broadcast();
  Stream<ASRError> get onError => _errorController.stream;

  final List<int> _currentWaveData = [];

  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    if (_isDisposing) throw Exception('ASR Engine is disposing');

    _initCompleter = Completer<void>();

    try {
      logger.i('Initializing ASR engine...');
      sherpa.initBindings();

      final modelFiles = {
        'asr/encoder-epoch-99-avg-1.int8.onnx':
            'assets/models/asr/encoder-epoch-99-avg-1.int8.onnx',
        'asr/decoder-epoch-99-avg-1.onnx':
            'assets/models/asr/decoder-epoch-99-avg-1.onnx',
        'asr/joiner-epoch-99-avg-1.int8.onnx':
            'assets/models/asr/joiner-epoch-99-avg-1.int8.onnx',
        'asr/tokens.txt': 'assets/models/asr/tokens.txt',
      };

      await ModelManager.instance.ensureInitialized(modelFiles);

      final modelPaths = <String, String>{};
      for (final key in modelFiles.keys) {
        final p = ModelManager.instance.getModelPath(key);
        if (p == null) {
          throw Exception('ModelManager failed to prepare $key');
        }
        modelPaths[key.split('/').last] = p;
      }

      final config = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: modelPaths['encoder-epoch-99-avg-1.int8.onnx']!,
            decoder: modelPaths['decoder-epoch-99-avg-1.onnx']!,
            joiner: modelPaths['joiner-epoch-99-avg-1.int8.onnx']!,
          ),
          tokens: modelPaths['tokens.txt']!,
          numThreads: 1,
          provider: 'cpu',
          debug: false,
          modelType: 'zipformer',
        ),
        feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
        enableEndpoint: true,
      );

      _recognizer = sherpa.OnlineRecognizer(config);
      _isInitialized = true;
      logger.i('ASREngine initialized successfully');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e(
        'ASREngine initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> startRecording() async {
    if (_isDisposing) throw Exception('ASR Engine is disposing');
    if (_isRecording) {
      logger.w('Recording already in progress');
      return;
    }

    try {
      logger.i('Starting ASR recording...');

      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception('Microphone permission denied');
      }

      if (!_isInitialized) {
        logger.i('ASR not initialized, initializing...');
        await init();
      }

      _stream = _recognizer!.createStream();
      _currentWaveData.clear();
      _isRecording = true;

      await _recorder.initialize();

      _recorderSub = _recorder.audioStream.listen(
        (data) {
          try {
            final bytes = data;
            final floatSamples = _convertBytesToFloat(bytes);

            if (floatSamples.isEmpty) return;

            _onAudioBuffer(floatSamples);

            if (_stream != null && !_isDisposing) {
              _stream!.acceptWaveform(samples: floatSamples, sampleRate: 16000);

              while (_recognizer!.isReady(_stream!)) {
                _recognizer!.decode(_stream!);
              }

              final result = _recognizer!.getResult(_stream!);
              if (result.text.isNotEmpty) {
                _resultController.add(result.text);
              }
            }

            double sum = 0.0;
            for (var i = 0; i < floatSamples.length; i++) {
              sum += floatSamples[i] * floatSamples[i];
            }
            final rms = math.sqrt(sum / floatSamples.length);
            _volumeController.add(rms.clamp(0.0, 1.0));
          } catch (e, stackTrace) {
            logger.e(
              'Error processing audio buffer',
              error: e,
              stackTrace: stackTrace,
            );
            _errorController.add(
              ASRError('Audio processing error: $e', stackTrace),
            );
          }
        },
        onError: (e, stackTrace) {
          logger.e('Audio stream error', error: e, stackTrace: stackTrace);
          _errorController.add(ASRError('Audio stream error: $e', stackTrace));
          _cleanupRecording();
        },
        cancelOnError: true,
      );

      await _recorder.start();
      logger.i('ASR recording started successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to start ASR recording',
        error: e,
        stackTrace: stackTrace,
      );
      _isRecording = false;
      _cleanupRecording();
      rethrow;
    }
  }

  Future<String> stop() async {
    if (!_isRecording) {
      logger.w('No recording in progress');
      return '';
    }

    logger.i('Stopping ASR recording...');

    try {
      await _recorder.stop();
      await _recorderSub?.cancel();
      _recorderSub = null;

      String finalResult = '';
      if (_stream != null && !_isDisposing) {
        try {
          _recognizer!.decode(_stream!);
          final result = _recognizer!.getResult(_stream!);
          finalResult = result.text;

          _stream!.free();
          _stream = null;
        } catch (e, stackTrace) {
          logger.e(
            'Error during final recognition',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      _isRecording = false;
      logger.i('ASR recording stopped, final result: $finalResult');
      return finalResult;
    } catch (e, stackTrace) {
      logger.e(
        'Error stopping ASR recording',
        error: e,
        stackTrace: stackTrace,
      );
      _isRecording = false;
      _cleanupRecording();
      rethrow;
    }
  }

  void _cleanupRecording() {
    try {
      _recorderSub?.cancel();
      _recorderSub = null;

      if (_stream != null) {
        try {
          _stream!.free();
        } catch (_) {}
        _stream = null;
      }

      _isRecording = false;
    } catch (e) {
      logger.e('Error during recording cleanup', error: e);
    }
  }

  void _onAudioBuffer(Float32List buffer) {
    double max = 0;
    for (var s in buffer) {
      if (s.abs() > max) max = s.abs();
    }
    _currentWaveData.add((max * 255).toInt());
  }

  List<int> getFinalWave() => _currentWaveData;

  Float32List _convertBytesToFloat(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return Float32List(0);
    final byteData = ByteData.sublistView(bytes);
    final out = Float32List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final val = byteData.getInt16(i * 2, Endian.little);
      out[i] = val / 32768.0;
    }
    return out;
  }

  Future<void> dispose() async {
    if (_isDisposing) return;
    _isDisposing = true;
    logger.i('Disposing ASREngine...');

    try {
      await _recorderSub?.cancel();
      try {
        await _recorder.stop();
      } catch (_) {}

      if (_stream != null) {
        try {
          _stream!.free();
        } catch (_) {}
        _stream = null;
      }

      if (_recognizer != null) {
        try {
          _recognizer!.free();
        } catch (_) {}
        _recognizer = null;
      }

      await _resultController.close();
      await _volumeController.close();
      await _errorController.close();

      _isInitialized = false;
      _initCompleter = null;
    } catch (e) {
      logger.e('Error during ASREngine dispose', error: e);
    }
  }
}
