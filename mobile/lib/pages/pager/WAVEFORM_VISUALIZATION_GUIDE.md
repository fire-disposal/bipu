# 波形可视化指南

## 概述

本指南说明如何使用波形可视化组件将 0-255 的振幅包络还原为可视化图表，并支持复制为图片。

## 128 点精度分析

### 视觉效果评估

**128 点是否足够？**

| 场景 | 评估 | 说明 |
|------|------|------|
| 实时动画 | ✅ 足够 | 人眼感知不到 128 点的离散性 |
| 静态显示 | ✅ 足够 | 足以显示音频的主要特征 |
| 打印输出 | ⚠️ 可接受 | 在 A4 纸上显示清晰，但不如 256 点精细 |
| 高精度分析 | ❌ 不足 | 需要 256+ 点 |

### 推荐用途

- **UI 显示**: 128 点完全足够，提供良好的视觉效果
- **消息存储**: 128 字节极其高效，适合网络传输
- **复制分享**: 128 点的图片清晰易读，文件大小小

### 如需更高精度

可以在 `WaveformProcessor` 中修改：

```dart
static const int maxWaveformPoints = 256; // 改为 256 点
```

## 组件架构

### 核心组件

#### 1. `WaveformVisualizationWidget`
主要的可视化组件，包含波形图和操作按钮。

```dart
WaveformVisualizationWidget(
  waveformData: [50, 100, 150, 200, 180, 160, ...],
  width: 300,
  height: 150,
  waveColor: Colors.blue,
  backgroundColor: Colors.white,
  showGrid: true,
  showLabels: true,
  onCopyImage: () => print('Image copied'),
)
```

#### 2. `WaveformVisualizationPainter`
自定义绘制器，负责波形的实际绘制。

#### 3. `WaveformVisualizationCard`
完整的卡片组件，包含标题、波形和操作按钮。

```dart
WaveformVisualizationCard(
  waveformData: waveformData,
  title: '消息波形',
  onCopyImage: () => print('Copied'),
  onShare: () => print('Shared'),
)
```

## 使用示例

### 基础使用

```dart
import 'package:bipupu/pages/pager/widgets/waveform_visualization_widget.dart';

class MyPage extends StatelessWidget {
  final List<int> waveformData = [50, 100, 150, 200, 180, 160, 140, 120, 100, 80];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: WaveformVisualizationWidget(
          waveformData: waveformData,
          width: 300,
          height: 150,
        ),
      ),
    );
  }
}
```

### 在消息详情页中使用

```dart
class MessageDetailPage extends StatelessWidget {
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息详情')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 消息内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message.content),
            ),

            // 波形可视化
            if (message.waveform != null && message.waveform!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: WaveformVisualizationCard(
                  waveformData: message.waveform!,
                  title: '语音波形',
                  onCopyImage: () => _copyWaveform(context),
                  onShare: () => _shareWaveform(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _copyWaveform(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('波形图已复制')),
    );
  }

  void _shareWaveform(BuildContext context) {
    // 实现分享逻辑
  }
}
```

### 在发送页面中显示

```dart
class FinalizePage extends StatelessWidget {
  final String messageContent;
  final List<int> waveformData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 消息内容
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(messageContent),
              ),
            ),
          ),

          // 波形预览
          if (waveformData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: WaveformVisualizationWidget(
                waveformData: waveformData,
                width: 280,
                height: 120,
                waveColor: Colors.blue,
                showGrid: true,
                showLabels: false,
              ),
            ),

          // 发送按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => _sendMessage(context),
              child: const Text('发送'),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    // 发送消息
  }
}
```

## 绘制特性

### 波形绘制

- **填充区域**: 半透明的波形填充，显示音频的能量分布
- **线条**: 清晰的波形轮廓线
- **数据点**: 可选的数据点标记（点数 ≤ 32 时显示）

### 网格和标签

