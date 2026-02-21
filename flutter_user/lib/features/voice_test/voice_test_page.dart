import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../assistant/assistant_controller.dart';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage>
    with TickerProviderStateMixin {
  final AssistantController _assistant = AssistantController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sidController = TextEditingController(text: '0');

  late TabController _tabController;

  // ASR state
  StreamSubscription<String>? _asrResultSubscription;
  String _asrResult = "";
  String _asrStatus = "Initializing ASR...";
  bool _isRecording = false;

  // TTS state
  String _ttsStatus = "Initializing TTS...";
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _speed = 1.0;
  int _maxSid = 173;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      await _assistant.init();
      _asrResultSubscription = _assistant.onResult.listen((text) {
        if (mounted) {
          setState(() {
            _asrResult = text;
          });
        }
      });

      if (mounted) {
        setState(() {
          _asrStatus = "ASR Ready. Press Start to speak.";
          _isInitialized = true;
          _ttsStatus = "TTS Ready. Enter text and press Generate.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _asrStatus = "Initialization failed: $e";
          _ttsStatus = "Initialization failed: $e";
        });
      }
    }
  }

  // ASR methods
  Future<void> _startRecording() async {
    try {
      await _assistant.startListening();
      setState(() {
        _isRecording = true;
        _asrStatus = "Listening...";
        _asrResult = "";
      });
    } catch (e) {
      setState(() {
        _asrStatus = "Failed to start recording: $e";
      });
    }
  }

  Future<void> _stopRecording() async {
    await _assistant.stopListening();
    setState(() {
      _isRecording = false;
      _asrStatus = "Stopped";
    });
  }

  // TTS methods
  Future<void> _generateAndPlay() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _ttsStatus = "Please enter text.";
      });
      return;
    }
    final sid = int.tryParse(_sidController.text) ?? 0;
    setState(() {
      _ttsStatus = "Generating and playing...";
      _isPlaying = true;
    });
    try {
      await _assistant.speakText(text, sid: sid, speed: _speed);
      if (mounted) {
        setState(() {
          _ttsStatus = "Playback completed.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ttsStatus = "Error: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _sidController.dispose();
    _asrResultSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Engine Test'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ASR (Speech to Text)'),
            Tab(text: 'TTS (Text to Speech)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAsrTab(), _buildTtsTab()],
      ),
    );
  }

  Widget _buildAsrTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: _isRecording ? Colors.red.shade50 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _asrStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _asrResult.isEmpty ? "(Waiting for speech...)" : _asrResult,
                  style: const TextStyle(fontSize: 20),
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
        ],
      ),
    );
  }

  Widget _buildTtsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text to speak',
              border: OutlineInputBorder(),
              hintText: 'Enter some text here...',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sidController,
            decoration: InputDecoration(
              labelText: 'Speaker ID (0-$_maxSid)',
              border: const OutlineInputBorder(),
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
                  max: 2.0,
                  divisions: 15,
                  label: _speed.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _speed = v),
                ),
              ),
              Text('${_speed.toStringAsFixed(1)}x'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isInitialized && !_isPlaying ? _generateAndPlay : null,
            icon: _isPlaying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Generate & Play'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Status: $_ttsStatus',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
