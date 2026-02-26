import 'package:flutter/material.dart';
import 'waveform_controller.dart';

class WaveformPainter extends CustomPainter {
  final WaveformController controller;
  final Color color;
  WaveformPainter(this.controller, {this.color = Colors.blue})
    : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.5), color],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final centerY = size.height / 2;
    final points = controller.amplitudes;
    if (points.isEmpty) return;

    final path = Path();
    final step = size.width / (points.length - 1).clamp(1, double.infinity);
    for (var i = 0; i < points.length; i++) {
      final x = i * step;
      final h = points[i] * size.height * 0.8; // scale
      final y = centerY - h / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => false;
}
