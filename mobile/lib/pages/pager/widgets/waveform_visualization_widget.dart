import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../../core/utils/logger.dart';

/// 波形可视化组件
/// 将 0-255 的振幅包络还原为可视化图表，支持复制为图片
class WaveformVisualizationWidget extends StatefulWidget {
  final List<int> waveformData; // 0-255 的振幅数据
  final double width;
  final double height;
  final Color waveColor;
  final Color backgroundColor;
  final bool showGrid;
  final bool showLabels;
  final VoidCallback? onCopyImage;

  const WaveformVisualizationWidget({
    super.key,
    required this.waveformData,
    this.width = 300,
    this.height = 150,
    this.waveColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.showGrid = true,
    this.showLabels = true,
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
    return Column(
      children: [
        // 波形图
        RepaintBoundary(
          key: _repaintKey,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: WaveformVisualizationPainter(
                waveformData: widget.waveformData,
                waveColor: widget.waveColor,
                showGrid: widget.showGrid,
                showLabels: widget.showLabels,
              ),
              size: Size(widget.width, widget.height),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 复制按钮
            ElevatedButton.icon(
              onPressed: _copyWaveformImage,
              icon: const Icon(Icons.copy),
              label: const Text('复制图片'),
            ),

            const SizedBox(width: 12),

            // 信息按钮
            ElevatedButton.icon(
              onPressed: () => _showWaveformInfo(),
              icon: const Icon(Icons.info_outline),
              label: const Text('详情'),
            ),
          ],
        ),
      ],
    );
  }

  /// 显示波形信息对话框
  void _showWaveformInfo() {
    if (widget.waveformData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有波形数据')));
      return;
    }

    final min = widget.waveformData.reduce((a, b) => a < b ? a : b);
    final max = widget.waveformData.reduce((a, b) => a > b ? a : b);
    final avg =
        widget.waveformData.reduce((a, b) => a + b) /
        widget.waveformData.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('波形信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('数据点数', '${widget.waveformData.length}'),
            _buildInfoRow('最小值', '$min'),
            _buildInfoRow('最大值', '$max'),
            _buildInfoRow('平均值', avg.toStringAsFixed(2)),
            _buildInfoRow('动态范围', '${max - min}'),
            _buildInfoRow('数据大小', '${widget.waveformData.length} 字节'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// 波形可视化绘制器
class WaveformVisualizationPainter extends CustomPainter {
  final List<int> waveformData;
  final Color waveColor;
  final bool showGrid;
  final bool showLabels;

  WaveformVisualizationPainter({
    required this.waveformData,
    required this.waveColor,
    required this.showGrid,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // 绘制网格
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // 绘制中心线
    _drawCenterLine(canvas, size);

    // 绘制波形
    _drawWaveform(canvas, size);

    // 绘制标签
    if (showLabels) {
      _drawLabels(canvas, size);
    }
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

  /// 绘制网格
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;

    // 水平网格线（8 条）
    for (int i = 1; i < 8; i++) {
      final y = (size.height / 8) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 竖直网格线（16 条）
    for (int i = 1; i < 16; i++) {
      final x = (size.width / 16) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  /// 绘制中心线
  void _drawCenterLine(Canvas canvas, Size size) {
    final centerPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final centerY = size.height / 2;

    // 绘制虚线（使用多个短线段）
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    for (double x = 0; x < size.width; x += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset((x + dashWidth).clamp(0, size.width), centerY),
        centerPaint,
      );
    }
  }

  /// 绘制波形
  void _drawWaveform(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = waveColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final pointWidth =
        size.width / (waveformData.length - 1).clamp(1, double.infinity);

    // 构建路径
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * pointWidth;
      final amplitude = waveformData[i] / 255.0; // 归一化到 0-1
      final y = centerY - (amplitude * centerY);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, centerY);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // 闭合填充路径
    fillPath.lineTo(size.width, centerY);
    fillPath.close();

    // 绘制填充
    canvas.drawPath(fillPath, fillPaint);

    // 绘制线条
    canvas.drawPath(path, paint);

    // 绘制数据点
    _drawDataPoints(canvas, size, centerY, pointWidth);
  }

  /// 绘制数据点
  void _drawDataPoints(
    Canvas canvas,
    Size size,
    double centerY,
    double pointWidth,
  ) {
    final pointPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * pointWidth;
      final amplitude = waveformData[i] / 255.0;
      final y = centerY - (amplitude * centerY);

      // 只绘制部分点以避免过度拥挤
      if (waveformData.length <= 32 || i % (waveformData.length ~/ 32) == 0) {
        canvas.drawCircle(Offset(x, y), 2, pointPaint);
      }
    }
  }

  /// 绘制标签
  void _drawLabels(Canvas canvas, Size size) {
    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    // 绘制幅度标签
    final amplitudes = ['255', '192', '128', '64', '0'];
    for (int i = 0; i < amplitudes.length; i++) {
      final y = (size.height / 4) * i;

      textPaint.text = TextSpan(
        text: amplitudes[i],
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );

      textPaint.layout();
      textPaint.paint(canvas, Offset(5, y - 5));
    }

    // 绘制时间标签
    final timeLabels = ['0%', '25%', '50%', '75%', '100%'];
    for (int i = 0; i < timeLabels.length; i++) {
      final x = (size.width / 4) * i;

      textPaint.text = TextSpan(
        text: timeLabels[i],
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );

      textPaint.layout();
      textPaint.paint(canvas, Offset(x - 10, size.height - 15));
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
  final VoidCallback? onShare;

  const WaveformVisualizationCard({
    super.key,
    required this.waveformData,
    this.title = '波形图',
    this.onCopyImage,
    this.onShare,
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
            // 标题
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // 波形可视化
            Center(
              child: WaveformVisualizationWidget(
                waveformData: waveformData,
                width: 280,
                height: 140,
                waveColor: Colors.blue,
                showGrid: true,
                showLabels: true,
                onCopyImage: onCopyImage,
              ),
            ),

            const SizedBox(height: 16),

            // 额外操作按钮
            if (onShare != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
