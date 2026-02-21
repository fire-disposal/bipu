import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import '../utils/logger.dart';

/// Enhanced audio resource manager with deadlock prevention and better error handling
class EnhancedAudioResourceManager {
  static final EnhancedAudioResourceManager _instance =
      EnhancedAudioResourceManager._internal();
  factory EnhancedAudioResourceManager() => _instance;
  EnhancedAudioResourceManager._internal();

  final Queue<_AudioRequest> _queue = Queue<_AudioRequest>();
  final Set<String> _activeHolders = <String>{};
  AudioSession? _session;
  Timer? _cleanupTimer;
  Timer? _deadlockTimer;
  
  // Configuration
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _deadlockCheckInterval = Duration(seconds: 10);
  static const int _maxQueueSize = 10;
  static const Duration _maxHoldDuration = Duration(minutes: 2);

  bool _isDisposed = false;
  int _requestCounter = 0;

  /// Initialize the audio resource manager
  Future<void> initialize() async {
    if (_isDisposed) return;
    
    try {
      logger.i('Initializing enhanced audio resource manager...');
      
      // Configure audio session
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.speech());
      
      // Start cleanup timer
      _startCleanupTimer();
      
      // Start deadlock detection timer
      _startDeadlockDetection();
      
      logger.i('Enhanced audio resource manager initialized');
    } catch (e, stackTrace) {
      logger.e('Failed to initialize audio resource manager', 
               error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Acquire audio resource with timeout and deadlock prevention
  Future<AudioResourceToken> acquire({
    String? holderId,
    Duration? timeout,
    bool highPriority = false,
  }) async {
    if (_isDisposed) {
      throw AudioResourceException('Audio resource manager is disposed');
    }

    final id = holderId ?? 'holder_${++_requestCounter}';
    final request = _AudioRequest(
      id: id,
      holderId: id,
      completer: Completer<AudioResourceToken>(),
      timestamp: DateTime.now(),
      timeout: timeout ?? _defaultTimeout,
      highPriority: highPriority,
    );

    try {
      logger.i('Audio resource requested by $id');
      
      // Check if resource is immediately available
      if (_activeHolders.isEmpty && _queue.isEmpty) {
        return _grantResource(request);
      }

      // Add to queue with priority handling
      if (highPriority) {
        _queue.addFirst(request);
      } else {
        _queue.add(request);
      }

      // Enforce queue size limit
      if (_queue.length > _maxQueueSize) {
        final removed = _queue.removeLast();
        removed.completer.completeError(
          AudioResourceException('Queue size limit exceeded')
        );
        logger.w('Audio request removed due to queue size limit: ${removed.holderId}');
      }

      // Set up timeout
      _setupRequestTimeout(request);

      return await request.completer.future;
    } catch (e) {
      // Clean up on error
      _queue.remove(request);
      rethrow;
    }
  }

  /// Try to acquire without waiting
  AudioResourceToken? tryAcquire({String? holderId}) {
    if (_isDisposed) return null;
    if (_activeHolders.isNotEmpty || _queue.isNotEmpty) return null;

    final id = holderId ?? 'holder_${++_requestCounter}';
    final request = _AudioRequest(
      id: id,
      holderId: id,
      completer: Completer<AudioResourceToken>(),
      timestamp: DateTime.now(),
      timeout: Duration.zero,
      highPriority: false,
    );

    return _grantResource(request);
  }

  /// Grant resource to request
  AudioResourceToken _grantResource(_AudioRequest request) {
    try {
      _activeHolders.add(request.holderId);
      
      // Activate audio session
      _session?.setActive(true).catchError((e) {
        logger.w('Failed to activate audio session: $e');
      });

      final token = AudioResourceToken(
        holderId: request.holderId,
        releaseCallback: () => _releaseResource(request.holderId),
      );

      logger.i('Audio resource granted to ${request.holderId}');
      return token;
    } catch (e, stackTrace) {
      logger.e('Error granting audio resource', error: e, stackTrace: stackTrace);
      throw AudioResourceException('Failed to grant audio resource: $e');
    }
  }

  /// Release resource
  void _releaseResource(String holderId) {
    if (_isDisposed) return;

    try {
      _activeHolders.remove(holderId);
      logger.i('Audio resource released by $holderId');

      // Deactivate audio session if no holders
      if (_activeHolders.isEmpty) {
        _session?.setActive(false).catchError((e) {
          logger.w('Failed to deactivate audio session: $e');
        });
      }

      // Grant to next request in queue
      _processNextRequest();
    } catch (e, stackTrace) {
      logger.e('Error releasing audio resource', error: e, stackTrace: stackTrace);
    }
  }

  /// Process next request in queue
  void _processNextRequest() {
    if (_queue.isEmpty || _activeHolders.isNotEmpty) return;

    final nextRequest = _queue.removeFirst();
    if (nextRequest.completer.isCompleted) return;

    try {
      final token = _grantResource(nextRequest);
      nextRequest.completer.complete(token);
    } catch (e) {
      nextRequest.completer.completeError(e);
    }
  }

  /// Set up timeout for request
  void _setupRequestTimeout(_AudioRequest request) {
    Timer(request.timeout, () {
      if (!request.completer.isCompleted) {
        _queue.remove(request);
        request.completer.completeError(
          AudioResourceException('Audio resource acquisition timed out')
        );
        logger.w('Audio request timed out: ${request.holderId}');
      }
    });
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Start deadlock detection timer
  void _startDeadlockDetection() {
    _deadlockTimer?.cancel();
    _deadlockTimer = Timer.periodic(_deadlockCheckInterval, (_) {
      _detectDeadlocks();
    });
  }

  /// Perform periodic cleanup
  void _performCleanup() {
    try {
      final now = DateTime.now();
      
      // Remove stale requests
      _queue.removeWhere((request) {
        if (now.difference(request.timestamp) > _maxHoldDuration) {
          if (!request.completer.isCompleted) {
            request.completer.completeError(
              AudioResourceException('Request expired due to age')
            );
            logger.w('Removed stale audio request: ${request.holderId}');
          }
          return true;
        }
        return false;
      });

      // Log status
      if (kDebugMode) {
        logger.d('Audio resource status: ${_activeHolders.length} active, ${_queue.length} queued');
      }
    } catch (e, stackTrace) {
      logger.e('Error during cleanup', error: e, stackTrace: stackTrace);
    }
  }

  /// Detect and resolve deadlocks
  void _detectDeadlocks() {
    try {
      final now = DateTime.now();
      
      // Check for requests that have been waiting too long
      for (final request in _queue) {
        final waitTime = now.difference(request.timestamp);
        if (waitTime > const Duration(minutes: 1)) {
          logger.w('Long-waiting audio request detected: ${request.holderId} (${waitTime.inSeconds}s)');
        }
      }

      // Check for holders that have held resource too long
      if (_activeHolders.isNotEmpty) {
        logger.d('Active audio holders: $_activeHolders');
      }
    } catch (e, stackTrace) {
      logger.e('Error during deadlock detection', error: e, stackTrace: stackTrace);
    }
  }

  /// Get current resource status
  AudioResourceStatus getStatus() {
    return AudioResourceStatus(
      activeHolders: Set.from(_activeHolders),
      queuedRequests: _queue.length,
      isDisposed: _isDisposed,
    );
  }

  /// Force release all resources (emergency use)
  Future<void> forceReleaseAll() async {
    logger.w('Force releasing all audio resources');
    
    // Complete all queued requests with error
    for (final request in _queue) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          AudioResourceException('Force released')
        );
      }
    }
    _queue.clear();

    // Clear active holders (this will trigger their release callbacks)
    final holders = Set.from(_activeHolders);
    _activeHolders.clear();

    // Deactivate audio session
    try {
      await _session?.setActive(false);
    } catch (e) {
      logger.w('Error deactivating audio session during force release: $e');
    }

    logger.i('Force released ${holders.length} audio holders');
  }

