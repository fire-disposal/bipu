import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:isolate';
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import '../utils/logger.dart';

/// Isolated ASR processing to prevent blocking the main thread
class ASRIsolateMessage {
  final String type;
  final dynamic data;
  
  ASRIsolateMessage(this.type, this.data);
}

/// Enhanced ASR Engine with proper isolation and error handling
class ASREngineIsolated {
  ASREngineIsolated._internal();
  static final ASREngineIsolated _instance = ASREngineIsolated._internal();
  factory ASREngineIsolated() => _instance;

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  bool _isDisposing = false;

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
  Isolate? _processingIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _isolateReceivePort;

  bool get isInitialized => _isInitialized;
  bool get isRecording => _recorderSub != null;

  /// Initialize the ASR engine with proper error handling
  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    if (_isDisposing) throw ASRError('Engine is disposing', ErrorType.disposing);

    _initCompleter = Completer<void>();

    try {
      logger.i('Initializing ASR engine...');
      
      // Initialize sherpa bindings
      sherpa.initBindings();

      // Prepare model files
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
          throw ASRError('ModelManager failed to prepare $key', ErrorType.modelLoad);
        }
        modelPaths[key.split('/').last] = p;
      }

      // Create recognizer configuration
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
      
      // Initialize processing isolate
      await _initializeProcessingIsolate();
      
      _isInitialized = true;
      logger.i('ASR engine initialized successfully');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e('ASR engine initialization failed', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(ASRError(
        'Initialization failed: $e', 
        ErrorType.initialization,
        originalError: e,
      ));
      _initCompleter = null;
      rethrow;
    }
  }

  /// Initialize the processing isolate for heavy computations
  Future<void> _initializeProcessingIsolate() async {
    try {
      _isolateReceivePort = ReceivePort();
      _processingIsolate = await Isolate.spawn(
        _isolateEntryPoint,
        _isolateReceivePort!.sendPort,
      );

      final completer = Completer<void>();
      _isolateReceivePort!.listen((message) {
        if (message is SendPort) {
          _isolateSendPort = message;
          completer.complete();
        } else if (message is ASRIsolateMessage) {
          _handleIsolateMessage(message);
        }
      });

      await completer.future;
      logger.i('ASR processing isolate initialized');
    } catch (e, stackTrace) {
      logger.e('Failed to initialize processing isolate', error: e, stackTrace: stackTrace);
      throw ASRError('Isolate initialization failed: $e', ErrorType.isolateError);
    }
  }

  /// Isolate entry point for processing
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is ASRIsolateMessage) {
        // Process heavy computations here
        // For now, we'll do basic processing on the main thread
        // but this structure allows for future optimization
        sendPort.send(message);
      }
    });
  }

  /// Handle messages from the processing isolate
  void _handleIsolateMessage(ASRIsolateMessage message) {
    switch (message.type) {
      case 'error':
        _errorController.add(message.data as ASRError);
        break;
      case 'result':
        _resultController.add(message.data as String);
        break;
      case 'volume':
        _volumeController.add(message.data as double);
        break;
    }
  }

  /// Start recording with comprehensive error handling
  Future<void> startRecording() async {
    if (_isDisposing) throw ASRError('Engine is disposing', ErrorType.disposing);
    if (isRecording) return;
    
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw ASRError('Microphone permission denied', ErrorType.permissionDenied);
      }

      // Ensure initialization
      if (!_isInitialized) {
        await init();
      }

      // Create new stream for recognition
      _stream = _recognizer!.createStream();
      _currentWaveData.clear();

      // Initialize recorder
      await _recorder.initialize();
      
      // Set up audio stream listener with error handling
      _recorderSub = _recorder.audioStream.listen(
        _processAudioBuffer,
        onError: (error) {
          logger.e('Audio stream error: $error');
          _errorController.add(ASRError('Audio stream error: $error', ErrorType.audioStream));
          _cleanupRecording();
        },
        cancelOnError: true,
      );

      // Start recording
      await _recorder.start();
      
      logger.i('ASR recording started');
    } catch (e, stackTrace) {
      logger.e('Failed to start recording', error: e, stackTrace: stackTrace);
      _cleanupRecording();
      
      if (e is ASRError) {
        rethrow;
      } else {
        throw ASRError('Failed to start recording: $e', ErrorType.recordingStart, originalError: e);
      }
    }
  }

  /// Process audio buffer with enhanced error handling
  void _processAudioBuffer(Uint8List bytes) {
    if (_isDisposing || _stream == null) return;

    try {
      // Convert bytes to float samples
      final floatSamples = _convertBytesToFloat(bytes);
      if (floatSamples.isEmpty) return;

      // Add to waveform data for visualization
      _onAudioBuffer(floatSamples);

      // Process audio in the stream
      _stream!.acceptWaveform(
        samples: floatSamples,
        sampleRate: 16000,
      );

      // Perform recognition while ready
      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }

      // Check for endpoint detection
      final isEndpoint = _recognizer!.isEndpoint(_stream!);
      if (isEndpoint) {
        final result = _recognizer!.getResult(_stream!);
        if (result.text.isNotEmpty) {
          _resultController.add(result.text);
        }
      }

      // Calculate volume for visualization
      double sum = 0.0;
      for (var sample in floatSamples) {
        sum += sample * sample;
      }
      final rms = math.sqrt(sum / floatSamples.length);
      _volumeController.add(rms.clamp(0.0, 1.0));

    } catch (e, stackTrace) {
      logger.e('Error processing audio buffer', error: e, stackTrace: stackTrace);
      _errorController.add(ASRError('Audio processing error: $e', ErrorType.processing, originalError: e));
    }
  }

  /// Stop recording with proper cleanup
  Future<String> stopRecording() async {
    if (!isRecording) return '';

    try {
      logger.i('Stopping ASR recording...');
      
      // Stop recorder
      await _recorder.stop();
      await _recorderSub?.cancel();
      _recorderSub = null;

      // Process final recognition
      String finalResult = '';
      if (_stream != null) {
        try {
          _recognizer!.decode(_stream!);
          final result = _recognizer!.getResult(_stream!);
          finalResult = result.text;
          
          // Clean up stream
          _stream!.free();
          _stream = null;
        } catch (e, stackTrace) {
          logger.e('Error during final recognition', error: e, stackTrace: stackTrace);
          _errorController.add(ASRError('Final recognition error: $e', ErrorType.recognition, originalError: e));
        }
      }

      // Release audio resources
      if (_audioRelease != null) {
        _audioRelease!.call();
        _audioRelease = null;
      }

      logger.i('ASR recording stopped, final result: $finalResult');
      return finalResult;
    } catch (e, stackTrace) {
      logger.e('Error stopping recording', error: e, stackTrace: stackTrace);
      _cleanupRecording();
      throw ASRError('Failed to stop recording: $e', ErrorType.recordingStop, originalError: e);
    }
  }

  /// Clean up recording resources
  void _cleanupRecording() {
    try {
      _recorderSub?.cancel();
      _recorderSub = null;
      
      if (_stream != null) {
        _stream!.free();
        _stream = null;
      }
    } catch (e) {
      logger.e('Error during recording cleanup', error: e);
    }
  }

  /// Handle audio buffer for waveform visualization
  void _onAudioBuffer(Float32List buffer) {
    // Aggressive compression: take max value every 1600 samples (0.1s)
    double max = 0;
    for (var sample in buffer) {
      if (sample.abs() > max) max = sample.abs();
    }
    _currentWaveData.add((max * 255).toInt());
  }

  /// Get final waveform data
  List<int> getFinalWave() => List.from(_currentWaveData);

  /// Convert bytes to float samples
  Float32List _convertBytesToFloat(Uint8List bytes) {
    try {
      final sampleCount = bytes.length ~/ 2;
      if (sampleCount == 0) return Float32List(0);
      
      final byteData = ByteData.sublistView(bytes);
      final out = Float32List(sampleCount);
      
      for (var i = 0; i < sampleCount; i++) {
        final val = byteData.getInt16(i * 2, Endian.little);
        out[i] = val / 32768.0;
      }
      
      return out;
    } catch (e, stackTrace) {
      logger.e('Error converting bytes to float', error: e, stackTrace: stackTrace);
      return Float32List(0);
    }
  }

  VoidCallback? _audioRelease;

  /// Set audio release callback for resource management
  void setAudioRelease(VoidCallback release) {
    _audioRelease = release;
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    logger.i('Disposing ASR engine...');
    _isDisposing = true;

    try {
      // Stop recording if active
      if (isRecording) {
        await stopRecording();
      }

      // Clean up resources
      _cleanupRecording();
      
      // Dispose recognizer
      if (_recognizer != null) {
        _recognizer!.free();
        _recognizer = null;
      }

      // Close streams
      await _resultController.close();
      await _volumeController.close();
      await _errorController.close();

      // Terminate isolate
      if (_processingIsolate != null) {
        _processingIsolate!.kill();
        _processingIsolate = null;
      }
      _isolateReceivePort?.close();

      _isInitialized = false;
      _initCompleter = null;
      
      logger.i('ASR engine disposed');
    } catch (e, stackTrace) {
      logger.e('Error disposing ASR engine', error: e, stackTrace: stackTrace);
    }
  }
}

