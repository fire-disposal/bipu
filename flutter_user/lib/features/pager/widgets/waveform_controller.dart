import 'dart:async';
import 'package:flutter/foundation.dart';

/// 轻量级波形控制器，监听音频样本流并通过ValueListenable暴露滚动振幅缓冲区
class WaveformController extends ChangeNotifier {
  StreamSubscription<double>? _sub;

  // 归一化振幅值的滚动缓冲区 [0..1]
  final List<double> amplitudes = [];
  final int maxPoints;

  WaveformController({this.maxPoints = 200});

  /// 开始监听音频流
  void start() {
    if (_sub != null) return;

    // 从语音命令中心获取音量流（暂时注释）
    // _sub = _assistant.voiceCommandCenter.onVolume.listen((v) {
    //   // 处理音量数据
    // }, onError: (_) {});
  }

  /// 停止监听音频流
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// 是否正在运行
  bool get isRunning => _sub != null;

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  /// 获取当前振幅值（最近的值）
  double get currentAmplitude => amplitudes.isNotEmpty ? amplitudes.last : 0.0;

  /// 获取振幅值的平均值
  double get averageAmplitude {
    if (amplitudes.isEmpty) return 0.0;
    final sum = amplitudes.reduce((a, b) => a + b);
    return sum / amplitudes.length;
  }

  /// 获取振幅值的最大值
  double get maxAmplitude {
    if (amplitudes.isEmpty) return 0.0;
    return amplitudes.reduce((a, b) => a > b ? a : b);
  }

  /// 清空振幅缓冲区
  void clear() {
    amplitudes.clear();
    notifyListeners();
  }

  /// 获取振幅值的归一化列表（用于绘制波形）
  List<double> get normalizedAmplitudes {
    if (amplitudes.isEmpty) return [];

    final maxVal = maxAmplitude;
    if (maxVal == 0.0) return List.filled(amplitudes.length, 0.0);

    return amplitudes.map((a) => a / maxVal).toList();
  }
}
