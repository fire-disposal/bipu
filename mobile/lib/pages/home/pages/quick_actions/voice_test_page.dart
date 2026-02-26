import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/voice/asr_engine.dart';
import '../../../../core/voice/voice_service.dart';
import '../../../../core/utils/logger.dart';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sidController = TextEditingController(text: '0');
  final ASREngine _asrEngine = ASREngine();
  final VoiceService _voiceService = VoiceService();

  String _asrResult = "";
  String _asrStatus = "ASR Ready";
  bool _isRecording = false;
  double _volume = 0.0;

  String _ttsStatus = "TTS Ready";
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _speed = 1.0;
  int _maxSid = 173;
  bool _ttsMode = false; // false: ASR, true: TTS

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _voiceService.init();
      setState(() {
        _isInitialized = true;
        _ttsStatus = "TTS Ready";
      });
    } catch (e) {
      logger.e('Failed to initialize VoiceService: $e');
      if (mounted) {
        setState(() {
          _ttsStatus = "TTS initialization failed: $e";
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _sidController.dispose();
    _asrEngine.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _asrStatus = "Listening...";
        _asrResult = "";
        _volume = 0.0;
      });

      await _asrEngine.init();
      await _asrEngine.startRecording();

      // 监听识别结果
      _asrEngine.onResult.listen((result) {
        if (mounted) {
          setState(() {
            _asrResult = result;
          });
        }
      });

      // 监听音量
      _asrEngine.onVolume.listen((volume) {
        if (mounted) {
          setState(() {
            _volume = volume;
          });
        }
      });
    } catch (e) {
      logger.e('Failed to start recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _asrStatus = "Recording failed: $e";
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await _asrEngine.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _asrStatus = "Recording stopped";
          if (result.isNotEmpty) {
            _asrResult = result;
          }
        });
      }
    } catch (e) {
      logger.e('Failed to stop recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _asrStatus = "Stop failed: $e";
        });
      }
    }
  }

  Future<void> _generateAndPlay() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _ttsStatus = "Please enter text.";
      });
      return;
    }

    try {
      final sidStr = _sidController.text.trim();
      final sid = int.tryParse(sidStr) ?? 0;

      if (sid < 0 || sid > _maxSid) {
        setState(() {
          _ttsStatus = "Speaker ID must be between 0 and $_maxSid";
        });
        return;
      }

      setState(() {
        _ttsStatus = "Generating audio...";
        _isPlaying = true;
      });

      await _voiceService.speak(text, sid: sid, speed: _speed);

      if (mounted) {
        setState(() {
          _ttsStatus = "Playback completed.";
          _isPlaying = false;
        });
      }
    } catch (e) {
      logger.e('Failed to generate and play: $e');
      if (mounted) {
        setState(() {
          _ttsStatus = "Error: $e";
          _isPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('voice_test'.tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(value: false, label: Text('ASR'.tr())),
                  ButtonSegment<bool>(value: true, label: Text('TTS'.tr())),
                ],
                selected: {_ttsMode},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _ttsMode = newSelection.first;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: _ttsMode ? _buildTTSContent() : _buildASRContent(),
    );
  }

  Widget _buildASRContent() {
    return Column(
      children: [
        // ASR 状态卡片
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: _isRecording ? Colors.green.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _asrStatus,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _volume,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green[400]!,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // 识别结果显示
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
        // 录音控制按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRecording ? null : _startRecording,
                  icon: const Icon(Icons.mic),
                  label: Text('start'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: Text('stop'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTTSContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // TTS 状态卡片
                Card(
                  color: _isPlaying ? Colors.blue.shade50 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _ttsStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 文本输入
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'enter_text_to_synthesize'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                // Speaker ID 输入
                TextField(
                  controller: _sidController,
                  decoration: InputDecoration(
                    labelText: 'speaker_id'.tr(args: ['0', '$_maxSid']),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // 速度调节
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('speed'.tr()),
                            Text(
                              _speed.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Slider(
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 生成和播放按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isInitialized && !_isPlaying
                  ? _generateAndPlay
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: Text('generate_and_play'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