/// ASR Error types for better error handling
class ASRError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ASRError(this.message, this.type, {this.originalError, this.stackTrace});

  @override
  String toString() => 'ASRError($type): $message';
}

enum ErrorType {
  initialization,
  modelLoad,
  permissionDenied,
  recordingStart,
  recordingStop,
  processing,
  recognition,
  audioStream,
  isolateError,
  disposing,
}import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:isolate';
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import '../utils/logger.dart';

/// Isolated ASR processing to prevent blocking the main thread
class ASRIsolateMessage {
  final String type;
  final dynamic data;
  
  ASRIsolateMessage(this.type, this.data);
}

/// Enhanced ASR Engine with proper isolation and error handling
class ASREngineIsolated {
  ASREngineIsolated._internal();
  static final ASREngineIsolated _instance = ASREngineIsolated._internal();
  factory ASREngineIsolated() => _instance;

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  bool _isDisposing = false;

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
  Isolate? _processingIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _isolateReceivePort;

  bool get isInitialized => _isInitialized;
  bool get isRecording => _recorderSub != null;

  /// Initialize the ASR engine with proper error handling
  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    if (_isDisposing) throw ASRError('Engine is disposing', ErrorType.disposing);

    _initCompleter = Completer<void>();

    try {
      logger.i('Initializing ASR engine...');
      
      // Initialize sherpa bindings
      sherpa.initBindings();

      // Prepare model files
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
          throw ASRError('ModelManager failed to prepare $key', ErrorType.modelLoad);
        }
        modelPaths[key.split('/').last] = p;
      }

      // Create recognizer configuration
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
      
      // Initialize processing isolate
      await _initializeProcessingIsolate();
      
      _isInitialized = true;
      logger.i('ASR engine initialized successfully');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e('ASR engine initialization failed', error: e, stackTrace: stackTrace);
      _initCompleter!.completeError(ASRError(
        'Initialization failed: $e', 
        ErrorType.initialization,
        originalError: e,
      ));
      _initCompleter = null;
      rethrow;
    }
  }

  /// Initialize the processing isolate for heavy computations
  Future<void> _initializeProcessingIsolate() async {
    try {
      _isolateReceivePort = ReceivePort();
      _processingIsolate = await Isolate.spawn(
        _isolateEntryPoint,
        _isolateReceivePort!.sendPort,
      );

      final completer = Completer<void>();
      _isolateReceivePort!.listen((message) {
        if (message is SendPort) {
          _isolateSendPort = message;
          completer.complete();
        } else if (message is ASRIsolateMessage) {
          _handleIsolateMessage(message);
        }
      });

      await completer.future;
      logger.i('ASR processing isolate initialized');
    } catch (e, stackTrace) {
      logger.e('Failed to initialize processing isolate', error: e, stackTrace: stackTrace);
      throw ASRError('Isolate initialization failed: $e', ErrorType.isolateError);
    }
  }

  /// Isolate entry point for processing
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is ASRIsolateMessage) {
        // Process heavy computations here
        // For now, we'll do basic processing on the main thread
        // but this structure allows for future optimization
        sendPort.send(message);
      }
    });
  }

  /// Handle messages from the processing isolate
  void _handleIsolateMessage(ASRIsolateMessage message) {
    switch (message.type) {
      case 'error':
        _errorController.add(message.data as ASRError);
        break;
      case 'result':
        _resultController.add(message.data as String);
        break;
      case 'volume':
        _volumeController.add(message.data as double);
        break;
    }
  }

  /// Start recording with comprehensive error handling
  Future<void> startRecording() async {
    if (_isDisposing) throw ASRError('Engine is disposing', ErrorType.disposing);
    if (isRecording) return;
    
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw ASRError('Microphone permission denied', ErrorType.permissionDenied);
      }

      // Ensure initialization
      if (!_isInitialized) {
        await init();
      }

      // Create new stream for recognition
      _stream = _recognizer!.createStream();
      _currentWaveData.clear();

      // Initialize recorder
      await _recorder.initialize();
      
      // Set up audio stream listener with error handling
      _recorderSub = _recorder.audioStream.listen(
        _processAudioBuffer,
        onError: (error) {
          logger.e('Audio stream error: $error');
          _errorController.add(ASRError('Audio stream error: $error', ErrorType.audioStream));
          _cleanupRecording();
        },
        cancelOnError: true,
      );

      // Start recording
      await _recorder.start();
      
      logger.i('ASR recording started');
    } catch (e, stackTrace) {
      logger.e('Failed to start recording', error: e, stackTrace: stackTrace);
      _cleanupRecording();
      
      if (e is ASRError) {
        rethrow;
      } else {
        throw ASRError('Failed to start recording: $e', ErrorType.recordingStart, originalError: e);
      }
    }
  }

  /// Process audio buffer with enhanced error handling
  void _processAudioBuffer(Uint8List bytes) {
    if (_isDisposing || _stream == null) return;

    try {
      // Convert bytes to float samples
      final floatSamples = _convertBytesToFloat(bytes);
      if (floatSamples.isEmpty) return;

      // Add to waveform data for visualization
      _onAudioBuffer(floatSamples);

      // Process audio in the stream
      _stream!.acceptWaveform(
        samples: floatSamples,
        sampleRate: 16000,
      );

      // Perform recognition while ready
      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }

      // Check for endpoint detection
      final isEndpoint = _recognizer!.isEndpoint(_stream!);
      if (isEndpoint) {
        final result = _recognizer!.getResult(_stream!);
        if (result.text.isNotEmpty) {
          _resultController.add(result.text);
        }
      }

      // Calculate volume for visualization
      double sum = 0.0;
      for (var sample in floatSamples) {
        sum += sample * sample;
      }
      final rms = math.sqrt(sum / floatSamples.length);
      _volumeController.add(rms.clamp(0.0, 1.0));

    } catch (e, stackTrace) {
      logger.e('Error processing audio buffer', error: e, stackTrace: stackTrace);
      _errorController.add(ASRError('Audio processing error: $e', ErrorType.processing, originalError: e));
    }
  }

  /// Stop recording with proper cleanup
  Future<String> stopRecording() async {
    if (!isRecording) return '';

    try {
      logger.i('Stopping ASR recording...');
      
      // Stop recorder
      await _recorder.stop();
      await _recorderSub?.cancel();
      _recorderSub = null;

      // Process final recognition
      String finalResult = '';
      if (_stream != null) {
        try {
          _recognizer!.decode(_stream!);
          final result = _recognizer!.getResult(_stream!);
          finalResult = result.text;
          
          // Clean up stream
          _stream!.free();
          _stream = null;
        } catch (e, stackTrace) {
          logger.e('Error during final recognition', error: e, stackTrace: stackTrace);
          _errorController.add(ASRError('Final recognition error: $e', ErrorType.recognition, originalError: e));
        }
      }

      // Release audio resources
      if (_audioRelease != null) {
        _audioRelease!.call();
        _audioRelease = null;
      }

      logger.i('ASR recording stopped, final result: $finalResult');
      return finalResult;
    } catch (e, stackTrace) {
      logger.e('Error stopping recording', error: e, stackTrace: stackTrace);
      _cleanupRecording();
      throw ASRError('Failed to stop recording: $e', ErrorType.recordingStop, originalError: e);
    }
  }

  /// Clean up recording resources
  void _cleanupRecording() {
    try {
      _recorderSub?.cancel();
      _recorderSub = null;
      
      if (_stream != null) {
        _stream!.free();
        _stream = null;
      }
    } catch (e) {
      logger.e('Error during recording cleanup', error: e);
    }
  }

  /// Handle audio buffer for waveform visualization
  void _onAudioBuffer(Float32List buffer) {
    // Aggressive compression: take max value every 1600 samples (0.1s)
    double max = 0;
    for (var sample in buffer) {
      if (sample.abs() > max) max = sample.abs();
    }
    _currentWaveData.add((max * 255).toInt());
  }

  /// Get final waveform data
  List<int> getFinalWave() => List.from(_currentWaveData);

  /// Convert bytes to float samples
  Float32List _convertBytesToFloat(Uint8List bytes) {
    try {
      final sampleCount = bytes.length ~/ 2;
      if (sampleCount == 0) return Float32List(0);
      
      final byteData = ByteData.sublistView(bytes);
      final out = Float32List(sampleCount);
      
      for (var i = 0; i < sampleCount; i++) {
        final val = byteData.getInt16(i * 2, Endian.little);
        out[i] = val / 32768.0;
      }
      
      return out;
    } catch (e, stackTrace) {
      logger.e('Error converting bytes to float', error: e, stackTrace: stackTrace);
      return Float32List(0);
    }
  }

  VoidCallback? _audioRelease;

  /// Set audio release callback for resource management
  void setAudioRelease(VoidCallback release) {
    _audioRelease = release;
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    logger.i('Disposing ASR engine...');
    _isDisposing = true;

    try {
      // Stop recording if active
      if (isRecording) {
        await stopRecording();
      }

      // Clean up resources
      _cleanupRecording();
      
      // Dispose recognizer
      if (_recognizer != null) {
        _recognizer!.free();
        _recognizer = null;
      }

      // Close streams
      await _resultController.close();
      await _volumeController.close();
      await _errorController.close();

      // Terminate isolate
      if (_processingIsolate != null) {
        _processingIsolate!.kill();
        _processingIsolate = null;
      }
      _isolateReceivePort?.close();

      _isInitialized = false;
      _initCompleter = null;
      
      logger.i('ASR engine disposed');
    } catch (e, stackTrace) {
      logger.e('Error disposing ASR engine', error: e, stackTrace: stackTrace);
    }
  }
}

/// ASR Error types for better error handling
class ASRError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ASRError(this.message, this.type, {this.originalError, this.stackTrace});

  @override
  String toString() => 'ASRError($type): $message';
}

enum ErrorType {
  initialization,
  modelLoad,
  permissionDenied,
  recordingStart,
  recordingStop,
  processing,
  recognition,
  audioStream,
  isolateError,
  disposing,
}