- **网格**: 8 条水平线 + 16 条竖直线，便于读取
- **幅度标签**: 显示 0, 64, 128, 192, 255 的幅度值
- **时间标签**: 显示 0%, 25%, 50%, 75%, 100% 的时间位置

### 中心线

虚线表示 0 幅度的参考线，便于判断音频的正负幅度。

## 复制图片功能

### 工作原理

1. 使用 `RepaintBoundary` 包装波形图
2. 调用 `toImage()` 将 Widget 转换为图片
3. 转换为 PNG 字节数据
4. 复制到剪贴板

### 代码示例

```dart
Future<void> _copyWaveformImage() async {
  final renderObject = _repaintKey.currentContext?.findRenderObject() 
      as RenderRepaintBoundary?;

  if (renderObject == null) return;

  final image = await renderObject.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  // 复制到剪贴板
  // 使用 flutter_clipboard 或其他库
}
```

### 图片质量

- **像素比**: 2.0（高清输出）
- **格式**: PNG（无损压缩）
- **大小**: 约 10-50KB（取决于波形复杂度）

## 自定义样式

### 颜色自定义

```dart
WaveformVisualizationWidget(
  waveformData: waveformData,
  waveColor: Colors.red,           // 波形颜色
  backgroundColor: Colors.grey.shade100,  // 背景颜色
)
```

### 尺寸自定义

```dart
WaveformVisualizationWidget(
  waveformData: waveformData,
  width: 400,   // 宽度
  height: 200,  // 高度
)
```

### 显示选项

```dart
WaveformVisualizationWidget(
  waveformData: waveformData,
  showGrid: true,    // 显示网格
  showLabels: true,  // 显示标签
)
```

## 性能优化

### 渲染性能

- **CustomPaint**: 高效的 Canvas 绘制
- **缓存**: 自动缓存绘制结果
- **重绘条件**: 仅在数据或颜色变化时重绘

### 内存使用

- **波形数据**: 最多 128 字节
- **图片缓存**: 按需生成，不持久化
- **UI 树**: 最小化 Widget 数量

### 优化建议

1. **避免频繁更新**: 使用 `const` 构造函数
2. **批量操作**: 一次性添加所有数据
3. **异步处理**: 复制图片时使用异步操作

## 常见问题

### Q: 波形图显示为空？
A: 检查 `waveformData` 是否为空，使用 `WaveformValidator.isValid()` 验证

### Q: 复制图片失败？
A: 确保 `RepaintBoundary` 已正确包装，检查日志输出

### Q: 图片质量不好？
A: 增加 `pixelRatio` 参数（例如 3.0）以获得更高质量

### Q: 如何导出为文件？
A: 使用 `image` 包将字节数据保存为文件

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

// 将字节数据保存为文件
final file = File('waveform.png');
await file.writeAsBytes(byteData.buffer.asUint8List());
```

## 集成检查清单

- [ ] 导入 `WaveformVisualizationWidget`
- [ ] 准备 0-255 的波形数据
- [ ] 在 UI 中添加组件
- [ ] 测试复制功能
- [ ] 自定义样式（可选）
- [ ] 处理空数据情况
- [ ] 添加错误处理
- [ ] 测试各种屏幕尺寸

## 扩展功能

### 可能的增强

1. **交互式缩放**: 支持手势缩放波形
2. **播放指示器**: 显示当前播放位置
3. **频谱分析**: 显示频率分布
4. **导出选项**: 支持多种格式导出
5. **对比显示**: 并排显示多个波形

### 实现示例

```dart
// 添加播放指示器
class InteractiveWaveformWidget extends StatefulWidget {
  final List<int> waveformData;
  final Duration duration;
  final Duration currentPosition;

  @override
  State<InteractiveWaveformWidget> createState() => 
      _InteractiveWaveformWidgetState();
}
```

## 参考资源

- [Flutter CustomPaint](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)
- [Canvas 绘制](https://api.flutter.dev/flutter/dart-ui/Canvas-class.html)
- [RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
