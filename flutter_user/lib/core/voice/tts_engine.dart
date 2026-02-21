import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import '../utils/logger.dart';

/// Enhanced TTS Engine with comprehensive error handling and resource management
class TTSEngine {
  static final TTSEngine _instance = TTSEngine._internal();
  factory TTSEngine() => _instance;
  TTSEngine._internal();

  sherpa.OfflineTts? _tts;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  bool _isDisposing = false;

  // Error tracking
  int _consecutiveErrors = 0;
  DateTime? _lastErrorTime;
  static const int _maxConsecutiveErrors = 3;
  static const Duration _errorResetDuration = Duration(minutes: 5);

  bool get isInitialized => _isInitialized;
  bool get isDisposing => _isDisposing;

  /// Initialize TTS engine with enhanced error handling
  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    if (_isDisposing)
      throw TTSError('TTS Engine is disposing', ErrorType.disposing);

    _initCompleter = Completer<void>();

    try {
      logger.i('Initializing TTS engine...');

      // Initialize sherpa bindings
      sherpa.initBindings();

      // Define model files
      final modelFiles = {
        'tts/vits-aishell3.onnx': 'assets/models/tts/vits-aishell3.onnx',
        'tts/tokens.txt': 'assets/models/tts/tokens.txt',
        'tts/lexicon.txt': 'assets/models/tts/lexicon.txt',
        'tts/phone.fst': 'assets/models/tts/phone.fst',
        'tts/date.fst': 'assets/models/tts/date.fst',
        'tts/number.fst': 'assets/models/tts/number.fst',
        'tts/new_heteronym.fst': 'assets/models/tts/new_heteronym.fst',
        'tts/rule.far': 'assets/models/tts/rule.far',
      };

      // Ensure models are available
      await ModelManager.instance.ensureInitialized(modelFiles);

      // Build model paths
      final paths = <String, String>{};
      for (final key in modelFiles.keys) {
        final p = ModelManager.instance.getModelPath(key);
        if (p == null) {
          throw TTSError(
            'ModelManager failed to prepare $key',
            ErrorType.modelLoad,
          );
        }
        paths[key.split('/').last.split('.').first] = p;
      }

      // Create VITS model configuration
      final vits = sherpa.OfflineTtsVitsModelConfig(
        model: paths['vits-aishell3']!,
        lexicon: paths['lexicon']!,
        tokens: paths['tokens']!,
      );

      // Create TTS configuration
      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: vits,
          numThreads: 1,
          debug: false,
        ),
        ruleFsts:
            '${paths['phone']},${paths['date']},${paths['number']},${paths['new_heteronym']},${paths['rule']}',
      );

      // Initialize TTS engine
      _tts = sherpa.OfflineTts(config);
      _isInitialized = true;

      logger.i('TTS engine initialized successfully');
      _initCompleter!.complete();
    } catch (e, stackTrace) {
      logger.e(
        'TTS engine initialization failed',
        error: e,
        stackTrace: stackTrace,
      );

      final error = TTSError(
        'Initialization failed: $e',
        ErrorType.initialization,
        originalError: e,
        stackTrace: stackTrace,
      );

      _initCompleter!.completeError(error);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Generate speech with comprehensive error handling and retry logic
  Future<TTSResult?> generate({
    required String text,
    int sid = 0,
    double speed = 1.0,
  }) async {
    if (_isDisposing) {
      throw TTSError('TTS Engine is disposing', ErrorType.disposing);
    }

    if (!_isInitialized || _tts == null) {
      logger.i('TTS not initialized, initializing...');
      await init();
    }

    // Validate input
    if (text.trim().isEmpty) {
      logger.w('Empty text provided for TTS generation');
      return null;
    }

    // Check error rate limiting
    if (_shouldThrottle()) {
      logger.w('TTS generation throttled due to excessive errors');
      throw TTSError('TTS generation throttled', ErrorType.throttled);
    }

    try {
      logger.i(
        'Generating TTS for text: "${text.substring(0, math.min(text.length, 50))}${text.length > 50 ? '...' : ''}"',
      );

      // Generate audio
      final audio = _tts!.generate(text: text, sid: sid, speed: speed);

      if (audio == null) {
        logger.w('TTS generation returned null');
        return null;
      }

      // Reset error counter on success
      _consecutiveErrors = 0;

      logger.i('TTS generation successful');
      return TTSResult(audio);
    } catch (e, stackTrace) {
      _handleGenerationError(e, stackTrace);
      return null;
    }
  }

  /// Handle generation errors with retry logic and throttling
  void _handleGenerationError(dynamic error, StackTrace? stackTrace) {
    _consecutiveErrors++;
    _lastErrorTime = DateTime.now();

    logger.e('TTS generation error', error: error, stackTrace: stackTrace);

    // Determine if we should attempt recovery
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      logger.e('Maximum consecutive TTS errors reached, throttling');
      throw TTSError(
        'Maximum consecutive errors reached',
        ErrorType.maxRetriesExceeded,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Check if error is recoverable
    if (_isRecoverableError(error)) {
      logger.i('Attempting TTS recovery after error');
      _isInitialized = false; // Force reinitialization on next use
    } else {
      throw TTSError(
        'TTS generation failed: $error',
        ErrorType.generationFailed,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if error is recoverable
  bool _isRecoverableError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('null') ||
        errorMessage.contains('memory') ||
        errorMessage.contains('allocation') ||
        errorMessage.contains('thread');
  }

  /// Check if generation should be throttled due to excessive errors
  bool _shouldThrottle() {
    if (_consecutiveErrors == 0) return false;

    final now = DateTime.now();
    if (_lastErrorTime != null &&
        now.difference(_lastErrorTime!) > _errorResetDuration) {
      // Reset error counter after cooldown period
      _consecutiveErrors = 0;
      return false;
    }

    return _consecutiveErrors >= _maxConsecutiveErrors;
  }

  /// Enhanced dispose with proper resource cleanup
  Future<void> dispose() async {
    if (_isDisposing) return;
    _isDisposing = true;

    logger.i('Disposing TTS engine...');

    try {
      // Free TTS resources
      if (_tts != null) {
        try {
          _tts!.free();
        } catch (e) {
          logger.w('Error freeing TTS during dispose: $e');
        }
        _tts = null;
      }

      _isInitialized = false;
      _initCompleter = null;

      logger.i('TTS engine disposed successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Error during TTS engine dispose',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// TTS Result wrapper for better type safety
class TTSResult {
  final sherpa.GeneratedAudio audio;

  TTSResult(this.audio);

  /// Convert to PCM16 audio data
  Uint8List? toPCM16() {
    try {
      if (audio.samples != null && audio.samples is Float32List) {
        final samples = audio.samples as Float32List;
        final pcm = Uint8List(samples.length * 2);
        final bd = ByteData.view(pcm.buffer);

        for (var i = 0; i < samples.length; i++) {
          var s = samples[i];
          if (s > 1.0) s = 1.0;
          if (s < -1.0) s = -1.0;
          final int val = (s * 32767).toInt();
          bd.setInt16(i * 2, val, Endian.little);
        }

        return pcm;
      }
      return null;
    } catch (e) {
      logger.e('Error converting TTS to PCM16', error: e);
      return null;
    }
  }
}

/// TTS-specific error for better error handling
class TTSError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  TTSError(this.message, this.type, {this.originalError, this.stackTrace});

  @override
  String toString() => 'TTSError($type): $message';
}

enum ErrorType {
  initialization,
  modelLoad,
  generationFailed,
  disposing,
  throttled,
  maxRetriesExceeded,
}
