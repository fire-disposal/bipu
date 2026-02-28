import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import 'voice_config.dart';

class ASREngine {
  ASREngine();

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

  final StreamController<Uint8List> _audioController =
      StreamController.broadcast();
  Stream<Uint8List> get onAudio => _audioController.stream;

  Completer<void> _stopLock = Completer<void>()..complete();
  Completer<void> _disposeLock = Completer<void>()..complete();
  bool _isStopping = false;
  bool _isDisposing = false;
  bool _isRecording = false;

  int _volumeCounter = 0;

  final Queue<Uint8List> _audioBuffer = Queue<Uint8List>();
  bool _isProcessing = false;
  final Queue<Uint8List> _processingQueue = Queue<Uint8List>();

  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isStopping => _isStopping;

  Future<void> init() async {
    if (_isInitialized) return;

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      sherpa.initBindings();
      await ModelManager.instance.ensureInitialized(VoiceConfig.asrModelFiles);

      final modelPaths = <String, String>{};
      for (final key in VoiceConfig.asrModelFiles.keys) {
        final p = ModelManager.instance.getModelPath(key);
        if (p == null) {
          throw Exception('ModelManager failed to prepare $key');
        }
        final fileName = key.split('/').last;
        modelPaths[fileName] = p;
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
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> startRecording() async {
    if (_isStopping) {
      throw Exception('Cannot start recording while stopping');
    }

    if (!_isInitialized) {
      await init();
    }

    final status = await Permission.microphone.request();
    if (status.isDenied) {
      throw Exception('Microphone permission denied');
    }

    _isRecording = false;

    try {
      _stream = _recognizer!.createStream();
      await _recorder.initialize();

      _recorderSub = _recorder.audioStream.listen(
        _handleAudioData,
        cancelOnError: true,
      );

      await _recorder.start();
      _isRecording = true;
    } catch (e) {
      _cleanupOnStartFailure();
      rethrow;
    }
  }

  void _cleanupOnStartFailure() {
    try {
      _recorderSub?.cancel();
      _recorderSub = null;

      if (_stream != null) {
        try {
          _stream!.free();
        } catch (_) {}
        _stream = null;
      }
    } catch (_) {}
  }

  Future<String> stop() async {
    if (!_stopLock.isCompleted) {
      return await _stopLock.future.then((_) => '');
    }

    _stopLock = Completer<void>();
    _isStopping = true;
    _isRecording = false;

    _processingQueue.clear();
    _audioBuffer.clear();

    String resultText = '';

    try {
      if (!_isRecording || _recorderSub == null) {
        return '';
      }

      try {
        await _recorderSub?.cancel();
        _recorderSub = null;
      } catch (_) {}

      try {
        await _recorder.stop();
      } catch (_) {}

      await _waitForProcessingToComplete();

      if (_stream != null && _recognizer != null) {
        try {
          _recognizer!.decode(_stream!);
        } catch (_) {}

        try {
          final result = _recognizer!.getResult(_stream!);
          resultText = result.text;
        } catch (_) {
          resultText = '';
        }

        try {
          _stream!.free();
        } catch (_) {}
        _stream = null;
      }
    } catch (_) {
    } finally {
      _isRecording = false;
      _isStopping = false;
      _stopLock.complete();
    }

    return resultText;
  }

  Future<void> _waitForProcessingToComplete() async {
    final maxWaitTime = Duration(seconds: 2);
    final startTime = DateTime.now();

    while (_isProcessing &&
        DateTime.now().difference(startTime) < maxWaitTime &&
        !_isDisposing) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (_isProcessing) {
      _isProcessing = false;
    }
  }

  void _handleAudioData(Uint8List data) {
    if (_isStopping || _isDisposing) return;

    if (!_audioController.isClosed) {
      try {
        if (_volumeCounter % 2 == 0) {
          _audioController.add(data);
        }
      } catch (_) {}
    }

    if (_processingQueue.length < 50) {
      _processingQueue.addLast(data);
    } else {
      _processingQueue.removeFirst();
      _processingQueue.addLast(data);
    }

    if (!_isProcessing) {
      Future.delayed(const Duration(milliseconds: 2), () {
        if (!_isProcessing && !_isStopping && !_isDisposing) {
          _processAudioQueue();
        }
      });
    }
  }

  Future<void> _processAudioQueue() async {
    if (_isProcessing || _isStopping || _isDisposing) return;

    _isProcessing = true;

    try {
      int batchCount = 0;
      while (_processingQueue.isNotEmpty &&
          !_isStopping &&
          !_isDisposing &&
          batchCount < 5) {
        final data = _processingQueue.removeFirst();
        batchCount++;

        if (_isStopping || _isDisposing) break;
        await _processSingleAudioData(data);
      }
    } catch (_) {
    } finally {
      _isProcessing = false;

      if (_processingQueue.isNotEmpty && !_isStopping && !_isDisposing) {
        await Future.delayed(const Duration(milliseconds: 5), () {
          if (!_isProcessing && !_isStopping && !_isDisposing) {
            _processAudioQueue();
          }
        });
      }
    }
  }

  Future<void> _processSingleAudioData(Uint8List data) async {
    if (_isStopping || _isDisposing) return;

    try {
      final floatSamples = _convertBytesToFloatFast(data);
      _emitVolume(floatSamples);

      if (_stream != null && !_isStopping && !_isDisposing) {
        _stream!.acceptWaveform(samples: floatSamples, sampleRate: 16000);

        if (_volumeCounter % 20 == 0 && !_isStopping && !_isDisposing) {
          if (_recognizer!.isReady(_stream!) && !_isStopping && !_isDisposing) {
            _recognizer!.decode(_stream!);
          }

          final isEndpoint = _recognizer!.isEndpoint(_stream!);
          if (isEndpoint && !_isStopping && !_isDisposing) {
            final text = _recognizer!.getResult(_stream!).text;
            if (text.isNotEmpty && !_resultController.isClosed) {
              _resultController.add(text);
            }
          }
        }
      }
    } catch (_) {}
  }

  void _emitVolume(Float32List samples) {
    if (samples.isEmpty || _volumeController.isClosed) return;

    _volumeCounter++;
    if (_volumeCounter % 4 != 0) return;

    double sum = 0.0;
    final step = (samples.length / 10).ceil();
    for (var i = 0; i < samples.length; i += step) {
      sum += samples[i].abs();
    }
    final avgVolume = (sum / (samples.length / step)).clamp(0.0, 1.0);

    if (!_volumeController.isClosed) {
      try {
        _volumeController.add(avgVolume);
      } catch (_) {}
    }
  }

  Float32List _convertBytesToFloatFast(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return Float32List(0);

    final byteData = ByteData.sublistView(bytes);
    final out = Float32List(sampleCount);

    for (var i = 0; i < sampleCount; i++) {
      out[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
    }

    return out;
  }

  Future<void> dispose() async {
    if (!_disposeLock.isCompleted) {
      return await _disposeLock.future;
    }

    _disposeLock = Completer<void>();
    _isDisposing = true;

    try {
      if (_isRecording) {
        await stop();
      }

      if (!_stopLock.isCompleted) {
        await _stopLock.future;
      }

      try {
        await _recorderSub?.cancel();
        _recorderSub = null;
      } catch (_) {}

      try {
        _recorder.dispose();
      } catch (_) {}

      if (_stream != null) {
        try {
          _stream!.free();
          _stream = null;
        } catch (_) {}
      }

      if (_recognizer != null) {
        try {
          _recognizer!.free();
          _recognizer = null;
        } catch (_) {}
      }

      _audioBuffer.clear();
      _processingQueue.clear();

      if (!_resultController.isClosed) {
        try {
          await _resultController.close();
        } catch (_) {}
      }

      if (!_volumeController.isClosed) {
        try {
          await _volumeController.close();
        } catch (_) {}
      }

      if (!_audioController.isClosed) {
        try {
          await _audioController.close();
        } catch (_) {}
      }

      _isInitialized = false;
      _initCompleter = null;
      _isRecording = false;
      _isStopping = false;
      _volumeCounter = 0;
      _isProcessing = false;
    } catch (_) {
    } finally {
      _isDisposing = false;
      _disposeLock.complete();
    }
  }
}
