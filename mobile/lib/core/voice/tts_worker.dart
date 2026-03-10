import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ServicesBinding;

/// 简化版 TTS Worker - 使用 Isolate 后台生成
class TtsWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  bool _ready = false;

  bool get isReady => _ready;

  /// 初始化 TTS Worker
  Future<void> init() async {
    if (_ready) return;

    debugPrint('[TTS] TtsWorker: 启动 Isolate...');

    final setupPort = ReceivePort();
    final token = RootIsolateToken.instance!;
    _isolate = await Isolate.spawn(_entryPoint, (
      setupPort.sendPort,
      token,
    ), debugName: 'TTS-Worker');

    _sendPort = await setupPort.first as SendPort;
    setupPort.close();

    // 加载模型
    final initPort = ReceivePort();
    _sendPort!.send({'type': 'init', 'reply': initPort.sendPort});

    final result = await initPort.first;
    initPort.close();

    if (result is! Map || result['success'] != true) {
      throw Exception('TTS Worker 初始化失败：${result['error']}');
    }

    _ready = true;
    debugPrint('[TTS] ✅ 就绪');
  }

  /// 生成 TTS 音频
  Future<Uint8List?> generate(
    String text, {
    int sid = 0,
    double speed = 1.0,
  }) async {
    if (!_ready) await init();

    final replyPort = ReceivePort();
    _sendPort!.send({
      'type': 'generate',
      'text': text,
      'sid': sid,
      'speed': speed,
      'reply': replyPort.sendPort,
    });

    try {
      final result = await replyPort.first.timeout(const Duration(seconds: 30));
      replyPort.close();
      return result as Uint8List?;
    } on TimeoutException {
      debugPrint('[TTS WARN] generate: 超时');
      replyPort.close();
      return null;
    } catch (e) {
      debugPrint('[TTS ERROR] generate: 失败 - $e');
      replyPort.close();
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    _sendPort?.send({'type': 'dispose'});
    Future.delayed(const Duration(milliseconds: 200), () {
      _isolate?.kill(priority: Isolate.immediate);
    });
    _sendPort = null;
    _isolate = null;
    _ready = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate 入口
// ─────────────────────────────────────────────────────────────────────────────

void _entryPoint((SendPort, RootIsolateToken) args) {
  final mainPort = args.$1;
  final token = args.$2;

  // 初始化 BackgroundIsolateBinaryMessenger 以支持 rootBundle
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final port = ReceivePort();
  mainPort.send(port.sendPort);

  sherpa.OfflineTts? tts;

  port.listen((msg) {
    if (msg is! Map) return;

    final type = msg['type'] as String?;
    final reply = msg['reply'] as SendPort?;

    switch (type) {
      case 'init':
        try {
          sherpa.initBindings();

          // 从 assets 复制模型（同步）
          final dir = _getModelsDirSync();
          final modelPath = '$dir/vits-zh-hf-fanchen-C.onnx';
          final tokensPath = '$dir/tokens.txt';
          final lexiconPath = '$dir/lexicon.txt';

          tts = sherpa.OfflineTts(
            sherpa.OfflineTtsConfig(
              model: sherpa.OfflineTtsModelConfig(
                vits: sherpa.OfflineTtsVitsModelConfig(
                  model: modelPath,
                  lexicon: lexiconPath,
                  tokens: tokensPath,
                ),
                numThreads: 4,
                debug: false,
              ),
            ),
          );

          reply?.send({'success': true});
        } catch (e) {
          reply?.send({'success': false, 'error': e.toString()});
        }
        break;

      case 'generate':
        if (tts == null) {
          reply?.send(null);
          return;
        }

        try {
          final text = msg['text'] as String;
          final sid = msg['sid'] as int;
          final speed = msg['speed'] as double;

          final audio = tts!.generate(text: text, sid: sid, speed: speed);
          reply!.send(_floatToPcm(audio.samples));
        } catch (e) {
          debugPrint('[TTS ERROR] 生成失败：$e');
          reply?.send(null);
        }
        break;

      case 'dispose':
        tts?.free();
        tts = null;
        port.close();
        break;
    }
  });
}

Future<String> _getModelsDir() async {
  final dir = await getApplicationSupportDirectory();
  final modelsDir = Directory('${dir.path}/models/tts');

  if (!await modelsDir.exists()) {
    await modelsDir.create(recursive: true);

    // 复制模型文件
    await _copyAsset(
      'assets/models/tts/vits-zh-hf-fanchen-C.onnx',
      modelsDir.path,
    );
    await _copyAsset('assets/models/tts/tokens.txt', modelsDir.path);
    await _copyAsset('assets/models/tts/lexicon.txt', modelsDir.path);
  }

  return modelsDir.path;
}

String _getModelsDirSync() {
  final appDir = Directory.systemTemp.path; // 使用系统临时目录作为fallback
  final modelsDir = Directory('$appDir/bipupu/models/tts');

  if (!modelsDir.existsSync()) {
    modelsDir.createSync(recursive: true);
  }

  return modelsDir.path;
}

Future<void> _copyAsset(String assetPath, String destDir) async {
  final fileName = assetPath.split('/').last;
  final dest = File('$destDir/$fileName');

  if (!await dest.exists()) {
    final data = await rootBundle.load(assetPath);
    await dest.create(recursive: true);
    await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }
}

Uint8List _floatToPcm(Float32List samples) {
  final bytes = Uint8List(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final pcm = (samples[i] * 32767).toInt().clamp(-32768, 32767);
    bytes[i * 2] = pcm & 0xFF;
    bytes[i * 2 + 1] = (pcm >> 8) & 0xFF;
  }
  return bytes;
}
