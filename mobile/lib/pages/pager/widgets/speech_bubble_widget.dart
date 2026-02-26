import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// 话语气泡数据模型
class SpeechBubbleData extends Equatable {
  /// 唯一标识符
  final String id;

  /// 气泡文本内容
  final String text;

  /// 显示时长（毫秒）
  final Duration displayDuration;

  /// 气泡样式
  final SpeechBubbleStyle style;

  /// 是否为操作员说话（影响气泡样式）
  final bool isOperator;

  /// 是否有语音播报
  final bool hasAudio;

  /// 显示位置偏好（相对于屏幕）
  final SpeechBubblePosition position;

  const SpeechBubbleData({
    required this.id,
    required this.text,
    this.displayDuration = const Duration(seconds: 4),
    this.style = SpeechBubbleStyle.primary,
    this.isOperator = true,
    this.hasAudio = false,
    this.position = SpeechBubblePosition.auto,
  });

  @override
  List<Object?> get props => [
    id,
    text,
    displayDuration,
    style,
    isOperator,
    hasAudio,
    position,
  ];
}

/// 气泡样式
enum SpeechBubbleStyle {
  primary, // 普通
  warning, // 警告（表情符号）
  success, // 成功
  error, // 错误
}

/// 气泡位置偏好
enum SpeechBubblePosition {
  auto, // 自动选择
  topLeft, // 左上
  topRight, // 右上
  bottomLeft, // 左下
  bottomRight, // 右下
  center, // 中心
}

/// 单个话语气泡Widget
class SpeechBubble extends StatefulWidget {
  final SpeechBubbleData data;
  final VoidCallback onDismiss;
  final double maxWidth;

  const SpeechBubble({
    super.key,
    required this.data,
    required this.onDismiss,
    this.maxWidth = 200,
  });

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scheduleDispose();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 入场动画：缩放
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // 入场动画：渐显
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // 上浮动画：随机水平移动
    final randomOffset = (DateTime.now().microsecond % 20 - 10) * 1.0;
    _slideAnimation = Tween<Offset>(
      begin: Offset(randomOffset / 100, 0),
      end: Offset(randomOffset / 100, -40),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 轻微旋转动画（灵动感）
    _rotateAnimation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  void _scheduleDispose() {
    Future.delayed(widget.data.displayDuration, () {
      if (mounted) {
        _playExitAnimation();
      }
    });
  }

  Future<void> _playExitAnimation() async {
    if (!mounted) return;

    // 离场动画
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        _opacityAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

        _slideAnimation = Tween<Offset>(
          begin: _slideAnimation.value,
          end: Offset(_slideAnimation.value.dx, -80),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      });

      await _controller.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.data.style) {
      case SpeechBubbleStyle.primary:
        return Colors.blue.shade50;
      case SpeechBubbleStyle.warning:
        return Colors.orange.shade50;
      case SpeechBubbleStyle.success:
        return Colors.green.shade50;
      case SpeechBubbleStyle.error:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    switch (widget.data.style) {
      case SpeechBubbleStyle.primary:
        return Colors.blue.shade200;
      case SpeechBubbleStyle.warning:
        return Colors.orange.shade200;
      case SpeechBubbleStyle.success:
        return Colors.green.shade200;
      case SpeechBubbleStyle.error:
        return Colors.red.shade200;
    }
  }

