import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Simple async mutex for coordinating audio resource usage between
/// TTS playback and ASR/recording across the app.
class AudioResourceManager {
  static final AudioResourceManager _instance =
      AudioResourceManager._internal();
  factory AudioResourceManager() => _instance;
  AudioResourceManager._internal();
  final Queue<Completer<void>> _queue = Queue<Completer<void>>();
  bool _locked = false;

  /// Acquire the audio resource. Returns a token (function) to release it.
  Future<VoidCallback> acquire({Duration? timeout}) async {
    if (!_locked) {
      _locked = true;
      return _makeReleaser();
    }

    final completer = Completer<void>();
    _queue.add(completer);

    try {
      if (timeout != null) {
        await completer.future.timeout(timeout);
      } else {
        await completer.future;
      }
    } catch (e) {
      // timed out -> remove from queue if still present
      _queue.remove(completer);
      rethrow;
    }

    return _makeReleaser();
  }

  /// Try to acquire without waiting. Returns release callback or null.
  Future<VoidCallback?> tryAcquire() async {
    if (!_locked) {
      _locked = true;
      return _makeReleaser();
    }
    return null;
  }

  VoidCallback _makeReleaser() {
    var released = false;
    return () {
      if (released) return;
      released = true;
      if (_queue.isNotEmpty) {
        final next = _queue.removeFirst();
        // grant to next waiter
        Future.microtask(() => next.complete());
      } else {
        _locked = false;
      }
    };
  }
}
