import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import 'voice_config.dart';
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

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      sherpa.initBindings();

      await ModelManager.instance.ensureInitialized(VoiceConfig.asrModelFiles);

      final modelPaths = <String, String>{};
      for (final key in VoiceConfig.asrModelFiles.keys) {
        final p = ModelManager.instance.getModelPath(key);
        if (p == null) throw Exception('ModelManager failed to prepare $key');
        modelPaths[key.split('/').last] = p;
      }

      final config = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: modelPaths[VoiceConfig.asrEncoder]!,
            decoder: modelPaths[VoiceConfig.asrDecoder]!,
            joiner: modelPaths[VoiceConfig.asrJoiner]!,
          ),
          tokens: modelPaths[VoiceConfig.asrTokens]!,
          numThreads: VoiceConfig.asrNumThreads,
          provider: VoiceConfig.asrProvider,
          debug: VoiceConfig.asrDebug,
          modelType: VoiceConfig.asrModelType,
        ),
        feat: sherpa.FeatureConfig(
          sampleRate: VoiceConfig.asrSampleRate,
          featureDim: VoiceConfig.asrFeatureDim,
        ),
        enableEndpoint: VoiceConfig.asrEnableEndpoint,
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

    await _recorder.initialize();
    _recorderSub = _recorder.audioStream.listen(
      (data) {
        try {
          final floatSamples = _convertBytesToFloat(data);
          if (_stream != null) {
            _stream!.acceptWaveform(samples: floatSamples, sampleRate: 16000);
            while (_recognizer!.isReady(_stream!)) {
              _recognizer!.decode(_stream!);
            }
            final isEndpoint = _recognizer!.isEndpoint(_stream!);
            if (isEndpoint) {
              final text = _recognizer!.getResult(_stream!).text;
              _resultController.add(text);
            }
          }
          _emitVolume(floatSamples);
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

  void _emitVolume(Float32List samples) {
    double sum = 0.0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    final rms = samples.isEmpty ? 0.0 : math.sqrt(sum / samples.length);
    _volumeController.add(rms.clamp(0.0, 1.0));
  }

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
