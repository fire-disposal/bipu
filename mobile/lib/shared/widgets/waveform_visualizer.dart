import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// 波形数据验证工具
///
/// 验证波形数据是否符合规范：
/// - 必须是数组
/// - 元素必须是 0-255 的整数
/// - 建议长度不超过 128
class WaveformValidator {
  /// 验证波形数据
  static bool validate(List<int>? waveform) {
    // 允许 null 或空数组
    if (waveform == null || waveform.isEmpty) {
      return true;
    }

    // 检查数组元素
    for (int i = 0; i < waveform.length; i++) {
      final value = waveform[i];

      // 必须是整数且在 0-255 范围内
      if (value < 0 || value > 255) {
        debugPrint('[WaveformValidator] 位置 $i 的值超出范围 (0-255): $value');
        return false;
      }
    }

    // 长度警告（不阻止使用）
    if (waveform.length > 128) {
      debugPrint('[WaveformValidator] 波形数据长度 ${waveform.length} 超过建议值 128');
    }

    return true;
  }

  /// 规范化波形数据
  ///
  /// 确保数据在有效范围内，如果无效则返回空数组
  static List<int> normalize(List<int>? waveform) {
    if (waveform == null || waveform.isEmpty) {
      return [];
    }

    if (!validate(waveform)) {
      return [];
    }

    return waveform;
  }

  /// 缩放波形数据到指定长度
  ///
  /// 使用线性插值将波形数据缩放到目标长度
  static List<int> scale(List<int> waveform, int targetLength) {
    if (waveform.isEmpty || targetLength <= 0) {
      return [];
    }

    if (waveform.length == targetLength) {
      return waveform;
    }

    final scaled = <int>[];
    final ratio = waveform.length / targetLength;

    for (int i = 0; i < targetLength; i++) {
      final start = (i * ratio).floor();
      final end = ((i + 1) * ratio).floor().clamp(0, waveform.length - 1);

      // 计算平均值
      int sum = 0;
      int count = 0;
      for (int j = start; j <= end && j < waveform.length; j++) {
        sum += waveform[j];
        count++;
      }

      scaled.add(count > 0 ? (sum / count).round() : 0);
    }

    return scaled;
  }
}