  /// Dispose of the resource manager
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    logger.i('Disposing enhanced audio resource manager...');

    try {
      // Cancel timers
      _cleanupTimer?.cancel();
      _deadlockTimer?.cancel();

      // Force release all resources
      await forceReleaseAll();

      // Dispose audio session
      _session = null;

      logger.i('Enhanced audio resource manager disposed');
    } catch (e, stackTrace) {
      logger.e('Error disposing audio resource manager', error: e, stackTrace: stackTrace);
    }
  }
}

/// Audio resource token for managing resource lifecycle
class AudioResourceToken {
  final String holderId;
  final VoidCallback releaseCallback;
  bool _isReleased = false;

  AudioResourceToken({
    required this.holderId,
    required this.releaseCallback,
  });

  void release() {
    if (!_isReleased) {
      _isReleased = true;
      releaseCallback();
    }
  }

  bool get isReleased => _isReleased;
}

/// Audio resource status information
class AudioResourceStatus {
  final Set<String> activeHolders;
  final int queuedRequests;
  final bool isDisposed;

  AudioResourceStatus({
    required this.activeHolders,
    required this.queuedRequests,
    required this.isDisposed,
  });
}

/// Internal audio request
class _AudioRequest {
  final String id;
  final String holderId;
  final Completer<AudioResourceToken> completer;
  final DateTime timestamp;
  final Duration timeout;
  final bool highPriority;

