import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../models/operator/virtual_operator.dart';

class VoiceGuideService extends ChangeNotifier {
  static final VoiceGuideService _instance = VoiceGuideService._internal();
  factory VoiceGuideService() => _instance;
  VoiceGuideService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  VirtualOperator _currentOperator = defaultOperators.first;
  VirtualOperator get currentOperator => _currentOperator;

  // Cooldown management
  final Map<String, DateTime> _lastPlayedTime = {};

  // Config
  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;
  double _volume = 1.0;

  // Events
  final StreamController<String> _playbackStatusController =
      StreamController.broadcast();
  Stream<String> get onPlaybackStatus => _playbackStatusController.stream;

  Future<void> init() async {
    // Initialize audio session if needed (often handled by OS/plugin automatically for simple cases)
    await _audioPlayer.setVolume(_volume);
    _audioPlayer.onPlayerComplete.listen((_) {
      _playbackStatusController.add('complete');
    });
  }

  void setOperator(VirtualOperator op) {
    if (_currentOperator == op) return;
    _currentOperator = op;
    notifyListeners();
    playVoice('greeting', interrupt: true);
  }

  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stop();
    }
    notifyListeners();
  }

  /// Play a voice clip associated with a specific key (e.g., 'welcome', 'error_network').
  ///
  /// [key]: The semantic key for the voice clip.
  /// [interrupt]: If true, stops current playback immediately.
  /// [cooldown]: If provided, this specific key won't be played again for this duration.
  /// [ignoreCooldown]: Force play even if in cooldown.
  Future<void> playVoice(
    String key, {
    bool interrupt = true,
    Duration? cooldown,
    bool ignoreCooldown = false,
  }) async {
    if (!_isEnabled) return;

    // Check cooldown
    if (!ignoreCooldown && cooldown != null) {
      final lastPlayed = _lastPlayedTime[key];
      if (lastPlayed != null &&
          DateTime.now().difference(lastPlayed) < cooldown) {
        debugPrint('[VoiceGuide] Skipped "$key" due to cooldown.');
        return;
      }
    }

    if (interrupt) {
      await _audioPlayer.stop();
    } else {
      if (_audioPlayer.state == PlayerState.playing) {
        return; // Busy, and we don't want to interrupt
      }
    }

    try {
      // Construct asset path based on operator voice ID
      // Assuming assets structure: assets/audio/voices/{voicePackageId}/{key}.mp3
      // For demo, we might fall back to a generic sound or simulate.
      // Since I don't have real files, I'll log this.
      // In a real app, I would do:
      // final path = 'audio/voices/${_currentOperator.voicePackageId}/$key.mp3';
      // await _audioPlayer.play(AssetSource(path));

      debugPrint(
        '[VoiceGuide] Playing: ${_currentOperator.voicePackageId}/$key',
      );

      // Update cooldown
      if (cooldown != null) {
        _lastPlayedTime[key] = DateTime.now();
      }

      _playbackStatusController.add('playing:$key');

      // TODO: Actual asset playback when files exist
      // await _audioPlayer.play(AssetSource('audio/voices/${_currentOperator.voicePackageId}/$key.mp3'));
    } catch (e) {
      debugPrint('[VoiceGuide] Error playing voice: $e');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
    _playbackStatusController.close();
    super.dispose();
  }
}
