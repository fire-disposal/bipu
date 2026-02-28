import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'model_manager.dart';
import 'voice_config.dart';
import '../utils/logger.dart';

class ASREngine {
  ASREngine._internal();
  static final ASREngine _instance = ASREngine._internal();
  factory ASREngine() => _instance;

  sherpa.OnlineRecognizer? _recognizer;
  sherpa.OnlineStream? _stream;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  final RecorderStream _recorder = RecorderStream();
  StreamSubscription? _recorderSub;

  final StreamController<String> _resultController =
      StreamController.broadcast();
  Stream<String> get onResult => _resultController.stream;

  final StreamController<double> _volumeController =
      StreamController.broadcast();
  Stream<double> get onVolume => _volumeController.stream;

  final StreamController<Uint8List> _audioController =
      StreamController.broadcast();
  Stream<Uint8List> get onAudio => _audioController.stream;

  bool get isInitialized => _isInitialized;

  // 计数器变量
  int _volumeCounter = 0;
  int _convertCounter = 0;

  // 防重复调用保护
  bool _isStopping = false;
  bool _isDisposing = false;

  Future<void> init() async {
    logger.i('🚀 ASREngine: 开始初始化...');
    logger.i('📋 ASR模型配置:');
    logger.i('   - 模型文件数量: ${VoiceConfig.asrModelFiles.length}');
    logger.i('   - 采样率: ${VoiceConfig.asrSampleRate} Hz');
    logger.i('   - 特征维度: ${VoiceConfig.asrFeatureDim}');
    logger.i('   - 线程数: ${VoiceConfig.asrNumThreads}');

    if (_isInitialized) {
      logger.i('✅ ASREngine: 已经初始化，跳过');
      return;
    }

    if (_initCompleter != null) {
      logger.i('⏳ ASREngine: 正在初始化中，等待完成...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    logger.i('🔄 ASREngine: 创建初始化Completer');

    try {
      logger.i('🔧 ASREngine: 初始化Sherpa绑定...');
      sherpa.initBindings();
      logger.i('✅ ASREngine: Sherpa绑定初始化成功');

      logger.i('📦 ASREngine: 初始化模型管理器...');
      logger.i('📋 需要加载的ASR模型文件: ${VoiceConfig.asrModelFiles.length} 个');
      VoiceConfig.asrModelFiles.forEach((key, value) {
        logger.i('   - $key -> $value');
      });

      logger.i('🔄 ASREngine: 调用ModelManager.ensureInitialized...');
      await ModelManager.instance.ensureInitialized(VoiceConfig.asrModelFiles);
      logger.i('✅ ASREngine: 模型管理器调用完成');

      // 打印模型管理器当前状态
      logger.i('🔍 ASREngine: 检查模型管理器状态...');
      ModelManager.instance.printStatus();

      final modelPaths = <String, String>{};
      logger.i('🔍 ASREngine: 获取模型路径...');

      for (final key in VoiceConfig.asrModelFiles.keys) {
        logger.i('   🔍 获取模型路径: $key');
        final p = ModelManager.instance.getModelPath(key);
        if (p == null) {
          logger.e('❌ ASREngine: 模型管理器未能准备文件 $key');
          logger.e('   📋 当前可用模型keys:');
          ModelManager.instance.getStatus()['models'].keys.forEach((k) {
            logger.e('     - $k');
          });
          throw Exception(
            'ModelManager failed to prepare $key - 请检查assets目录中是否存在此文件',
          );
        }
        final fileName = key.split('/').last;
        modelPaths[fileName] = p;
        logger.i('   ✅ $fileName -> $p');
      }

      logger.i('🔧 ASREngine: 构建识别器配置...');
      logger.i('   📊 配置参数:');
      logger.i('     - 采样率: ${VoiceConfig.asrSampleRate}');
      logger.i('     - 特征维度: ${VoiceConfig.asrFeatureDim}');
      logger.i('     - 线程数: ${VoiceConfig.asrNumThreads}');
      logger.i('     - 提供者: ${VoiceConfig.asrProvider}');
      logger.i('     - 模型类型: ${VoiceConfig.asrModelType}');
      logger.i('     - 启用端点检测: ${VoiceConfig.asrEnableEndpoint}');

      logger.i('   📁 模型文件:');
      logger.i('     - 编码器: ${modelPaths[VoiceConfig.asrEncoder]}');
      logger.i('     - 解码器: ${modelPaths[VoiceConfig.asrDecoder]}');
      logger.i('     - 连接器: ${modelPaths[VoiceConfig.asrJoiner]}');
      logger.i('     - 令牌文件: ${modelPaths[VoiceConfig.asrTokens]}');

      final config = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: modelPaths[VoiceConfig.asrEncoder]!,
            decoder: modelPaths[VoiceConfig.asrDecoder]!,
            joiner: modelPaths[VoiceConfig.asrJoiner]!,
          ),
          tokens: modelPaths[VoiceConfig.asrTokens]!,
          numThreads: VoiceConfig.asrNumThreads,
          provider: VoiceConfig.asrProvider,
          debug: VoiceConfig.asrDebug,
          modelType: VoiceConfig.asrModelType,
        ),
        feat: sherpa.FeatureConfig(
          sampleRate: VoiceConfig.asrSampleRate,
          featureDim: VoiceConfig.asrFeatureDim,
        ),
        enableEndpoint: VoiceConfig.asrEnableEndpoint,
      );

      logger.i('🔧 ASREngine: 创建在线识别器...');
      _recognizer = sherpa.OnlineRecognizer(config);
      _isInitialized = true;

      logger.i('🎉 ASREngine: 初始化成功!');
      logger.i('📊 ASREngine: 初始化统计:');
      logger.i('   - 加载模型数量: ${modelPaths.length}');
      logger.i('   - 识别器类型: ${VoiceConfig.asrModelType}');
      logger.i('   - 端点检测: ${VoiceConfig.asrEnableEndpoint ? "启用" : "禁用"}');

      _initCompleter!.complete();
      logger.i('✅ ASREngine: 初始化Completer完成');
    } catch (e, stackTrace) {
      logger.e('❌ ASREngine: 初始化失败!');
      logger.e('   🔴 错误类型: ${e.runtimeType}');
      logger.e('   🔴 错误信息: $e');
      logger.e('   📄 堆栈跟踪:');
      logger.e('$stackTrace');
      logger.e('   🔧 调试建议:');
      logger.e('     1. 检查assets/models/asr/目录下是否存在所有模型文件');
      logger.e('     2. 检查pubspec.yaml中是否正确配置了assets');
      logger.e('     3. 检查模型文件名称和路径是否正确');

      _initCompleter!.completeError(e, stackTrace);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> startRecording() async {
    logger.i('🎤 ASREngine: 开始录音...');

    logger.i('🔍 ASREngine: 请求麦克风权限...');
    final status = await Permission.microphone.request();
    logger.i('📋 ASREngine: 麦克风权限状态: $status');

    if (status.isDenied) {
      logger.e('❌ ASREngine: 麦克风权限被拒绝');
      throw Exception('Microphone denied');
    }

    if (!_isInitialized) {
      logger.i('🔄 ASREngine: 引擎未初始化，开始初始化...');
      await init();
    } else {
      logger.i('✅ ASREngine: 引擎已初始化');
    }

    logger.i('🔧 ASREngine: 创建音频流...');
    _stream = _recognizer!.createStream();
    logger.i('✅ ASREngine: 音频流创建成功');

    logger.i('🔧 ASREngine: 初始化录音器...');
    await _recorder.initialize();
    logger.i('✅ ASREngine: 录音器初始化成功');

    logger.i('🔧 ASREngine: 设置音频流监听...');
    _recorderSub = _recorder.audioStream.listen(
      (data) {
        try {
          logger.v('🎵 ASREngine: 收到音频数据，大小: ${data.length} 字节');

          // 将音频数据发送给订阅者（用于波形处理）
          _audioController.add(data);

          final floatSamples = _convertBytesToFloat(data);
          logger.v('   🔢 转换后样本数: ${floatSamples.length}');

          if (_stream != null) {
            logger.v('   📤 发送波形到识别器...');
            _stream!.acceptWaveform(samples: floatSamples, sampleRate: 16000);

            while (_recognizer!.isReady(_stream!)) {
              logger.v('   🔍 识别器就绪，开始解码...');
              _recognizer!.decode(_stream!);
            }

            final isEndpoint = _recognizer!.isEndpoint(_stream!);
            if (isEndpoint) {
              logger.i('   🎯 检测到端点，获取识别结果...');
              final text = _recognizer!.getResult(_stream!).text;
              logger.i('   📝 识别结果: "$text"');
              _resultController.add(text);
            }
          }

          _emitVolume(floatSamples);
        } catch (e) {
          logger.e('❌ ASREngine: 处理音频缓冲区错误: $e');
        }
      },
      onError: (e) {
        logger.e('❌ ASREngine: 音频流错误: $e');
      },
    );

    logger.i('▶️  ASREngine: 开始录音...');
    await _recorder.start();
    logger.i('✅ ASREngine: 录音已开始');
  }

  Future<String> stop() async {
    logger.i('⏹️  ASREngine: 停止录音...');

    // 防重复调用检查
    if (_isStopping) {
      logger.w('⚠️  ASREngine: 已经在停止过程中，跳过重复调用');
      return '';
    }

    // 检查是否已经初始化
    if (!_isInitialized) {
      logger.w('⚠️  ASREngine: 引擎未初始化，无需停止');
      return '';
    }

    // 检查是否正在录音
    if (_recorderSub == null) {
      logger.w('⚠️  ASREngine: 未在录音状态，无需停止');
      return '';
    }

    _isStopping = true;

    try {
      logger.i('🛑 ASREngine: 停止录音器...');
      await _recorder.stop();
      logger.i('✅ ASREngine: 录音器已停止');
    } catch (e) {
      logger.w('⚠️  ASREngine: 停止录音器时出错: $e');
    }

    logger.i('🔌 ASREngine: 取消音频流订阅...');
    await _recorderSub?.cancel();
    _recorderSub = null;
    logger.i('✅ ASREngine: 音频流订阅已取消');

    String resultText = '';

    try {
      if (_stream != null && _recognizer != null) {
        logger.i('🔍 ASREngine: 执行最终解码...');
        try {
          _recognizer!.decode(_stream!);
        } catch (e) {
          logger.w('⚠️  ASREngine: 最终解码时出错: $e');
          // 继续执行，不中断流程
        }

        logger.i('📝 ASREngine: 获取最终识别结果...');
        try {
          final result = _recognizer!.getResult(_stream!);
          resultText = result.text;
          logger.i('   📄 识别结果: "$resultText"');
        } catch (e) {
          logger.w('⚠️  ASREngine: 获取识别结果时出错: $e');
          resultText = '';
        }

        logger.i('🗑️  ASREngine: 释放音频流...');
        try {
          _stream!.free();
        } catch (e) {
          logger.w('⚠️  ASREngine: 释放音频流时出错: $e');
        }
        _stream = null;
        logger.i('✅ ASREngine: 音频流已释放');
      } else {
        if (_stream == null) {
          logger.w('⚠️  ASREngine: 音频流为空');
        }
        if (_recognizer == null) {
          logger.w('⚠️  ASREngine: 识别器为空');
        }
      }
    } catch (e, stackTrace) {
      logger.e('❌ ASREngine: stop()方法出现未预期错误');
      logger.e('   🔴 错误: $e');
      logger.e('   📄 堆栈: $stackTrace');
    } finally {
      _isStopping = false;
    }

    return resultText;
  }

  void _emitVolume(Float32List samples) {
    if (samples.isEmpty) {
      _volumeController.add(0.0);
      return;
    }

    double sum = 0.0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    final rms = math.sqrt(sum / samples.length);
    final clampedRms = rms.clamp(0.0, 1.0);

    // 每10次打印一次音量信息，避免过于频繁
    _volumeCounter++;
    if (_volumeCounter % 10 == 0) {
      logger.v(
        '🔊 ASREngine: 音量 RMS = ${clampedRms.toStringAsFixed(4)} (原始: ${rms.toStringAsFixed(4)})',
      );
    }

    _volumeController.add(clampedRms);
  }

  Float32List _convertBytesToFloat(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) {
      logger.w('⚠️  ASREngine: 音频数据为空，返回空Float32List');
      return Float32List(0);
    }

    logger.v('   🔢 ASREngine: 转换音频数据: ${bytes.length} 字节 -> $sampleCount 个样本');

    final byteData = ByteData.sublistView(bytes);
    final out = Float32List(sampleCount);

    double minVal = double.infinity;
    double maxVal = -double.infinity;
    double sum = 0.0;

    for (var i = 0; i < sampleCount; i++) {
      final val = byteData.getInt16(i * 2, Endian.little);
      final floatVal = val / 32768.0;
      out[i] = floatVal;

      // 统计信息
      if (floatVal < minVal) minVal = floatVal;
      if (floatVal > maxVal) maxVal = floatVal;
      sum += floatVal.abs();
    }

    final avg = sum / sampleCount;

    // 每10次转换打印一次统计信息
    _convertCounter++;
    if (_convertCounter % 10 == 0) {
      logger.v(
        '   📊 ASREngine: 音频统计 - 样本数: $sampleCount, 最小值: ${minVal.toStringAsFixed(4)}, 最大值: ${maxVal.toStringAsFixed(4)}, 平均绝对值: ${avg.toStringAsFixed(4)}',
      );
    }

    return out;
  }