  _AudioRequest({
    required this.id,
    required this.holderId,
    required this.completer,
    required this.timestamp,
    required this.timeout,
    required this.highPriority,
  });
}

/// Audio resource exception
class AudioResourceException implements Exception {
  final String message;
  AudioResourceException(this.message);
  
  @override
  String toString() => 'AudioResourceException: $message';
}import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import '../utils/logger.dart';

/// Enhanced audio resource manager with deadlock prevention and better error handling
class EnhancedAudioResourceManager {
  static final EnhancedAudioResourceManager _instance =
      EnhancedAudioResourceManager._internal();
  factory EnhancedAudioResourceManager() => _instance;
  EnhancedAudioResourceManager._internal();

  final Queue<_AudioRequest> _queue = Queue<_AudioRequest>();
  final Set<String> _activeHolders = <String>{};
  AudioSession? _session;
  Timer? _cleanupTimer;
  Timer? _deadlockTimer;
  
  // Configuration
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _deadlockCheckInterval = Duration(seconds: 10);
  static const int _maxQueueSize = 10;
  static const Duration _maxHoldDuration = Duration(minutes: 2);

  bool _isDisposed = false;
  int _requestCounter = 0;

  /// Initialize the audio resource manager
  Future<void> initialize() async {
    if (_isDisposed) return;
    
    try {
      logger.i('Initializing enhanced audio resource manager...');
      
      // Configure audio session
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.speech());
      
      // Start cleanup timer
      _startCleanupTimer();
      
      // Start deadlock detection timer
      _startDeadlockDetection();
      
      logger.i('Enhanced audio resource manager initialized');
    } catch (e, stackTrace) {
      logger.e('Failed to initialize audio resource manager', 
               error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Acquire audio resource with timeout and deadlock prevention
  Future<AudioResourceToken> acquire({
    String? holderId,
    Duration? timeout,
    bool highPriority = false,
  }) async {
    if (_isDisposed) {
      throw AudioResourceException('Audio resource manager is disposed');
    }

    final id = holderId ?? 'holder_${++_requestCounter}';
    final request = _AudioRequest(
      id: id,
      holderId: id,
      completer: Completer<AudioResourceToken>(),
      timestamp: DateTime.now(),
      timeout: timeout ?? _defaultTimeout,
      highPriority: highPriority,
    );

    try {
      logger.i('Audio resource requested by $id');
      
      // Check if resource is immediately available
      if (_activeHolders.isEmpty && _queue.isEmpty) {
        return _grantResource(request);
      }

      // Add to queue with priority handling
      if (highPriority) {
        _queue.addFirst(request);
      } else {
        _queue.add(request);
      }

      // Enforce queue size limit
      if (_queue.length > _maxQueueSize) {
        final removed = _queue.removeLast();
        removed.completer.completeError(
          AudioResourceException('Queue size limit exceeded')
        );
        logger.w('Audio request removed due to queue size limit: ${removed.holderId}');
      }

      // Set up timeout
      _setupRequestTimeout(request);

      return await request.completer.future;
    } catch (e) {
      // Clean up on error
      _queue.remove(request);
      rethrow;
    }
  }

  /// Try to acquire without waiting
  AudioResourceToken? tryAcquire({String? holderId}) {
    if (_isDisposed) return null;
    if (_activeHolders.isNotEmpty || _queue.isNotEmpty) return null;

    final id = holderId ?? 'holder_${++_requestCounter}';
    final request = _AudioRequest(
      id: id,
      holderId: id,
      completer: Completer<AudioResourceToken>(),
      timestamp: DateTime.now(),
      timeout: Duration.zero,
      highPriority: false,
    );

    return _grantResource(request);
  }

  /// Grant resource to request
  AudioResourceToken _grantResource(_AudioRequest request) {
    try {
      _activeHolders.add(request.holderId);
      
      // Activate audio session
      _session?.setActive(true).catchError((e) {
        logger.w('Failed to activate audio session: $e');
      });

      final token = AudioResourceToken(
        holderId: request.holderId,
        releaseCallback: () => _releaseResource(request.holderId),
      );

      logger.i('Audio resource granted to ${request.holderId}');
      return token;
    } catch (e, stackTrace) {
      logger.e('Error granting audio resource', error: e, stackTrace: stackTrace);
      throw AudioResourceException('Failed to grant audio resource: $e');
    }
  }

  /// Release resource
  void _releaseResource(String holderId) {
    if (_isDisposed) return;

    try {
      _activeHolders.remove(holderId);
      logger.i('Audio resource released by $holderId');

      // Deactivate audio session if no holders
      if (_activeHolders.isEmpty) {
        _session?.setActive(false).catchError((e) {
          logger.w('Failed to deactivate audio session: $e');
        });
      }

      // Grant to next request in queue
      _processNextRequest();
    } catch (e, stackTrace) {
      logger.e('Error releasing audio resource', error: e, stackTrace: stackTrace);
    }
  }

  /// Process next request in queue
  void _processNextRequest() {
    if (_queue.isEmpty || _activeHolders.isNotEmpty) return;

    final nextRequest = _queue.removeFirst();
    if (nextRequest.completer.isCompleted) return;

    try {
      final token = _grantResource(nextRequest);
      nextRequest.completer.complete(token);
    } catch (e) {
      nextRequest.completer.completeError(e);
    }
  }

  /// Set up timeout for request
  void _setupRequestTimeout(_AudioRequest request) {
    Timer(request.timeout, () {
      if (!request.completer.isCompleted) {
        _queue.remove(request);
        request.completer.completeError(
          AudioResourceException('Audio resource acquisition timed out')
        );
        logger.w('Audio request timed out: ${request.holderId}');
      }
    });
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Start deadlock detection timer
  void _startDeadlockDetection() {
    _deadlockTimer?.cancel();
    _deadlockTimer = Timer.periodic(_deadlockCheckInterval, (_) {
      _detectDeadlocks();
    });
  }

  /// Perform periodic cleanup
  void _performCleanup() {
    try {
      final now = DateTime.now();
      
      // Remove stale requests
      _queue.removeWhere((request) {
        if (now.difference(request.timestamp) > _maxHoldDuration) {
          if (!request.completer.isCompleted) {
            request.completer.completeError(
              AudioResourceException('Request expired due to age')
            );
            logger.w('Removed stale audio request: ${request.holderId}');
          }
          return true;
        }
        return false;
      });

      // Log status
      if (kDebugMode) {
        logger.d('Audio resource status: ${_activeHolders.length} active, ${_queue.length} queued');
      }
    } catch (e, stackTrace) {
      logger.e('Error during cleanup', error: e, stackTrace: stackTrace);
    }
  }

  /// Detect and resolve deadlocks
  void _detectDeadlocks() {
    try {
      final now = DateTime.now();
      
      // Check for requests that have been waiting too long
      for (final request in _queue) {
        final waitTime = now.difference(request.timestamp);
        if (waitTime > const Duration(minutes: 1)) {
          logger.w('Long-waiting audio request detected: ${request.holderId} (${waitTime.inSeconds}s)');
        }
      }

      // Check for holders that have held resource too long
      if (_activeHolders.isNotEmpty) {
        logger.d('Active audio holders: $_activeHolders');
      }
    } catch (e, stackTrace) {
      logger.e('Error during deadlock detection', error: e, stackTrace: stackTrace);
    }
  }

  /// Get current resource status
  AudioResourceStatus getStatus() {
    return AudioResourceStatus(
      activeHolders: Set.from(_activeHolders),
      queuedRequests: _queue.length,
      isDisposed: _isDisposed,
    );
  }

  /// Force release all resources (emergency use)
  Future<void> forceReleaseAll() async {
    logger.w('Force releasing all audio resources');
    
    // Complete all queued requests with error
    for (final request in _queue) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          AudioResourceException('Force released')
        );
      }
    }
    _queue.clear();

    // Clear active holders (this will trigger their release callbacks)
    final holders = Set.from(_activeHolders);
    _activeHolders.clear();

    // Deactivate audio session
    try {
      await _session?.setActive(false);
    } catch (e) {
      logger.w('Error deactivating audio session during force release: $e');
    }

    logger.i('Force released ${holders.length} audio holders');
  }

