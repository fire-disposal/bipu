import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/voice/voice_service_unified.dart';
import '../../../../core/utils/logger.dart';

class VoiceTestPage extends StatefulWidget {
  const VoiceTestPage({super.key});

  @override
  State<VoiceTestPage> createState() => _VoiceTestPageState();
}

class _VoiceTestPageState extends State<VoiceTestPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sidController = TextEditingController(text: '0');
  final VoiceService _voiceService = VoiceService();

  StreamSubscription<String>? _resultSubscription;
  StreamSubscription<double>? _volumeSubscription;

  String _asrResult = '';
  bool _isRecording = false;
  double _volume = 0.0;

  String _ttsStatus = 'Ready';
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _speed = 1.0;
  static const int _maxSid = 173;

  bool _ttsMode = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _voiceService.init();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      logger.e('VoiceService init failed: $e');
      if (mounted) setState(() => _ttsStatus = 'Init failed');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _sidController.dispose();
    _resultSubscription?.cancel();
    _volumeSubscription?.cancel();
    super.dispose();
  }

  //  ASR 

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _resultSubscription?.cancel();
      await _volumeSubscription?.cancel();
      setState(() {
        _isRecording = true;
        _asrResult = '';
        _volume = 0.0;
      });
      await _voiceService.startRecording();
      _resultSubscription = _voiceService.recognitionResults.listen((r) {
        if (mounted && _isRecording) setState(() => _asrResult = r);
      });
      _volumeSubscription = _voiceService.volumeStream.listen((v) {
        if (mounted && _isRecording) setState(() => _volume = v);
      });
    } catch (e) {
      logger.e('Start recording failed: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await _voiceService.stopRecording();
      await _resultSubscription?.cancel();
      await _volumeSubscription?.cancel();
      _resultSubscription = null;
      _volumeSubscription = null;
      if (mounted) {
        setState(() {
          _isRecording = false;
          _volume = 0.0;
          if (result.isNotEmpty) _asrResult = result;
        });
      }
    } catch (e) {
      logger.e('Stop recording failed: $e');
      if (mounted) setState(() { _isRecording = false; _volume = 0.0; });
    }
  }

  //  TTS 

  Future<void> _generateAndPlay() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final sid = int.tryParse(_sidController.text.trim()) ?? 0;
    if (sid < 0 || sid > _maxSid) {
      setState(() => _ttsStatus = 'SID must be 0$_maxSid');
      return;
    }
    try {
      setState(() { _ttsStatus = 'Generating'; _isPlaying = true; });
      await _voiceService.speak(text, sid: sid, speed: _speed);
      if (mounted) setState(() { _ttsStatus = 'Done'; _isPlaying = false; });
    } catch (e) {
      logger.e('TTS failed: $e');
      if (mounted) setState(() { _ttsStatus = 'Error'; _isPlaying = false; });
    }
  }

  Future<void> _stopPlaying() async {
    await _voiceService.stopSpeaking();
    if (mounted) setState(() { _ttsStatus = 'Stopped'; _isPlaying = false; });
  }

  //  Build 

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('voice_test'.tr()),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.mic_outlined), label: Text('ASR')),
                ButtonSegment(value: true, icon: Icon(Icons.record_voice_over_outlined), label: Text('TTS')),
              ],
              selected: {_ttsMode},
              onSelectionChanged: (s) => setState(() => _ttsMode = s.first),
            ),
          ),
        ),
      ),
      body: _ttsMode ? _buildTTS(cs) : _buildASR(cs),
    );
  }

  //  ASR Panel 

  Widget _buildASR(ColorScheme cs) {
    return Column(
      children: [
        // Volume bar  visible only while recording
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _isRecording ? 3 : 0,
          child: LinearProgressIndicator(
            value: _volume,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),

        // Result area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isRecording
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.outline.withValues(alpha: 0.2),
                ),
              ),
              child: _asrResult.isEmpty
                  ? Center(
                      child: Text(
                        _isRecording ? 'Listening' : 'Tap mic to record',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                      ),
                    )
                  : SelectableText(
                      _asrResult,
                      style: const TextStyle(fontSize: 16, height: 1.65),
                    ),
            ),
          ),
        ),

        // Mic FAB
        Padding(
          padding: const EdgeInsets.only(bottom: 36),
          child: GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? cs.error : cs.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? cs.error : cs.primary).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: cs.onPrimary,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  //  TTS Panel 

  Widget _buildTTS(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text input  takes remaining space
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'enter_text_to_synthesize'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SID + Speed row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Speaker ID field
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _sidController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'SID',
                    hintText: '0$_maxSid',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Speed slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('speed'.tr(), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        Text(
                          _speed.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Slider(
                      value: _speed,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Status line
          Text(
            _ttsStatus,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          // Play / Stop button
          FilledButton.icon(
            onPressed: _isInitialized
                ? (_isPlaying ? _stopPlaying : _generateAndPlay)
                : null,
            icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(_isPlaying ? 'stop'.tr() : 'generate_and_play'.tr()),
            style: FilledButton.styleFrom(
              backgroundColor: _isPlaying ? cs.error : cs.primary,
              foregroundColor: _isPlaying ? cs.onError : cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
