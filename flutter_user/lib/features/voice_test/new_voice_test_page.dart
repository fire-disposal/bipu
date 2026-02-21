import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:piper_tts_plugin/piper_tts_plugin.dart';
import 'package:piper_tts_plugin/enums/piper_voice_pack.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:bipupu/core/utils/logger.dart';

/// 新的语音测试页面
/// 测试Piper TTS + 基础录音功能
class NewVoiceTestPage extends StatefulWidget {
  const NewVoiceTestPage({super.key});

  @override
  State<NewVoiceTestPage> createState() => _NewVoiceTestPageState();
}

class _NewVoiceTestPageState extends State<NewVoiceTestPage> {
  // Piper TTS相关
  final PiperTtsPlugin _piper = PiperTtsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  PiperVoicePack _selectedVoice = PiperVoicePack.norman;
  bool _isTtsSpeaking = false;
  String _ttsStatus = '未初始化';
  File? _currentAudioFile;

  // 录音相关
  final RecorderStream _recorder = RecorderStream();
  bool _isRecording = false;
  String _asrStatus = '未初始化';
  String _recordedText = '';
  StreamSubscription? _recorderSub;

  // 日志
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog('语音测试页面初始化');
    _initializeServices();
  }

  @override
  void dispose() {
    _recorderSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > 50) {
      _logs.removeLast();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeServices() async {
    try {
      // 初始化录音权限
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        await _recorder.initialize();
        setState(() {
          _asrStatus = '录音已就绪';
        });
        _addLog('录音服务初始化成功');
      } else {
        setState(() {
          _asrStatus = '麦克风权限被拒绝';
        });
        _addLog('麦克风权限被拒绝');
      }

      // 初始化TTS
      setState(() {
        _ttsStatus = 'TTS已就绪';
      });
      _addLog('TTS服务初始化成功');
    } catch (e, stackTrace) {
      _addLog('服务初始化失败: $e');
      logger.e('服务初始化失败', error: e, stackTrace: stackTrace);
    }
  }

  // ==================== Piper TTS 功能 ====================

  Future<void> _testPiperTTS(String text) async {
    if (text.isEmpty) {
      _addLog('请输入要合成的文本');
      return;
    }

    if (_isTtsSpeaking) {
      _addLog('TTS正在播放中，请稍候');
      return;
    }

    setState(() {
      _isTtsSpeaking = true;
      _ttsStatus = '合成中...';
    });

    try {
      _addLog('开始Piper TTS合成: "$text"');

      // 清理之前的音频文件
      _cleanupAudioFile();

      // 获取临时目录
      final dir = await getTemporaryDirectory();
      final outputFile = File(
        '${dir.path}/piper_test_${DateTime.now().millisecondsSinceEpoch}.wav',
      );

      // 合成语音到文件
      final audioFile = await _piper.synthesizeToFile(
        text: text.trim(),
        outputPath: outputFile.path,
      );

      _currentAudioFile = audioFile;
      _addLog('Piper TTS合成完成，文件: ${audioFile.path}');

      // 播放音频
      await _audioPlayer.setFilePath(audioFile.path);
      await _audioPlayer.play();

      setState(() {
        _ttsStatus = '播放中...';
      });

      // 等待播放完成
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );

      setState(() {
        _ttsStatus = '播放完成';
      });
      _addLog('Piper TTS播放完成');
    } catch (e, stackTrace) {
      setState(() {
        _ttsStatus = '合成失败: $e';
      });
      _addLog('Piper TTS合成失败: $e');
      logger.e('Piper TTS测试失败', error: e, stackTrace: stackTrace);
    } finally {
      setState(() {
        _isTtsSpeaking = false;
      });
    }
  }

  void _cleanupAudioFile() {
    if (_currentAudioFile != null && _currentAudioFile!.existsSync()) {
      try {
        _currentAudioFile!.deleteSync();
        _currentAudioFile = null;
      } catch (e) {
        _addLog('清理音频文件失败: $e');
      }
    }
  }

  // ==================== 录音功能 ====================

  Future<void> _startRecording() async {
    if (_isRecording) {
      _addLog('已经在录音中');
      return;
    }

    // 检查麦克风权限
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _addLog('麦克风权限被拒绝');
      return;
    }

    try {
      _addLog('开始录音...');
      await _recorder.start();

      _recorderSub = _recorder.audioStream.listen((data) {
        // 这里可以添加音频处理逻辑
        // 实际项目中可以集成ASR引擎
      });

      setState(() {
        _isRecording = true;
        _asrStatus = '录音中...';
        _recordedText = '';
      });
      _addLog('录音已开始');
    } catch (e, stackTrace) {
      _addLog('开始录音失败: $e');
      logger.e('开始录音失败', error: e, stackTrace: stackTrace);
      _stopRecording();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      _recorderSub?.cancel();
      _recorderSub = null;

      setState(() {
        _isRecording = false;
        _asrStatus = '录音完成';
        // 模拟识别结果
        _recordedText = '这是模拟的语音识别结果（实际需要集成ASR引擎）';
      });
      _addLog('录音已停止');
    } catch (e, stackTrace) {
      _addLog('停止录音失败: $e');
      logger.e('停止录音失败', error: e, stackTrace: stackTrace);
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeServices,
            tooltip: '重新初始化服务',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TTS测试部分
            _buildTTSSection(),
            const SizedBox(height: 24),
            // 录音测试部分
            _buildRecordingSection(),
            const SizedBox(height: 24),
            // 日志部分
            _buildLogSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSSection() {
    final TextEditingController _ttsController = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Piper TTS 测试',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ttsController,
              decoration: const InputDecoration(
                labelText: '输入要合成的文本',
                border: OutlineInputBorder(),
                hintText: '请输入要转换为语音的文本...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '状态: $_ttsStatus',
                    style: TextStyle(
                      color: _isTtsSpeaking ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isTtsSpeaking
                      ? null
                      : () => _testPiperTTS(_ttsController.text),
                  child: _isTtsSpeaking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('合成并播放'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButton<PiperVoicePack>(
              value: _selectedVoice,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVoice = value;
                  });
                  _addLog('切换语音包: ${value.name}');
                }
              },
              items: PiperVoicePack.values.map((voice) {
                return DropdownMenuItem(value: voice, child: Text(voice.name));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '录音测试',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '状态: $_asrStatus',
              style: TextStyle(color: _isRecording ? Colors.red : Colors.green),
            ),
            const SizedBox(height: 12),
            if (_recordedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '识别结果: $_recordedText',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? null : _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('开始录音'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止录音'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '运行日志',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Text(
                    log,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Monospace',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                    _addLog('日志已清空');
                  },
                  child: const Text('清空日志'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
