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

  String _currentModel = 'default';

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
        setState(() {
          _asrResult = text;
        });
      });

      setState(() {
        _asrStatus = "ASR Ready. Press Start to speak.";
        _isInitialized = true;
        _ttsStatus = "TTS Ready. Enter text and press Generate.";
      });
    } catch (e) {
      setState(() {
        _asrStatus = "Initialization failed: $e";
        _ttsStatus = "Initialization failed: $e";
      });
    }
  }

  // ASR methods
  Future<void> _startRecording() async {
    if (kIsWeb) return;

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
      _ttsStatus = "Generating audio...";
    });
    try {
      await _assistant.speakText(text, sid: sid, speed: _speed);
      setState(() {
        _ttsStatus = "Playback completed.";
      });
    } catch (e) {
      setState(() {
        _ttsStatus = "Error: $e";
      });
    }
  }

  void _switchModel(String model) {
    setState(() {
      _currentModel = model;
      _asrStatus = "Switched to $model model for ASR";
      _ttsStatus = "Switched to $model model for TTS";
    });
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
        title: const Text('Voice Test'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ASR'),
            Tab(text: 'TTS'),
          ],
        ),
        actions: [
          Text('Model: $_currentModel'),
          PopupMenuButton<String>(
            onSelected: _switchModel,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'default',
                child: Text('Default Model'),
              ),
              const PopupMenuItem(value: 'fast', child: Text('Fast Model')),
              const PopupMenuItem(
                value: 'accurate',
                child: Text('Accurate Model'),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ASR Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        _asrResult.isEmpty
                            ? "(No speech detected)"
                            : _asrResult,
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
          // TTS Tab
          Padding(
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
                Text(_ttsStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
