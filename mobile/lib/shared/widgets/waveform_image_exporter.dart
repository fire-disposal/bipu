import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'waveform_visualizer.dart';

/// 波形图片导出工具
///
/// 提供将波形数据导出为图片的功能
class WaveformImageExporter {
  /// 导出波形为 PNG 图片
  ///
  /// [waveform] 波形数据数组（0-255）
  /// [width] 图片宽度（像素）
  /// [height] 图片高度（像素）
  /// [color] 波形颜色
  /// [backgroundColor] 背景颜色，默认透明
  /// [style] 绘制样式
  ///
  /// 返回 PNG 图片的字节数据
  static Future<Uint8List?> exportToPng(
    List<int>? waveform, {
    int width = 400,
    int height = 120,
    Color color = const Color(0xFF4A90E2),
    Color? backgroundColor,
    WaveformStyle style = WaveformStyle.line,
    double strokeWidth = 2.0,
    double barWidth = 3.0,
  }) async {
    if (waveform == null || waveform.isEmpty) {
      return null;
    }

    // 验证波形数据
    if (!WaveformValidator.validate(waveform)) {
      debugPrint('[WaveformImageExporter] 波形数据验证失败');
      return null;
    }

    try {
      // 创建 PictureRecorder 和 Canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 绘制背景
      if (backgroundColor != null) {
        final paint = Paint()..color = backgroundColor;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          paint,
        );
      }

      // 绘制波形
      WaveformPainter.drawWaveform(
        waveform,
        canvas,
        ui.Size(width.toDouble(), height.toDouble()),
        color: color,
        style: style,
        strokeWidth: strokeWidth,
        barWidth: barWidth,
      );

      // 转换为 Image
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);

      // 转换为 PNG 字节
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      // 清理资源
      picture.dispose();
      image.dispose();

      return pngBytes;
    } catch (e) {
      debugPrint('[WaveformImageExporter] 导出 PNG 失败：$e');
      return null;
    }
  }

  /// 导出波形并保存到文件
  ///
  /// [waveform] 波形数据数组
  /// [fileName] 文件名（不含扩展名）
  /// [width] 图片宽度
  /// [height] 图片高度
  /// [color] 波形颜色
  /// [backgroundColor] 背景颜色
  ///
  /// 返回保存的文件路径
  static Future<String?> saveToFile(
    List<int>? waveform, {
    String fileName = 'waveform',
    int width = 400,
    int height = 120,
    Color color = const Color(0xFF4A90E2),
    Color? backgroundColor,
    WaveformStyle style = WaveformStyle.line,
  }) async {
    try {
      // 导出为 PNG
      final pngBytes = await exportToPng(
        waveform,
        width: width,
        height: height,
        color: color,
        backgroundColor: backgroundColor,
        style: style,
      );

      if (pngBytes == null) {
        return null;
      }

      // 获取临时目录
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.png';

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      debugPrint('[WaveformImageExporter] 波形图片已保存：$filePath');
      return filePath;
    } catch (e) {
      debugPrint('[WaveformImageExporter] 保存文件失败：$e');
      return null;
    }
  }

  /// 复制波形图片到剪贴板
  ///
  /// [waveform] 波形数据数组
  /// [width] 图片宽度
  /// [height] 图片高度
  /// [color] 波形颜色
  /// [backgroundColor] 背景颜色
  ///
  /// 返回是否复制成功
  static Future<bool> copyToClipboard(
    List<int>? waveform, {
    int width = 400,
    int height = 120,
    Color color = const Color(0xFF4A90E2),
    Color? backgroundColor,
    WaveformStyle style = WaveformStyle.line,
  }) async {
    try {
      // 导出为 PNG
      final pngBytes = await exportToPng(
        waveform,
        width: width,
        height: height,
        color: color,
        backgroundColor: backgroundColor,
        style: style,
      );

      if (pngBytes == null) {
        return false;
      }

      // 复制到剪贴板
      await Clipboard.setData(
        ClipboardData(
          text: '[波形图片]', // 文本提示
        ),
      );

      // 注意：Flutter 的 Clipboard API 目前不支持直接复制图片
      // 这里我们保存到临时文件并提示用户
      final filePath = await saveToFile(
        waveform,
        fileName: 'clipboard_waveform',
        width: width,
        height: height,
        color: color,
        backgroundColor: backgroundColor,
        style: style,
      );

      if (filePath != null) {
        debugPrint('[WaveformImageExporter] 波形图片已保存到：$filePath');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[WaveformImageExporter] 复制到剪贴板失败：$e');
      return false;
    }
  }

  /// 生成波形缩略图
  ///
  /// [waveform] 波形数据
  /// [size] 缩略图尺寸（正方形）
  /// [color] 波形颜色
  ///
  /// 返回缩略图 PNG 字节
  static Future<Uint8List?> generateThumbnail(
    List<int>? waveform, {
    int size = 64,
    Color color = const Color(0xFF4A90E2),
  }) async {
    return exportToPng(
      waveform,
      width: size,
      height: size,
      color: color,
      style: WaveformStyle.bar,
      barWidth: 2.0,
    );
  }

  /// 批量导出波形图片
  ///
  /// [waveforms] 波形数据列表
  /// [outputDir] 输出目录
  /// [fileNamePrefix] 文件名前缀
  ///
  /// 返回保存的文件路径列表
  static Future<List<String>> batchExport(
    List<List<int>> waveforms, {
    String? outputDir,
    String fileNamePrefix = 'waveform',
    int width = 400,
    int height = 120,
    Color color = const Color(0xFF4A90E2),
  }) async {
    final savedPaths = <String>[];

    final directory = outputDir != null
        ? Directory(outputDir)
        : await getTemporaryDirectory();

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    for (int i = 0; i < waveforms.length; i++) {
      final fileName = '${fileNamePrefix}_$i';
      final path = await saveToFile(
        waveforms[i],
        fileName: fileName,
        width: width,
        height: height,
        color: color,
      );

      if (path != null) {
        savedPaths.add(path);
      }
    }

    return savedPaths;
  }
}