/// 波形绘制工具
///
/// 提供波形数据的可视化绘制功能
class WaveformPainter {
  /// 绘制波形到 Canvas
  ///
  /// [waveform] 波形数据数组（0-255）
  /// [canvas] 画布
  /// [size] 画布大小
  /// [color] 波形颜色
  /// [style] 绘制样式（line 或 bar）
  static void drawWaveform(
    List<int> waveform,
    ui.Canvas canvas,
    ui.Size size, {
    Color color = const Color(0xFF4A90E2),
    WaveformStyle style = WaveformStyle.line,
    double strokeWidth = 2.0,
    double barWidth = 2.0,
  }) {
    if (waveform.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxValue = waveform.reduce(math.max).toDouble();
    final normalizedMax = maxValue > 0 ? maxValue : 255.0;

    if (style == WaveformStyle.line) {
      _drawLineWaveform(waveform, canvas, size, paint, normalizedMax);
    } else {
      _drawBarWaveform(waveform, canvas, size, paint, normalizedMax, barWidth);
    }
  }

  /// 绘制线形波形
  static void _drawLineWaveform(
    List<int> waveform,
    ui.Canvas canvas,
    ui.Size size,
    Paint paint,
    double normalizedMax,
  ) {
    final path = Path();
    final pointWidth = size.width / waveform.length;
    final centerY = size.height / 2;

    for (int i = 0; i < waveform.length; i++) {
      final x = i * pointWidth + pointWidth / 2;
      final value = waveform[i];
      final y = centerY - (value / normalizedMax) * (size.height / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  /// 绘制条形波形
  static void _drawBarWaveform(
    List<int> waveform,
    ui.Canvas canvas,
    ui.Size size,
    Paint paint,
    double normalizedMax,
    double barWidth,
  ) {
    final spacing = barWidth;
    final totalWidth = waveform.length * (barWidth + spacing);
    final startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < waveform.length; i++) {
      final value = waveform[i];
      final barHeight = (value / normalizedMax) * size.height;
      final x = startX + i * (barWidth + spacing);
      final y = (size.height - barHeight) / 2;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRect(rect, paint);
    }
  }

  /// 创建波形预览字符串（使用 Unicode 块元素）
  ///
  /// 将波形数据转换为类似 ▁▂▃▄▅▆▇█ 的字符串
  static String createPreview(List<int>? waveform, {int maxLength = 16}) {
    if (waveform == null || waveform.isEmpty) {
      return '▁▁▁▁';
    }

    const chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    final previewLength = math.min(waveform.length, maxLength);

    final result = StringBuffer();
    for (int i = 0; i < previewLength; i++) {
      final index = (i * waveform.length / previewLength).floor();
      final value = waveform[index];
      final charIndex = ((value / 255) * (chars.length - 1)).round();
      result.write(chars[charIndex.clamp(0, chars.length - 1)]);
    }

    return result.toString();
  }
}

/// 波形绘制样式
enum WaveformStyle {
  /// 线形
  line,

  /// 条形
  bar,
}

/// 波形可视化组件
///
/// 使用 CustomPaint 绘制波形数据
class WaveformVisualizer extends HookWidget {
  /// 波形数据
  final List<int>? waveform;

  /// 画布宽度
  final double width;

  /// 画布高度
  final double height;

  /// 波形颜色
  final Color color;

  /// 绘制样式
  final WaveformStyle style;

  /// 线条宽度
  final double strokeWidth;

  /// 条形宽度（bar 样式使用）
  final double barWidth;

  const WaveformVisualizer({
    super.key,
    this.waveform,
    this.width = 200,
    this.height = 60,
    this.color = const Color(0xFF4A90E2),
    this.style = WaveformStyle.line,
    this.strokeWidth = 2.0,
    this.barWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedWaveform = useMemoized(
      () => WaveformValidator.normalize(waveform),
      [waveform],
    );

    if (normalizedWaveform.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            '无波形数据',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _WaveformPainterDelegate(
          waveform: normalizedWaveform,
          color: color,
          style: style,
          strokeWidth: strokeWidth,
          barWidth: barWidth,
        ),
      ),
    );
  }
}

class _WaveformPainterDelegate extends CustomPainter {
  final List<int> waveform;
  final Color color;
  final WaveformStyle style;
  final double strokeWidth;
  final double barWidth;

  _WaveformPainterDelegate({
    required this.waveform,
    required this.color,
    required this.style,
    required this.strokeWidth,
    required this.barWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    WaveformPainter.drawWaveform(
      waveform,
      canvas,
      size,
      color: color,
      style: style,
      strokeWidth: strokeWidth,
      barWidth: barWidth,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainterDelegate oldDelegate) {
    return waveform != oldDelegate.waveform ||
        color != oldDelegate.color ||
        style != oldDelegate.style ||
        strokeWidth != oldDelegate.strokeWidth ||
        barWidth != oldDelegate.barWidth;
  }
}

/// 波形信息
class WaveformInfo {
  /// 采样点数量
  final int sampleCount;

  /// 峰值
  final int peak;

  /// 平均值
  final double average;

  /// 预览字符串
  final String preview;

  WaveformInfo({
    required this.sampleCount,
    required this.peak,
    required this.average,
    required this.preview,
  });

  /// 从波形数据创建信息对象
  static WaveformInfo? fromWaveform(List<int>? waveform) {
    if (waveform == null || waveform.isEmpty) {
      return null;
    }

    final peak = waveform.reduce(math.max);
    final average = waveform.reduce((a, b) => a + b) / waveform.length;

    return WaveformInfo(
      sampleCount: waveform.length,
      peak: peak,
      average: average,
      preview: WaveformPainter.createPreview(waveform),
    );
  }
}
