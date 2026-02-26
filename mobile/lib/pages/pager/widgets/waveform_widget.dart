import 'package:flutter/material.dart';

/// 静态波形显示组件
class StaticWaveform extends StatelessWidget {
  final String? waveformBase64;
  final double height;
  final Color color;

  const StaticWaveform({
    super.key,
    this.waveformBase64,
    this.height = 60,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (waveformBase64 == null || waveformBase64!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '音频波形',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
