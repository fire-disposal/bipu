import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_user/features/assistant/assistant_controller.dart';

/// Lightweight controller that listens to audio sample stream and exposes
/// a rolling amplitude buffer via `ValueListenable` (itself via ChangeNotifier).
class WaveformController extends ChangeNotifier {
  final AssistantController _assistant;
  StreamSubscription<double>? _sub;

  // Rolling buffer of normalized amplitude values [0..1]
  final List<double> amplitudes = [];
  final int maxPoints;

  WaveformController(this._assistant, {this.maxPoints = 200});

  void start() {
    if (_sub != null) return;
    _sub = _assistant.onVolume.listen((v) {
      _pushAmplitude(v);
    }, onError: (_) {});
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  bool get isRunning => _sub != null;

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void _pushAmplitude(double v) {
    // simple smoothing
    final smooth = (amplitudes.isNotEmpty)
        ? (amplitudes.last * 0.6 + v * 0.4)
        : v;
    amplitudes.add(smooth.clamp(0.0, 1.0));
    if (amplitudes.length > maxPoints) amplitudes.removeAt(0);
    notifyListeners();
  }
}
