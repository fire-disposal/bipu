import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'waveform_controller.dart';
import 'waveform_painter.dart';

class WaveformWidget extends StatefulWidget {
  final WaveformController controller;
  final double height;
  const WaveformWidget({
    required this.controller,
    this.height = 120,
    super.key,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: WaveformPainter(
          widget.controller,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Container(),
      ),
    );
  }
}

class StaticWaveform extends StatelessWidget {
  final String waveformBase64; // pcm16 little-endian
  final double height;
  final Color color;
  const StaticWaveform({
    required this.waveformBase64,
    this.height = 80,
    this.color = Colors.blue,
    super.key,
  });

  List<double> _decodeToAmplitudes(String b64) {
    final bytes = base64.decode(b64);
    final samples = <double>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final lo = bytes[i];
      final hi = bytes[i + 1];
      final int16 = (hi << 8) | lo;
      // adjust for signed
      final signed = int16 & 0x8000 != 0 ? int16 - 0x10000 : int16;
      samples.add(signed / 32768.0);
    }
    // downsample to ~200 points
    final step = (samples.length / 200).ceil().clamp(1, samples.length);
    final amps = <double>[];
    for (var i = 0; i < samples.length; i += step) {
      // compute RMS for chunk
      double sum = 0;
      final end = (i + step).clamp(0, samples.length);
      for (var j = i; j < end; j++) {
        sum += samples[j] * samples[j];
      }
      final mean = sum / (end - i);
      amps.add((mean <= 0) ? 0.0 : math.sqrt(mean));
    }
    return amps;
  }

  @override
  Widget build(BuildContext context) {
    // decode and create a simple painter
    final amps = _decodeToAmplitudes(waveformBase64);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _StaticPainter(amps, color),
        child: Container(),
      ),
    );
  }
}

class _StaticPainter extends CustomPainter {
  final List<double> amps;
  final Color color;
  _StaticPainter(this.amps, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;
    if (amps.isEmpty) return;
    final centerY = size.height / 2;
    final path = Path();
    final step = size.width / (amps.length - 1).clamp(1, double.infinity);
    for (var i = 0; i < amps.length; i++) {
      final x = i * step;
      final h = amps[i] * size.height * 0.9;
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
  bool shouldRepaint(covariant _StaticPainter oldDelegate) => false;
}

/// Export the static waveform (base64 pcm16) to PNG bytes.
Future<Uint8List> exportWaveformPng(
  String waveformBase64, {
  int width = 800,
  int height = 200,
  Color color = Colors.blue,
}) async {
  // Decode amplitudes
  final bytes = base64.decode(waveformBase64);
  final samples = <double>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    final lo = bytes[i];
    final hi = bytes[i + 1];
    final int16 = (hi << 8) | lo;
    final signed = int16 & 0x8000 != 0 ? int16 - 0x10000 : int16;
    samples.add(signed / 32768.0);
  }
  final step = (samples.length / 200).ceil().clamp(1, samples.length);
  final amps = <double>[];
  for (var i = 0; i < samples.length; i += step) {
    double sum = 0;
    final end = (i + step).clamp(0, samples.length);
    for (var j = i; j < end; j++) {
      sum += samples[j] * samples[j];
    }
    final mean = sum / (end - i);
    amps.add((mean <= 0) ? 0.0 : math.sqrt(mean));
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(width.toDouble(), height.toDouble());
  final painter = _StaticPainter(amps, color);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}