  void dispose() {
    logger.i('🗑️  ASREngine: 开始销毁...');

    // 防重复调用检查
    if (_isDisposing) {
      logger.w('⚠️  ASREngine: 已经在销毁过程中，跳过重复调用');
      return;
    }
    _isDisposing = true;

    // 首先停止录音（如果正在录音）
    if (_recorderSub != null) {
      logger.i('🛑 ASREngine: 正在停止录音...');
      try {
        _recorder.stop();
      } catch (e) {
        logger.w('⚠️  ASREngine: 停止录音器时出错: $e');
      }
    }

    logger.i('🔌 ASREngine: 取消录音器订阅...');
    try {
      _recorderSub?.cancel();
      _recorderSub = null;
    } catch (e) {
      logger.w('⚠️  ASREngine: 取消录音器订阅时出错: $e');
    }

    // 清理音频流
    try {
      if (_stream != null) {
        logger.i('🗑️  ASREngine: 释放音频流...');
        try {
          _stream!.free();
        } catch (e) {
          logger.w('⚠️  ASREngine: 释放音频流时出错: $e');
        }
        _stream = null;
      } else {
        logger.i('✅ ASREngine: 音频流已为空');
      }
    } catch (e) {
      logger.w('⚠️  ASREngine: 处理音频流时出错: $e');
    }

    // 清理识别器
    try {
      if (_recognizer != null) {
        logger.i('🗑️  ASREngine: 释放识别器...');
        try {
          _recognizer!.free();
        } catch (e) {
          logger.w('⚠️  ASREngine: 释放识别器时出错: $e');
        }
        _recognizer = null;
      } else {
        logger.i('✅ ASREngine: 识别器已为空');
      }
    } catch (e) {
      logger.w('⚠️  ASREngine: 处理识别器时出错: $e');
    }

    // 重置状态
    _isInitialized = false;
    _initCompleter = null;
    _volumeCounter = 0;
    _convertCounter = 0;

    // 关闭结果控制器
    try {
      logger.i('🔌 ASREngine: 关闭结果控制器...');
      if (!_resultController.isClosed) {
        _resultController.close();
      }
    } catch (e) {
      logger.w('⚠️  ASREngine: 关闭结果控制器时出错: $e');
    }

    // 关闭音量控制器
    try {
      logger.i('🔌 ASREngine: 关闭音量控制器...');
      if (!_volumeController.isClosed) {
        _volumeController.close();
      }
    } catch (e) {
      logger.w('⚠️  ASREngine: 关闭音量控制器时出错: $e');
    }

    logger.i('✅ ASREngine: 销毁完成');
    _isDisposing = false;
  }
}
