import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../services/speech_recognition_service.dart';

class SpeechTestPage extends StatefulWidget {
  const SpeechTestPage({super.key});

  @override
  State<SpeechTestPage> createState() => _SpeechTestPageState();
}

class _SpeechTestPageState extends State<SpeechTestPage> {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final RecorderStream _recorder = RecorderStream();

  sherpa.OnlineStream? _stream;
  StreamSubscription<List<int>>? _audioSubscription;

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

    _stream = _speechService.createStream();

    _audioSubscription = _recorder.audioStream.listen((data) {
      if (_stream != null) {
        // Convert Int8List (bytes) to Float32List for sherpa_onnx
        // sound_stream returns 16-bit PCM.
        // We need to convert it to float samples normalized to [-1, 1]

        final samples = _convertBytesToFloat(data);
        _stream!.acceptWaveform(samples: samples, sampleRate: 16000);

        while (_speechService.isReady(_stream!)) {
          _speechService.decode(_stream!);
        }

        final text = _speechService.getResult(_stream!);
        if (text.isNotEmpty) {
          setState(() {
            _result = text;
          });
        }

        if (_speechService.isEndpoint(_stream!)) {
          _speechService.reset(_stream!);
        }
      }
    });

    await _recorder.start();
    setState(() {
      _isRecording = true;
      _status = "Listening...";
      _result = "";
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _audioSubscription?.cancel();
    _stream?.free();
    _stream = null;

    setState(() {
      _isRecording = false;
      _status = "Stopped";
    });
  }

  // Convert 16-bit PCM bytes to float samples
  Float32List _convertBytesToFloat(List<int> bytes) {
    final int16List = Int16List.view(Uint8List.fromList(bytes).buffer);
    final float32List = Float32List(int16List.length);
    for (var i = 0; i < int16List.length; i++) {
      float32List[i] = int16List[i] / 32768.0;
    }
    return float32List;
  }

  @override
  void dispose() {
    _recorder.stop();
    _audioSubscription?.cancel();
    _stream?.free();
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
