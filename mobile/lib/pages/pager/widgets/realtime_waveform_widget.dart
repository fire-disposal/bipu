import 'package:flutter/material.dart';

/// 实时录音波形动画组件
/// 显示录音时的动态波形效果
class RealtimeWaveformWidget extends StatelessWidget {
  final List<double> amplitudes;
  final Color waveColor;
  final double height;
  final bool isRecording;

  const RealtimeWaveformWidget({
    super.key,
    required this.amplitudes,
    required this.isRecording,
    this.waveColor = Colors.blue,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: _RealtimeWaveformPainter(
          amplitudes: amplitudes,
          waveColor: waveColor,
          isRecording: isRecording,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RealtimeWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color waveColor;
  final bool isRecording;

  _RealtimeWaveformPainter({
    required this.amplitudes,
    required this.waveColor,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      _drawIdleState(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final barWidth = size.width / 40; // 显示40个柱状条
    final spacing = barWidth * 0.3;
    final actualBarWidth = barWidth - spacing;

    // 计算要显示的振幅数据范围
    final startIndex = amplitudes.length > 40 
        ? amplitudes.length - 40 
        : 0;
    final displayAmplitudes = amplitudes.sublist(startIndex);

    for (int i = 0; i < displayAmplitudes.length; i++) {
      final amplitude = displayAmplitudes[i].clamp(0.0, 1.0);
      final x = i * barWidth + barWidth / 2;
      
      // 计算柱状条高度（最小高度为4，最大为centerY）
      final barHeight = 4 + amplitude * (centerY - 4);
      
      // 绘制对称的上下柱状条
      final path = Path();
      
      // 上半部分
      path.moveTo(x - actualBarWidth / 2, centerY - barHeight);
      path.lineTo(x + actualBarWidth / 2, centerY - barHeight);
      path.lineTo(x + actualBarWidth / 2, centerY);
      path.lineTo(x - actualBarWidth / 2, centerY);
      path.close();
      
      // 下半部分
      path.moveTo(x - actualBarWidth / 2, centerY + barHeight);
      path.lineTo(x + actualBarWidth / 2, centerY + barHeight);
      path.lineTo(x + actualBarWidth / 2, centerY);
      path.lineTo(x - actualBarWidth / 2, centerY);
      path.close();
      
      // 根据时间衰减透明度（越新的数据越亮）
      final opacity = 0.3 + (i / displayAmplitudes.length) * 0.7;
      paint.color = waveColor.withValues(alpha: opacity);
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawIdleState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    
    // 绘制一条水平线表示空闲状态
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // 绘制几个小点表示等待
    final dotPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(centerX + i * 20, centerY),
        3,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RealtimeWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.waveColor != waveColor;
  }
}

/// 简化版实时波形条组件
/// 用于显示在录音按钮附近的小波形
class MiniWaveformWidget extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;
  final double width;
  final double height;

  const MiniWaveformWidget({
    super.key,
    required this.amplitudes,
    required this.color,
    this.width = 120,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MiniWaveformPainter(
          amplitudes: amplitudes,
          color: color,
        ),
      ),
    );
  }
}

class _MiniWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _MiniWaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = size.width / 20;

    final startIndex = amplitudes.length > 20 ? amplitudes.length - 20 : 0;
    final displayData = amplitudes.sublist(startIndex);

    for (int i = 0; i < displayData.length; i++) {
      final amplitude = displayData[i].clamp(0.0, 1.0);
      final x = i * barWidth + barWidth / 2;
      final barHeight = amplitude * centerY;

      paint.color = color.withValues(alpha: 0.3 + i / displayData.length * 0.7);
      
      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes || oldDelegate.color != color;
  }
}