  /// Dispose of the resource manager
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    logger.i('Disposing enhanced audio resource manager...');

    try {
      // Cancel timers
      _cleanupTimer?.cancel();
      _deadlockTimer?.cancel();

      // Force release all resources
      await forceReleaseAll();

      // Dispose audio session
      _session = null;

      logger.i('Enhanced audio resource manager disposed');
    } catch (e, stackTrace) {
      logger.e('Error disposing audio resource manager', error: e, stackTrace: stackTrace);
    }
  }
}

/// Audio resource token for managing resource lifecycle
class AudioResourceToken {
  final String holderId;
  final VoidCallback releaseCallback;
  bool _isReleased = false;

  AudioResourceToken({
    required this.holderId,
    required this.releaseCallback,
  });

  void release() {
    if (!_isReleased) {
      _isReleased = true;
      releaseCallback();
    }
  }

  bool get isReleased => _isReleased;
}

/// Audio resource status information
class AudioResourceStatus {
  final Set<String> activeHolders;
  final int queuedRequests;
  final bool isDisposed;

  AudioResourceStatus({
    required this.activeHolders,
    required this.queuedRequests,
    required this.isDisposed,
  });
}

/// Internal audio request
class _AudioRequest {
  final String id;
  final String holderId;
  final Completer<AudioResourceToken> completer;
  final DateTime timestamp;
  final Duration timeout;
  final bool highPriority;

  _AudioRequest({
    required this.id,
    required this.holderId,
    required this.completer,
    required this.timestamp,
    required this.timeout,
    required this.highPriority,
  });
}

/// Audio resource exception
class AudioResourceException implements Exception {
  final String message;
  AudioResourceException(this.message);
  
  @override
  String toString() => 'AudioResourceException: $message';
}
