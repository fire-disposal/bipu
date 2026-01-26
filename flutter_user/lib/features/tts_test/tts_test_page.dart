import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../services/tts_service.dart';

class TtsTestPage extends StatefulWidget {
  const TtsTestPage({super.key});

  @override
  State<TtsTestPage> createState() => _TtsTestPageState();
}

class _TtsTestPageState extends State<TtsTestPage> {
  final TtsService _ttsService = TtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sidController = TextEditingController(text: '0');

  String _status = "Initializing...";
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _speed = 1.0;
  int _maxSid = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _ttsService.init();
      setState(() {
        _isInitialized = true;
        _status = "Ready. Enter text and press Generate.";
        _maxSid = 173; // vits-zh-aishell3 supports 174 speakers (0-173)
      });
    } catch (e) {
      setState(() {
        _status = "Initialization failed: $e";
      });
    }
  }

  Future<void> _generateAndPlay() async {
    if (!_isInitialized) {
      setState(() {
        _status = "TTS not initialized.";
      });
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _status = "Please enter text.";
      });
      return;
    }

    final sid = int.tryParse(_sidController.text) ?? 0;
    if (sid < 0 || sid > _maxSid) {
      setState(() {
        _status = "Invalid speaker ID. Must be between 0 and $_maxSid.";
      });
      return;
    }

    setState(() {
      _status = "Generating audio...";
    });

    try {
      final audio = await _ttsService.generate(
        text: text,
        sid: sid,
        speed: _speed,
      );

      if (audio != null) {
        // Save to temporary WAV file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_output.wav');
        sherpa.writeWave(
          filename: tempFile.path,
          samples: audio.samples,
          sampleRate: audio.sampleRate,
        );

        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        setState(() {
          _status = "Playing audio...";
          _isPlaying = true;
        });

        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() {
            _status = "Playback completed.";
            _isPlaying = false;
          });
          tempFile.delete(); // Clean up
        });
      } else {
        setState(() {
          _status = "Failed to generate audio.";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    _sidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to synthesize',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sidController,
              decoration: InputDecoration(
                labelText: 'Speaker ID (0-$_maxSid)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Speed:'),
                Expanded(
                  child: Slider(
                    value: _speed,
                    min: 0.5,
                    max: 3.0,
                    divisions: 25,
                    label: _speed.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _speed = value;
                      });
                    },
                  ),
                ),
                Text(_speed.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isInitialized && !_isPlaying
                  ? _generateAndPlay
                  : null,
              child: const Text('Generate and Play'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
