import 'package:flutter/material.dart';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sidController = TextEditingController(text: '0');

  String _asrResult = "";
  String _asrStatus = "ASR Ready";
  bool _isRecording = false;

  String _ttsStatus = "TTS Ready";
  bool _isInitialized = true;
  bool _isPlaying = false;
  double _speed = 1.0;
  int _maxSid = 173;

  @override
  void dispose() {
    _textController.dispose();
    _sidController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _asrStatus = "Listening...";
      _asrResult = "";
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _asrStatus = "Stopped";
    });
  }

  Future<void> _generateAndPlay() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _ttsStatus = "Please enter text.";
      });
      return;
    }
    setState(() {
      _ttsStatus = "Generating audio...";
    });
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _ttsStatus = "Playback completed.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: _isRecording ? Colors.green.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _asrStatus,
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
                    _asrResult.isEmpty ? "(No speech detected)" : _asrResult,
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
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            Text(_ttsStatus),
          ],
        ),
      ),
    );
  }
}
