import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 实时声纹动效组件
/// 使用CustomPainter绘制声波动画，模拟接线员说话或收音
class WaveformAnimationWidget extends StatefulWidget {
  final List<double> waveformData; // 声纹数据 (0-1范围)
  final bool isActive; // 是否激活动画
  final Color waveColor;
  final Color backgroundColor;
  final double height;
  final Duration animationDuration;

  const WaveformAnimationWidget({
    super.key,
    this.waveformData = const [],
    this.isActive = false,
    this.waveColor = Colors.blue,
    this.backgroundColor = Colors.transparent,
    this.height = 120,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<WaveformAnimationWidget> createState() =>
      _WaveformAnimationWidgetState();
}

class _WaveformAnimationWidgetState extends State<WaveformAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    if (widget.isActive) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: WaveformPainter(
            waveformData: widget.waveformData,
            animationValue: _animationController.value,
            waveColor: widget.waveColor,
            backgroundColor: widget.backgroundColor,
          ),
          size: Size(double.infinity, widget.height),
        );
      },
    );
  }
}

/// 声纹绘制器
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double animationValue;
  final Color waveColor;
  final Color backgroundColor;

  WaveformPainter({
    required this.waveformData,
    required this.animationValue,
    required this.waveColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    if (backgroundColor != Colors.transparent) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );
    }

    // 绘制声纹
    _drawWaveform(canvas, size);
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final barWidth = size.width / (waveformData.length + 1);

    // 如果没有数据，绘制默认动画
    if (waveformData.isEmpty) {
      _drawDefaultWaveform(canvas, size, paint, centerY);
      return;
    }

    // 绘制每个声纹柱
    for (int i = 0; i < waveformData.length; i++) {
      final x = (i + 1) * barWidth;
      final baseHeight = waveformData[i] * size.height * 0.8;

      // 添加动画效果
      final animatedHeight =
          baseHeight *
          (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi + i * 0.3));

      // 绘制柱子
      final rect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: barWidth * 0.6,
        height: animatedHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth * 0.3)),
        paint,
      );
    }
  }

  /// 绘制默认动画（无数据时）
  void _drawDefaultWaveform(
    Canvas canvas,
    Size size,
    Paint paint,
    double centerY,
  ) {
    const barCount = 16;
    final barWidth = size.width / (barCount + 1);

    for (int i = 0; i < barCount; i++) {
      final x = (i + 1) * barWidth;

      // 创建波形效果
      final phase = animationValue * 2 * math.pi;
      final baseHeight = size.height * 0.3;
      final amplitude = size.height * 0.2;

      final height =
          baseHeight +
          amplitude * math.sin(phase + i * (2 * math.pi / barCount));

      final rect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: barWidth * 0.6,
        height: height.abs(),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth * 0.3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveformData != waveformData ||
        oldDelegate.waveColor != waveColor;
  }
}

/// 圆形脉冲动效组件
/// 用于表示正在录音或播放
class PulseAnimationWidget extends StatefulWidget {
  final bool isActive;
  final Color pulseColor;
  final double size;
  final Duration duration;

  const PulseAnimationWidget({
    super.key,
    this.isActive = false,
    this.pulseColor = Colors.blue,
    this.size = 80,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseAnimationWidget> createState() => _PulseAnimationWidgetState();
}

class _PulseAnimationWidgetState extends State<PulseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.isActive) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外层脉冲
            Container(
              width: widget.size * (1 + 0.5 * _animationController.value),
              height: widget.size * (1 + 0.5 * _animationController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.pulseColor.withOpacity(
                    1.0 - _animationController.value,
                  ),
                  width: 2,
                ),
              ),
            ),

            // 中层脉冲
            Container(
              width: widget.size * (1 + 0.3 * _animationController.value),
              height: widget.size * (1 + 0.3 * _animationController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.pulseColor.withOpacity(
                    0.5 * (1.0 - _animationController.value),
                  ),
                  width: 1.5,
                ),
              ),
            ),

            // 中心圆
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.pulseColor,
              ),
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}

/// 频谱分析动效组件
/// 显示实时音频频谱
class SpectrumAnimationWidget extends StatefulWidget {
  final List<double> spectrumData; // 频谱数据
  final bool isActive;
  final Color spectrumColor;
  final double height;

  const SpectrumAnimationWidget({
    super.key,
    this.spectrumData = const [],
    this.isActive = false,
    this.spectrumColor = Colors.cyan,
    this.height = 100,
  });

  @override
  State<SpectrumAnimationWidget> createState() =>
      _SpectrumAnimationWidgetState();
}

class _SpectrumAnimationWidgetState extends State<SpectrumAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (widget.isActive) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SpectrumAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: SpectrumPainter(
            spectrumData: widget.spectrumData,
            spectrumColor: widget.spectrumColor,
            animationValue: _animationController.value,
          ),
          size: Size(double.infinity, widget.height),
        );
      },
    );
  }
}

/// 频谱绘制器
class SpectrumPainter extends CustomPainter {
  final List<double> spectrumData;
  final Color spectrumColor;
  final double animationValue;

  SpectrumPainter({
    required this.spectrumData,
    required this.spectrumColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = spectrumColor
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final barWidth = size.width / (spectrumData.length + 1);

    for (int i = 0; i < spectrumData.length; i++) {
      final x = (i + 1) * barWidth;
      final height = spectrumData[i] * size.height * 0.8;

      // 绘制上半部分
      canvas.drawRect(
        Rect.fromLTWH(
          x - barWidth * 0.3,
          centerY - height / 2,
          barWidth * 0.6,
          height / 2,
        ),
        paint,
      );

      // 绘制下半部分
      canvas.drawRect(
        Rect.fromLTWH(x - barWidth * 0.3, centerY, barWidth * 0.6, height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SpectrumPainter oldDelegate) {
    return oldDelegate.spectrumData != spectrumData ||
        oldDelegate.animationValue != animationValue;
  }
}
