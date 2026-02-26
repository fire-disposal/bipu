import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';

class AudioBus {
  static final AudioBus _instance = AudioBus._internal();
  factory AudioBus() => _instance;
  AudioBus._internal();

  final PlayerStream _player = PlayerStream();
  final RecorderStream _recorder = RecorderStream();

  bool _recorderInitialized = false;
  bool _playerInitialized = false;

  Future<void> ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      throw Exception('Microphone permission denied');
    }
  }

  Future<void> initRecorder() async {
    if (_recorderInitialized) return;
    await _recorder.initialize();
    _recorderInitialized = true;
  }

  Future<void> initPlayer() async {
    if (_playerInitialized) return;
    await _player.initialize();
    _playerInitialized = true;
  }

  Stream<Uint8List> get audioStream => _recorder.audioStream;

  Future<void> startRecording() async {
    await ensureMicrophonePermission();
    await initRecorder();
    await _recorder.start();
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  Future<void> playAudio(Uint8List data) async {
    await initPlayer();
    _player.writeChunk(data);
  }

  Future<void> stopPlaying() async {
    _player.stop();
  }

  void dispose() {
    _recorder.stop();
    _player.stop();
  }
}
