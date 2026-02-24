import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:async';

/// 动态声纹视图
///
/// 使用 CustomPainter 绘制动态波形，模拟语音输入时的声纹效果
class WaveformView extends HookWidget {
  /// 波形条数
  final int barCount;

  /// 波形颜色
  final Color? color;

  /// 是否正在动画
  final bool isAnimating;

  /// 动画速度（毫秒）
  final int animationSpeed;

  /// 波形高度比例（0.0 - 1.0）
  final double amplitudeScale;

  const WaveformView({
    super.key,
    this.barCount = 20,
    this.color,
    this.isAnimating = true,
    this.animationSpeed = 100,
    this.amplitudeScale = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waveformColor = color ?? theme.colorScheme.primary;

    // 使用useState管理波形数据
    final waveformData = useState<List<double>>(
      List.generate(barCount, (_) => 0.5),
    );

    // 使用useEffect管理动画
    useEffect(() {
      if (!isAnimating) return null;

      Timer? timer;

      void updateWaveform() {
        // 生成新的波形数据
        final newWaveform = List.generate(
          barCount,
          (_) => 0.2 + Random().nextDouble() * 0.6,
        );

        waveformData.value = newWaveform;
      }

      // 启动定时器
      timer = Timer.periodic(
        Duration(milliseconds: animationSpeed),
        (_) => updateWaveform(),
      );

      // 立即更新一次
      updateWaveform();

      // 清理函数
      return () {
        timer?.cancel();
      };
    }, [isAnimating, barCount, animationSpeed]);

    return CustomPaint(
      painter: WaveformPainter(
        amplitudes: waveformData.value,
        color: waveformColor,
        amplitudeScale: amplitudeScale,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// 波形绘制器
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final double amplitudeScale;
  final double strokeWidth;

  WaveformPainter({
    required this.amplitudes,
    required this.color,
    this.amplitudeScale = 0.8,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final barWidth = size.width / amplitudes.length;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * amplitudeScale;

    for (int i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i];
      // 确保振幅在有效范围内
      final clampedAmplitude = amplitude.clamp(0.0, 1.0);
      final barHeight = clampedAmplitude * maxBarHeight;
      final x = i * barWidth + barWidth / 2;

      // 绘制垂直线段
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.color != color ||
        oldDelegate.amplitudeScale != amplitudeScale ||
        oldDelegate.strokeWidth != strokeWidth;
  }

  @override
  bool shouldRebuildSemantics(WaveformPainter oldDelegate) => false;
}
