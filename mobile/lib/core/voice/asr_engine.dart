import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import '../utils/logger.dart';

class ASREngine {
  ASREngine._internal();
  static final ASREngine _instance = ASREngine._internal();
  factory ASREngine() => _instance;

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _recorderSub;

  final StreamController<String> _resultController =
      StreamController.broadcast();
  Stream<String> get onResult => _resultController.stream;

  final StreamController<double> _volumeController =
      StreamController.broadcast();
  Stream<double> get onVolume => _volumeController.stream;

  final List<int> _currentWaveData = [];

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
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
        if (p == null) throw Exception('ModelManager failed to prepare $key');
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
        'ASREngine initialization failed.',
        error: e,
        stackTrace: stackTrace,
      );
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) throw Exception('Microphone denied');
    if (!_isInitialized) await init();

    _stream = _recognizer!.createStream();
    _currentWaveData.clear();

    await _recorder.initialize();
    _recorderSub = _recorder.audioStream.listen(
      (data) {
        try {
          final bytes = data;
          _onAudioBuffer(_convertBytesToFloat(bytes));
          if (_stream != null) {
            _stream!.acceptWaveform(
              samples: _convertBytesToFloat(bytes),
              sampleRate: 16000,
            );
            while (_recognizer!.isReady(_stream!)) {
              _recognizer!.decode(_stream!);
            }
            final isEndpoint = _recognizer!.isEndpoint(_stream!);
            if (isEndpoint) {
              final text = _recognizer!.getResult(_stream!).text;
              _resultController.add(text);
            }
          }
          final floatSamples = _convertBytesToFloat(bytes);
          double sum = 0.0;
          for (var i = 0; i < floatSamples.length; i++) {
            sum += floatSamples[i] * floatSamples[i];
          }
          final rms = floatSamples.isEmpty
              ? 0.0
              : math.sqrt(sum / floatSamples.length);
          _volumeController.add(rms.clamp(0.0, 1.0));
        } catch (e) {
          logger.e('Error processing audio buffer: $e');
        }
      },
      onError: (e) {
        logger.e('Audio stream error: $e');
      },
    );
    await _recorder.start();
  }

  Future<String> stop() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    await _recorderSub?.cancel();
    _recorderSub = null;

    if (_stream != null) {
      _recognizer!.decode(_stream!);
      final result = _recognizer!.getResult(_stream!);
      _stream!.free();
      _stream = null;
      return result.text;
    }
    return '';
  }

  void _onAudioBuffer(Float32List buffer) {
    // 激进压缩：每 1600 个采样点（0.1s）取一个最大值
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

  void dispose() {
    _recorderSub?.cancel();
    _stream?.free();
    _recognizer?.free();
    _recognizer = null;
    _stream = null;
    _isInitialized = false;
    _initCompleter = null;
    _resultController.close();
    _volumeController.close();
  }
}
