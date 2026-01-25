import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';

import '../../services/speech_recognition_service.dart';

class SpeechTestPage extends StatefulWidget {
  const SpeechTestPage({super.key});

  @override
  State<SpeechTestPage> createState() => _SpeechTestPageState();
}

class _SpeechTestPageState extends State<SpeechTestPage> {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final RecorderStream _recorder = RecorderStream();
  StreamSubscription<String>? _resultSubscription;

  String _result = "";
  String _status = "Initializing...";
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      setState(() {
        _status =
            "Speech recognition is not supported on Web.\nPlease run on Android, iOS, or Desktop.";
      });
      return;
    }

    try {
      await _recorder.initialize();
    } catch (e) {
      setState(() {
        _status = "Microphone initialization failed: $e";
      });
      return;
    }

    try {
      await _speechService.init();
      _resultSubscription = _speechService.onResult.listen((text) {
        setState(() {
          _result = text;
        });
      });

      setState(() {
        _status = "Ready. Press Start to speak.";
      });
    } catch (e) {
      setState(() {
        _status =
            "Initialization failed: $e\nMake sure models are in assets/models/";
      });
    }
  }

  Future<void> _startRecording() async {
    if (kIsWeb) return;

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _status = "Microphone permission denied";
      });
      return;
    }

    if (!_speechService.isInitialized) {
      setState(() {
        _status = "Service not initialized";
      });
      return;
    }

    try {
      await _recorder.start();
      _speechService.startListening(_recorder.audioStream);

      setState(() {
        _isRecording = true;
        _status = "Listening...";
        _result = "";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to start recording: $e";
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _speechService.stop();

    setState(() {
      _isRecording = false;
      _status = "Stopped";
    });
  }

  @override
  void dispose() {
    _recorder.stop();
    _resultSubscription?.cancel();
    _speechService.stop();
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Recognition Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: _isRecording ? Colors.green.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? "(No speech detected)" : _result,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? null : _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Listening'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
