import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 实时声纹动效组件
/// 使用CustomPainter绘制声波动画，模拟接线员说话或收音
class WaveformAnimationWidget extends StatefulWidget {
  final bool isActive; // 是否激活动画
  final Color waveColor;
  final Color backgroundColor;
  final double height;
  final Duration animationDuration;

  const WaveformAnimationWidget({
    super.key,
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

/// 声纹绘制器（纯程序动画，无需外部数据）
///
/// 使用双频正弦叠加 + 正弦包络塑形，产生有机感的波形动效。
/// isActive=false 时显示静态低幅条，isActive=true 时全幅动画。
class WaveformPainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;
  final Color backgroundColor;

  const WaveformPainter({
    required this.animationValue,
    required this.waveColor,
    this.backgroundColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor != Colors.transparent) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );
    }

    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    const barCount = 18;
    final barWidth = size.width / (barCount + 1);
    final centerY = size.height / 2;
    final phase = animationValue * 2 * math.pi;

    for (int i = 0; i < barCount; i++) {
      final x = (i + 1) * barWidth;
      final pos = i / (barCount - 1); // 0.0 ~ 1.0

      // 双频叠加：主频 + 谐波，产生有机感
      final wave1 = math.sin(phase + i * (2 * math.pi / barCount));
      final wave2 = 0.35 * math.sin(phase * 2.3 + i * 0.8);
      final combined = ((wave1 + wave2) / 1.35).clamp(-1.0, 1.0);

      // 正弦包络：两端低、中间高，边缘自然收缩
      final envelope = math.sin(pos * math.pi);
      final baseH = size.height * (0.15 + 0.55 * envelope);
      final barH = math.max(2.0, baseH * (0.5 + 0.5 * (combined * 0.5 + 0.5)));

      final barW = math.max(1.5, barWidth * 0.55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, centerY),
            width: barW,
            height: barH,
          ),
          Radius.circular(barW * 0.4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.animationValue != animationValue || old.waveColor != waveColor;
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
