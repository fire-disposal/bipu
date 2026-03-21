import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../../../core/utils/logger.dart';

/// 波形可视化组件
/// 将 0-255 的振幅包络还原为可视化图表，支持复制为图片
class WaveformVisualizationWidget extends StatefulWidget {
  final List<int> waveformData; // 0-255 的振幅数据
  final double width;
  final double height;
  final Color waveColor;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback? onCopyImage;

  const WaveformVisualizationWidget({
    super.key,
    required this.waveformData,
    this.width = 300,
    this.height = 150,
    this.waveColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.onCopyImage,
  });

  @override
  State<WaveformVisualizationWidget> createState() =>
      _WaveformVisualizationWidgetState();
}

class _WaveformVisualizationWidgetState
    extends State<WaveformVisualizationWidget> {
  final GlobalKey _repaintKey = GlobalKey();

  /// 复制波形图为图片
  Future<void> _copyWaveformImage() async {
    try {
      final renderObject =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (renderObject == null) {
        logger.e('Failed to get render object');
        return;
      }

      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        logger.e('Failed to convert image to bytes');
        return;
      }

      logger.i('Waveform image copied: ${byteData.lengthInBytes} bytes');

      // 触发回调
      widget.onCopyImage?.call();

      // 显示提示
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('波形图已复制到剪贴板')));
      }
    } catch (e) {
      logger.e('Failed to copy waveform image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '长按复制波形图',
      child: GestureDetector(
        onLongPress: _copyWaveformImage,
        child: RepaintBoundary(
          key: _repaintKey,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: WaveformVisualizationPainter(
                waveformData: widget.waveformData,
                waveColor: widget.waveColor,
              ),
              size: Size(widget.width, widget.height),
            ),
          ),
        ),
      ),
    );
  }
}

/// 波形可视化绘制器
/// 采用类似苹果录音机的上下对称条状图案
class WaveformVisualizationPainter extends CustomPainter {
  final List<int> waveformData;
  final Color waveColor;

  WaveformVisualizationPainter({
    required this.waveformData,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // 绘制波形 - 苹果录音机风格的上下对称条状
    _drawSymmetricBars(canvas, size);
  }

  /// 绘制空状态
  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '无波形数据',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  /// 绘制上下对称的条状波形（苹果录音机风格）
  void _drawSymmetricBars(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    
    // 计算条形数量和间距
    const barCount = 60; // 条形数量
    final dataStep = waveformData.length / barCount;
    final barWidth = size.width / barCount;
    final barSpacing = barWidth * 0.15; // 条形间距为宽度的 15%
    final actualBarWidth = barWidth - barSpacing;
    
    // 创建渐变色
    final gradient = LinearGradient(
      colors: [
        waveColor.withValues(alpha: 0.6),
        waveColor,
        waveColor.withValues(alpha: 0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    for (int i = 0; i < barCount; i++) {
      // 采样波形数据（使用平均值）
      final startIndex = (i * dataStep).floor();
      final endIndex = ((i + 1) * dataStep).ceil();
      final validIndices = [
        for (int j = startIndex; j < endIndex && j < waveformData.length; j++)
          waveformData[j]
      ];
      
      final amplitude = validIndices.isNotEmpty
          ? validIndices.reduce((a, b) => a + b) / validIndices.length / 255.0
          : 0.0;
      
      // 计算条形高度（最大高度为中心到顶部/底部的 95%）
      final maxBarHeight = centerY * 0.95;
      final barHeight = amplitude * maxBarHeight;
      
      // 最小高度保证可见性
      final minHeight = 2.0;
      final finalBarHeight = barHeight < minHeight ? minHeight : barHeight;
      
      // 创建条形矩形（上半部分）
      final topRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * barWidth + barSpacing / 2,
          centerY - finalBarHeight,
          actualBarWidth,
          finalBarHeight,
        ),
        Radius.circular(actualBarWidth * 0.4),
      );
      
      // 创建条形矩形（下半部分）
      final bottomRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * barWidth + barSpacing / 2,
          centerY,
          actualBarWidth,
          finalBarHeight,
        ),
        Radius.circular(actualBarWidth * 0.4),
      );
      
      // 绘制条形
      final barPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(i * barWidth, 0, barWidth, size.height),
        )
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(topRect, barPaint);
      canvas.drawRRect(bottomRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(WaveformVisualizationPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
        oldDelegate.waveColor != waveColor;
  }
}

/// 波形卡片组件
/// 包含波形可视化和操作按钮的完整卡片
class WaveformVisualizationCard extends StatelessWidget {
  final List<int> waveformData;
  final String title;
  final VoidCallback? onCopyImage;

  const WaveformVisualizationCard({
    super.key,
    required this.waveformData,
    this.title = '波形图',
    this.onCopyImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: WaveformVisualizationWidget(
                waveformData: waveformData,
                width: 280,
                height: 140,
                waveColor: Colors.blue,
                onCopyImage: onCopyImage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