/// 波形图片预览组件（带复制按钮）
///
/// 显示波形的静态图片预览，并提供复制功能
class WaveformImagePreview extends StatefulWidget {
  final List<int>? waveform;
  final double width;
  final double height;
  final Color color;
  final Color? backgroundColor;
  final bool showCopyButton;

  const WaveformImagePreview({
    super.key,
    this.waveform,
    this.width = 200,
    this.height = 60,
    this.color = const Color(0xFF4A90E2),
    this.backgroundColor,
    this.showCopyButton = true,
  });

  @override
  State<WaveformImagePreview> createState() => _WaveformImagePreviewState();
}

class _WaveformImagePreviewState extends State<WaveformImagePreview> {
  Uint8List? _imageBytes;
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(WaveformImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waveform != oldWidget.waveform) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final bytes = await WaveformImageExporter.exportToPng(
      widget.waveform,
      width: widget.width.toInt(),
      height: widget.height.toInt(),
      color: widget.color,
      backgroundColor: widget.backgroundColor,
    );

    if (mounted) {
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (widget.waveform == null || widget.waveform!.isEmpty) {
      return;
    }

    setState(() {
      _isCopying = true;
    });

    try {
      final success = await WaveformImageExporter.copyToClipboard(
        widget.waveform,
        width: widget.width.toInt(),
        height: widget.height.toInt(),
        color: widget.color,
        backgroundColor: widget.backgroundColor,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '波形图片已复制（保存到临时文件）' : '复制失败，请重试'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCopying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 图片预览
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imageBytes == null
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.color,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    width: widget.width,
                    height: widget.height,
                    fit: BoxFit.fill,
                  ),
                ),
        ),

        // 复制按钮
        if (widget.showCopyButton && widget.waveform != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: widget.width,
              child: ElevatedButton.icon(
                onPressed: _isCopying ? null : _copyToClipboard,
                icon: _isCopying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.copy, size: 16),
                label: Text(_isCopying ? '复制中...' : '复制图片'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 简化的波形图片导出组件
///
/// 提供基本的导出和复制功能
class SimpleWaveformExporter extends StatelessWidget {
  final List<int>? waveform;
  final String? fileName;
  final VoidCallback? onExported;
  final VoidCallback? onCopied;

  const SimpleWaveformExporter({
    super.key,
    this.waveform,
    this.fileName,
    this.onExported,
    this.onCopied,
  });

  Future<void> _exportImage(BuildContext context) async {
    if (waveform == null || waveform!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有波形数据可导出')));
      return;
    }

    final filePath = await WaveformImageExporter.saveToFile(
      waveform,
      fileName: fileName ?? 'waveform_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (filePath != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已保存到：$filePath')));
      onExported?.call();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导出失败')));
    }
  }

  Future<void> _copyImage(BuildContext context) async {
    if (waveform == null || waveform!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有波形数据可复制')));
      return;
    }

    final success = await WaveformImageExporter.copyToClipboard(waveform);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('波形图片已复制（保存到临时文件）')));
        onCopied?.call();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('复制失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 导出按钮
        ElevatedButton.icon(
          onPressed: () => _exportImage(context),
          icon: const Icon(Icons.download, size: 16),
          label: const Text('导出'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        const SizedBox(width: 8),

        // 复制按钮
        ElevatedButton.icon(
          onPressed: () => _copyImage(context),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}