  Color _getTextColor() {
    switch (widget.data.style) {
      case SpeechBubbleStyle.primary:
        return Colors.blue.shade700;
      case SpeechBubbleStyle.warning:
        return Colors.orange.shade700;
      case SpeechBubbleStyle.success:
        return Colors.green.shade700;
      case SpeechBubbleStyle.error:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: Transform.rotate(
              angle: (_rotateAnimation.value * 3.14159 / 180),
              child: ScaleTransition(scale: _scaleAnimation, child: child),
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(color: _getBorderColor(), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文本内容
            Text(
              widget.data.text,
              style: TextStyle(
                fontSize: 13,
                color: _getTextColor(),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // 音频指示器（如果有TTS）
            if (widget.data.hasAudio) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 12,
                    color: _getTextColor().withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '有音频',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getTextColor().withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 话语气泡容器 - 管理多个气泡的显示
class SpeechBubbleContainer extends StatefulWidget {
  /// 目标Widget（通常是立绘）的全局位置和大小
  final GlobalKey targetKey;

  /// 容器大小
  final Size containerSize;

  /// 容器位置
  final Offset containerOffset;

  const SpeechBubbleContainer({
    super.key,
    required this.targetKey,
    required this.containerSize,
    required this.containerOffset,
  });

  @override
  State<SpeechBubbleContainer> createState() => _SpeechBubbleContainerState();
}

class _SpeechBubbleContainerState extends State<SpeechBubbleContainer> {
  final List<MapEntry<String, SpeechBubbleData>> _activeBubbles = [];

  /// 显示新的话语气泡
  void showBubble(SpeechBubbleData data) {
    setState(() {
      _activeBubbles.add(MapEntry(data.id, data));
    });
  }

  /// 移除特定气泡
  void _removeBubble(String id) {
    setState(() {
      _activeBubbles.removeWhere((entry) => entry.key == id);
    });
  }

  /// 计算气泡的显示位置
  Offset _calculateBubblePosition(int index, SpeechBubbleData data) {
    final targetSize = _getTargetSize();
    final targetPos = _getTargetPosition();

    // 基于位置偏好计算
    switch (data.position) {
      case SpeechBubblePosition.topLeft:
        return Offset(
          targetPos.dx - 100,
          targetPos.dy - 80 - (index * 70).toDouble(),
        );

      case SpeechBubblePosition.topRight:
        return Offset(
          targetPos.dx + targetSize.width + 20,
          targetPos.dy - 60 - (index * 70).toDouble(),
        );

      case SpeechBubblePosition.bottomLeft:
        return Offset(
          targetPos.dx - 100,
          targetPos.dy + targetSize.height + 20 + (index * 70).toDouble(),
        );

      case SpeechBubblePosition.bottomRight:
        return Offset(
          targetPos.dx + targetSize.width + 20,
          targetPos.dy + targetSize.height + 20 + (index * 70).toDouble(),
        );

      case SpeechBubblePosition.center:
        return Offset(
          targetPos.dx + targetSize.width / 2 - 100,
          targetPos.dy + targetSize.height / 2,
        );

      case SpeechBubblePosition.auto:
        // 自动选择最优位置
        final positions = [
          SpeechBubblePosition.topLeft,
          SpeechBubblePosition.topRight,
          SpeechBubblePosition.bottomRight,
        ];
        final randomPos = positions[index % positions.length];
        return _calculateBubblePosition(
          index,
          data.copyWith(position: randomPos),
        );
    }
  }

  /// 获取目标Widget的大小
  Size _getTargetSize() {
    try {
      final context = widget.targetKey.currentContext;
      if (context != null) {
        final renderObject = context.findRenderObject() as RenderBox?;
        return renderObject?.size ?? const Size(0, 0);
      }
    } catch (e) {
      // 忽略错误
    }
    return const Size(0, 0);
  }

  /// 获取目标Widget的位置
  Offset _getTargetPosition() {
    try {
      final context = widget.targetKey.currentContext;
      if (context != null) {
        final renderObject = context.findRenderObject() as RenderBox?;
        return renderObject?.localToGlobal(Offset.zero) ?? Offset.zero;
      }
    } catch (e) {
      // 忽略错误
    }
    return Offset.zero;
  }

  /// 限制位置在屏幕范围内
  Offset _constrainPosition(Offset pos, Size bubbleSize) {
    final screenSize = MediaQuery.of(context).size;
    final padding = 16.0;

    return Offset(
      pos.dx.clamp(padding, screenSize.width - bubbleSize.width - padding),
      pos.dy.clamp(padding, screenSize.height - bubbleSize.height - padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 动态显示气泡
        ..._activeBubbles.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value.value;
          final bubbleSize = const Size(220, 80);
          var pos = _calculateBubblePosition(index, data);
          pos = _constrainPosition(pos, bubbleSize);

          return Positioned(
            left: pos.dx,
            top: pos.dy,
            child: SpeechBubble(
              data: data,
              onDismiss: () => _removeBubble(data.id),
              maxWidth: 200,
            ),
          );
        }),
      ],
    );
  }
}

/// 话语气泡管理器 - 统一接口
class SpeechBubbleManager {
  static final SpeechBubbleManager _instance = SpeechBubbleManager._internal();

  factory SpeechBubbleManager() {
    return _instance;
  }

  SpeechBubbleManager._internal();

  _SpeechBubbleContainerState? _containerState;

  /// 注册容器状态
  void registerContainer(_SpeechBubbleContainerState? state) {
    _containerState = state;
  }

  /// 显示话语气泡
  void showSpeech({
    required String text,
    String? id,
    Duration displayDuration = const Duration(seconds: 4),
    SpeechBubbleStyle style = SpeechBubbleStyle.primary,
    bool isOperator = true,
    bool hasAudio = false,
    SpeechBubblePosition position = SpeechBubblePosition.auto,
  }) {
    final bubbleId = id ?? 'bubble_${DateTime.now().millisecondsSinceEpoch}';

    final data = SpeechBubbleData(
      id: bubbleId,
      text: text,
      displayDuration: displayDuration,
      style: style,
      isOperator: isOperator,
      hasAudio: hasAudio,
      position: position,
    );

    _containerState?.showBubble(data);
  }

  /// 显示成功消息
  void showSuccess({
    required String text,
    String? id,
    Duration displayDuration = const Duration(seconds: 3),
  }) {
    showSpeech(
      text: text,
      id: id,
      displayDuration: displayDuration,
      style: SpeechBubbleStyle.success,
    );
  }

  /// 显示警告消息
  void showWarning({
    required String text,
    String? id,
    Duration displayDuration = const Duration(seconds: 4),
  }) {
    showSpeech(
      text: text,
      id: id,
      displayDuration: displayDuration,
      style: SpeechBubbleStyle.warning,
    );
  }

  /// 显示错误消息
  void showError({
    required String text,
    String? id,
    Duration displayDuration = const Duration(seconds: 4),
  }) {
    showSpeech(
      text: text,
      id: id,
      displayDuration: displayDuration,
      style: SpeechBubbleStyle.error,
    );
  }
}

/// SpeechBubbleData的copyWith扩展
extension SpeechBubbleDataCopyWith on SpeechBubbleData {
  SpeechBubbleData copyWith({
    String? id,
    String? text,
    Duration? displayDuration,
    SpeechBubbleStyle? style,
    bool? isOperator,
    bool? hasAudio,
    SpeechBubblePosition? position,
  }) {
    return SpeechBubbleData(
      id: id ?? this.id,
      text: text ?? this.text,
      displayDuration: displayDuration ?? this.displayDuration,
      style: style ?? this.style,
      isOperator: isOperator ?? this.isOperator,
      hasAudio: hasAudio ?? this.hasAudio,
      position: position ?? this.position,
    );
  }
}
