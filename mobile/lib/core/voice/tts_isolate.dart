import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

// ─────────────────────────────────────────────────────────────────────────────
//  TTS 后台 Isolate 管理器
//
//  将 sherpa.OfflineTts 的同步 ONNX 推理（FFI）完全移入独立 Dart Isolate。
//  主线程通过 SendPort/ReceivePort 消息传递异步获取 PCM bytes，
//  Flutter 渲染管线（UI 帧）不再被 ONNX 推理阻塞。
//
//  生命周期：
//    TtsIsolateRunner.spawn()  → 启动 Isolate + 初始化模型
//    TtsIsolateRunner.generate() → 异步生成，返回 Uint8List PCM bytes
//    TtsIsolateRunner.dispose()  → 通知 Isolate 释放 native 资源后退出
// ─────────────────────────────────────────────────────────────────────────────

/// TTS 后台 Isolate 管理器（由 TTSEngine 持有）
class TtsIsolateRunner {
  Isolate? _isolate;
  SendPort? _sendPort;

  bool get isReady => _sendPort != null;

  /// 启动后台 Isolate 并完成 sherpa.OfflineTts 模型初始化。
  ///
  /// [modelPaths] 预提取的绝对文件系统路径（key 见下方说明）：
  ///   'onnx'      → VITS .onnx 模型文件
  ///   'tokens'    → tokens.txt
  ///   'lexicon'   → lexicon.txt
  ///   'phone'     → phone.fst
  ///   'date'      → date.fst
  ///   'number'    → number.fst
  ///   'heteronym' → new_heteronym.fst
  Future<void> spawn({
    required Map<String, String> modelPaths,
    required int numThreads,
    required bool debug,
  }) async {
    if (isReady) return;

    // ① 启动 Isolate，拿到它的 SendPort
    final setupPort = ReceivePort();
    _isolate = await Isolate.spawn(
      _ttsIsolateEntryPoint,
      setupPort.sendPort,
      debugName: 'TTS-Worker',
      errorsAreFatal: false, // Isolate 内部异常不杀死主 Isolate
    );
    _sendPort = await setupPort.first as SendPort;
    setupPort.close();

    // ② 发送初始化配置，等待就绪信号
    final initReply = ReceivePort();
    _sendPort!.send({
      'type': 'init',
      'paths': modelPaths,
      'numThreads': numThreads,
      'debug': debug,
      'replyPort': initReply.sendPort,
    });
    final reply = await initReply.first;
    initReply.close();

    if (reply is! Map || reply['success'] != true) {
      final err = reply is Map ? reply['error'] : 'unknown';
      _sendPort = null;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      throw Exception('TTS Isolate 初始化失败: $err');
    }
  }

  /// 在后台 Isolate 生成音频，返回 16-bit little-endian PCM bytes（24 kHz 单声道）。
  ///
  /// 多次并发调用时会在 Isolate 内部队列化顺序执行。
  /// 超时或生成失败时返回 null。
  Future<Uint8List?> generate({
    required String text,
    required int sid,
    required double speed,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isReady) return null;

    final replyPort = ReceivePort();
    _sendPort!.send({
      'type': 'generate',
      'text': text,
      'sid': sid,
      'speed': speed,
      'replyPort': replyPort.sendPort,
    });

    try {
      final result = await replyPort.first.timeout(timeout);
      replyPort.close();
      return result as Uint8List?;
    } on TimeoutException {
      replyPort.close();
      return null;
    } catch (_) {
      replyPort.close();
      return null;
    }
  }

  /// 通知后台 Isolate 释放 native 资源后自然退出。
  void dispose() {
    _sendPort?.send({'type': 'dispose'});
    // 稍后强杀（给 dispose 消息留出处理时间）
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _isolate?.kill(priority: Isolate.immediate);
    });
    _sendPort = null;
    _isolate = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  以下函数运行在后台 Isolate 中（必须是顶层函数 / static 方法）
// ─────────────────────────────────────────────────────────────────────────────

/// TTS Isolate 入口（顶层函数，不能是实例方法）
void _ttsIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  // 把自己的 SendPort 发回主线程
  mainSendPort.send(receivePort.sendPort);

  sherpa.OfflineTts? tts;

  receivePort.listen((message) {
    if (message is! Map) return;
    final type = message['type'] as String?;
    final replyPort = message['replyPort'] as SendPort?;

    switch (type) {
      case 'init':
        try {
          sherpa.initBindings();
          final paths = Map<String, String>.from(message['paths'] as Map);
          final numThreads = message['numThreads'] as int;
          final debug = message['debug'] as bool;
          tts = sherpa.OfflineTts(
            _buildTtsConfigInIsolate(paths, numThreads, debug),
          );
          replyPort?.send({'success': true});
        } catch (e) {
          replyPort?.send({'success': false, 'error': e.toString()});
        }

      case 'generate':
        if (tts == null || replyPort == null) {
          replyPort?.send(null);
          return;
        }
        try {
          final text = message['text'] as String;
          final sid = message['sid'] as int;
          final speed = message['speed'] as double;
          // 同步 ONNX 推理 —— 在后台 Isolate 中执行，不阻塞主线程
          final audio = tts!.generate(text: text, sid: sid, speed: speed);
          // PCM 转换也在此 Isolate 中完成，主线程拿到已就绪的 Uint8List
          replyPort.send(_floatSamplesToPcmBytes(audio.samples));
        } catch (_) {
          replyPort.send(null);
        }

      case 'dispose':
        tts?.free();
        tts = null;
        receivePort.close(); // 关闭后 Isolate 自然退出
    }
  });
}

/// Float32 样本 → 16-bit little-endian PCM Uint8List
Uint8List _floatSamplesToPcmBytes(Float32List samples) {
  final bytes = Uint8List(samples.length * 2);
  for (int i = 0; i < samples.length; i++) {
    final pcm = (samples[i] * 32767).toInt().clamp(-32768, 32767);
    bytes[i * 2] = pcm & 0xFF;
    bytes[i * 2 + 1] = (pcm >> 8) & 0xFF;
  }
  return bytes;
}

/// 在 Isolate 内构建 sherpa TTS 配置
sherpa.OfflineTtsConfig _buildTtsConfigInIsolate(
  Map<String, String> paths,
  int numThreads,
  bool debug,
) {
  final onnx = paths['onnx'];
  final lexicon = paths['lexicon'];
  final tokens = paths['tokens'];
  if (onnx == null || lexicon == null || tokens == null) {
    throw Exception('TTS Isolate: 缺少必要模型路径 (onnx/lexicon/tokens)');
  }

  final vits = sherpa.OfflineTtsVitsModelConfig(
    model: onnx,
    lexicon: lexicon,
    tokens: tokens,
  );

  // 将存在的 FST rule 文件拼接为逗号分隔字符串
  final ruleFsts = [
    'phone',
    'date',
    'number',
    'heteronym',
  ].map((k) => paths[k]).where((p) => p != null && p.isNotEmpty).join(',');

  return sherpa.OfflineTtsConfig(
    model: sherpa.OfflineTtsModelConfig(
      vits: vits,
      numThreads: numThreads,
      debug: debug,
    ),
    ruleFsts: ruleFsts,
  );
}
