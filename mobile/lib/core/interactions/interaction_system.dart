import 'package:flutter/material.dart';
import '../animations/animation_system.dart';

/// 增强的手势检测器，提供丰富的触觉反馈
class EnhancedGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final bool enableHapticFeedback;
  final bool enableScaleAnimation;
  final bool enableRippleEffect;
  final Color rippleColor;
  final Duration animationDuration;

  const EnhancedGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onPanUpdate,
    this.onPanEnd,
    this.enableHapticFeedback = true,
    this.enableScaleAnimation = true,
    this.enableRippleEffect = true,
    this.rippleColor = Colors.blue,
    this.animationDuration = AnimationConfig.fast,
  });

  @override
  State<EnhancedGestureDetector> createState() =>
      _EnhancedGestureDetectorState();
}

class _EnhancedGestureDetectorState extends State<EnhancedGestureDetector>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (widget.enableScaleAnimation) {
      _scaleController.forward();
    }

    if (widget.enableRippleEffect) {
      _rippleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  void _handleDoubleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    // 添加缩放动画
    if (widget.enableScaleAnimation) {
      child = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: child,
      );
    }

    // 添加波纹效果
    if (widget.enableRippleEffect) {
      child = AnimationBuilders.rippleExpand(
        child: child,
        controller: _rippleController,
        color: widget.rippleColor,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: (details) => widget.onPanEnd?.call(),
      child: child,
    );
  }
}

/// 智能按钮组件，自动适配不同状态的视觉和触觉反馈
class SmartButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isLoading;
  final bool isDisabled;
  final ButtonStyle? style;
  final SmartButtonType type;

  const SmartButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.isLoading = false,
    this.isDisabled = false,
    this.style,
    this.type = SmartButtonType.elevated,
  });

  @override
  State<SmartButton> createState() => _SmartButtonState();
}

class _SmartButtonState extends State<SmartButton>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _pressController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(SmartButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!widget.isDisabled && !widget.isLoading) {
      HapticFeedback.lightImpact();
      _pressController.forward();
    }
  }

  void _handleTapUp() {
    _pressController.reverse();
  }

  void _handleTap() {
    if (!widget.isDisabled && !widget.isLoading) {
      HapticFeedback.selectionClick();
      widget.onPressed?.call();
    }
  }

  void _handleLongPress() {
    if (!widget.isDisabled && !widget.isLoading) {
      HapticFeedback.mediumImpact();
      widget.onLongPress?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = widget.child;

    // 添加加载指示器
    if (widget.isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingAnimation.value * 2 * 3.14159,
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          buttonChild,
        ],
      );
    }

    // 添加按压动画
    buttonChild = AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pressAnimation.value, child: child);
      },
      child: buttonChild,
    );

    // 创建对应类型的按钮
    Widget button;
    switch (widget.type) {
      case SmartButtonType.elevated:
        button = ElevatedButton(
          onPressed: widget.isDisabled || widget.isLoading ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          style: widget.style,
          child: buttonChild,
        );
        break;
      case SmartButtonType.filled:
        button = FilledButton(
          onPressed: widget.isDisabled || widget.isLoading ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          style: widget.style,
          child: buttonChild,
        );
        break;
      case SmartButtonType.outlined:
        button = OutlinedButton(
          onPressed: widget.isDisabled || widget.isLoading ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          style: widget.style,
          child: buttonChild,
        );
        break;
      case SmartButtonType.text:
        button = TextButton(
          onPressed: widget.isDisabled || widget.isLoading ? null : _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          style: widget.style,
          child: buttonChild,
        );
        break;
    }

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapUp,
      child: button,
    );
  }
}

enum SmartButtonType { elevated, filled, outlined, text }

/// 智能列表项，提供丰富的交互反馈
class SmartListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableSwipeActions;
  final List<SwipeAction>? leftSwipeActions;
  final List<SwipeAction>? rightSwipeActions;

  const SmartListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enableSwipeActions = false,
    this.leftSwipeActions,
    this.rightSwipeActions,
  });

  @override
  State<SmartListTile> createState() => _SmartListTileState();
}

class _SmartListTileState extends State<SmartListTile>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _highlightAnimation = ColorTween(
      begin: Colors.transparent,
      end: Theme.of(context).primaryColor.withValues(alpha: 0.1),
    ).animate(_highlightController);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    HapticFeedback.lightImpact();
    _highlightController.forward();
  }

  void _handleTapUp() {
    _highlightController.reverse();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _highlightAnimation.value,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: widget.leading,
            title: widget.title,
            subtitle: widget.subtitle,
            trailing: widget.trailing,
            onTap: _handleTap,
            onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          ),
        );
      },
    );

    if (widget.enableSwipeActions) {
      child = Dismissible(
        key: Key('list_tile_${widget.title.hashCode}'),
        background: _buildSwipeBackground(widget.leftSwipeActions, true),
        secondaryBackground: _buildSwipeBackground(
          widget.rightSwipeActions,
          false,
        ),
        child: child,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapUp,
      child: child,
    );
  }

  Widget? _buildSwipeBackground(List<SwipeAction>? actions, bool isLeft) {
    if (actions == null || actions.isEmpty) return null;

    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      color: actions.first.color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(actions.first.icon, color: Colors.white),
      ),
    );
  }
}

/// 滑动操作
class SwipeAction {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String label;

  const SwipeAction({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
  });
}

/// 触觉反馈管理器
class HapticFeedback {
  /// 轻微触感
  static void lightImpact() {
    // SystemSound.play(SystemSoundType.click);
  }

  /// 选择触感
  static void selectionClick() {
    // SystemSound.play(SystemSoundType.click);
  }

  /// 中等触感
  static void mediumImpact() {
    // SystemSound.play(SystemSoundType.click);
  }

  /// 重度触感
  static void heavyImpact() {
    // SystemSound.play(SystemSoundType.click);
  }

  /// 成功反馈
  static void success() {
    // SystemSound.play(SystemSoundType.alert);
  }

  /// 警告反馈
  static void warning() {
    // SystemSound.play(SystemSoundType.alert);
  }

  /// 错误反馈
  static void error() {
    // SystemSound.play(SystemSoundType.alert);
  }
}
