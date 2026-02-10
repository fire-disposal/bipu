import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局交互优化器
class InteractionOptimizer {
  static bool _isInitialized = false;
  static bool _hapticEnabled = true;
  static bool _soundEnabled = true;
  static double _animationScale = 1.0;

  /// 初始化交互优化器
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 检查设备能力
      await _detectDeviceCapabilities();

      // 设置全局触觉反馈
      await _setupHapticFeedback();

      _isInitialized = true;
      debugPrint('InteractionOptimizer initialized successfully');
    } catch (e) {
      debugPrint('InteractionOptimizer initialization failed: $e');
    }
  }

  /// 检测设备能力
  static Future<void> _detectDeviceCapabilities() async {
    // 这里可以添加设备性能检测逻辑
    // 例如检测是否支持触觉反馈、设备性能等
  }

  /// 设置触觉反馈
  static Future<void> _setupHapticFeedback() async {
    try {
      // 测试触觉反馈是否可用
      await HapticFeedback.lightImpact();
      _hapticEnabled = true;
    } catch (e) {
      _hapticEnabled = false;
      debugPrint('Haptic feedback not available: $e');
    }
  }

  /// 触觉反馈控制
  static void lightImpact() {
    if (!_hapticEnabled) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (!_hapticEnabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (!_hapticEnabled) return;
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (!_hapticEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// 声音反馈控制
  static void playClickSound() {
    if (!_soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  static void playAlertSound() {
    if (!_soundEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  /// 设置动画缩放
  static void setAnimationScale(double scale) {
    _animationScale = scale.clamp(0.0, 2.0);
  }

  static double get animationScale => _animationScale;

  /// 获取优化的动画持续时间
  static Duration getOptimizedDuration(Duration baseDuration) {
    return Duration(
      milliseconds: (baseDuration.inMilliseconds / _animationScale).round(),
    );
  }
}

/// 智能触摸反馈组件
class SmartTouchFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final TouchFeedbackType feedbackType;
  final bool enableVisualFeedback;
  final bool enableHapticFeedback;
  final bool enableSoundFeedback;
  final Duration animationDuration;

  const SmartTouchFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.feedbackType = TouchFeedbackType.light,
    this.enableVisualFeedback = true,
    this.enableHapticFeedback = true,
    this.enableSoundFeedback = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<SmartTouchFeedback> createState() => _SmartTouchFeedbackState();
}

class _SmartTouchFeedbackState extends State<SmartTouchFeedback>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: InteractionOptimizer.getOptimizedDuration(
        widget.animationDuration,
      ),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: InteractionOptimizer.getOptimizedDuration(
        const Duration(milliseconds: 400),
      ),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutCubic),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCirc),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableVisualFeedback) {
      _scaleController.forward();
    }

    if (widget.enableHapticFeedback) {
      switch (widget.feedbackType) {
        case TouchFeedbackType.light:
          InteractionOptimizer.lightImpact();
          break;
        case TouchFeedbackType.medium:
          InteractionOptimizer.mediumImpact();
          break;
        case TouchFeedbackType.heavy:
          InteractionOptimizer.heavyImpact();
          break;
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableVisualFeedback) {
      _scaleController.reverse();
      _rippleController.forward().then((_) {
        _rippleController.reset();
      });
    }

    if (widget.enableSoundFeedback) {
      InteractionOptimizer.playClickSound();
    }
  }

  void _handleTapCancel() {
    if (widget.enableVisualFeedback) {
      _scaleController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      InteractionOptimizer.selectionClick();
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHapticFeedback) {
      InteractionOptimizer.heavyImpact();
    }
    widget.onLongPress?.call();
  }

  void _handleDoubleTap() {
    if (widget.enableHapticFeedback) {
      InteractionOptimizer.mediumImpact();
    }
    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    // 添加缩放动画
    if (widget.enableVisualFeedback) {
      child = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: child,
      );

      // 添加涟漪效果
      child = Stack(
        children: [
          child,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: RippleEffectPainter(
                    animation: _rippleAnimation,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null ? _handleTap : null,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
      child: child,
    );
  }
}

/// 涟漪效果绘制器
class RippleEffectPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  RippleEffectPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide / 2;
    final radius = maxRadius * animation.value;

    final paint = Paint()
      ..color = color.withValues(alpha: (1 - animation.value) * 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RippleEffectPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

/// 触摸反馈类型
enum TouchFeedbackType { light, medium, heavy }

/// 智能按钮封装
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool isLoading;
  final bool isDisabled;
  final ResponsiveButtonType type;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.isLoading = false,
    this.isDisabled = false,
    this.type = ResponsiveButtonType.elevated,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = SmartTouchFeedback(
      onTap: (!isDisabled && !isLoading) ? onPressed : null,
      onLongPress: (!isDisabled && !isLoading) ? onLongPress : null,
      feedbackType: TouchFeedbackType.medium,
      child: _buildButton(context),
    );

    // 添加加载状态处理
    if (isLoading) {
      button = Stack(
        alignment: Alignment.center,
        children: [
          button,
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    return button;
  }

  Widget _buildButton(BuildContext context) {
    switch (type) {
      case ResponsiveButtonType.elevated:
        return ElevatedButton(
          onPressed: (!isDisabled && !isLoading) ? () {} : null,
          onLongPress: (!isDisabled && !isLoading) ? () {} : null,
          style: style,
          child: child,
        );
      case ResponsiveButtonType.filled:
        return FilledButton(
          onPressed: (!isDisabled && !isLoading) ? () {} : null,
          onLongPress: (!isDisabled && !isLoading) ? () {} : null,
          style: style,
          child: child,
        );
      case ResponsiveButtonType.outlined:
        return OutlinedButton(
          onPressed: (!isDisabled && !isLoading) ? () {} : null,
          onLongPress: (!isDisabled && !isLoading) ? () {} : null,
          style: style,
          child: child,
        );
      case ResponsiveButtonType.text:
        return TextButton(
          onPressed: (!isDisabled && !isLoading) ? () {} : null,
          onLongPress: (!isDisabled && !isLoading) ? () {} : null,
          style: style,
          child: child,
        );
    }
  }
}

enum ResponsiveButtonType { elevated, filled, outlined, text }

/// 智能滑动组件
class ResponsiveSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  const ResponsiveSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  State<ResponsiveSlider> createState() => _ResponsiveSliderState();
}

class _ResponsiveSliderState extends State<ResponsiveSlider> {
  bool _isChanging = false;

  void _handleChangeStart(double value) {
    setState(() => _isChanging = true);
    InteractionOptimizer.lightImpact();
    widget.onChangeStart?.call(value);
  }

  void _handleChanged(double value) {
    // 只在值实际变化时提供触觉反馈
    if ((value - widget.value).abs() > 0.01) {
      InteractionOptimizer.selectionClick();
    }
    widget.onChanged?.call(value);
  }

  void _handleChangeEnd(double value) {
    setState(() => _isChanging = false);
    InteractionOptimizer.mediumImpact();
    widget.onChangeEnd?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.diagonal3Values(
        _isChanging ? 1.02 : 1.0,
        _isChanging ? 1.02 : 1.0,
        1.0,
      ),
      child: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.label,
        onChanged: widget.onChanged != null ? _handleChanged : null,
        onChangeStart: widget.onChangeStart != null ? _handleChangeStart : null,
        onChangeEnd: widget.onChangeEnd != null ? _handleChangeEnd : null,
      ),
    );
  }
}

/// 智能开关组件
class ResponsiveSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const ResponsiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  State<ResponsiveSwitch> createState() => _ResponsiveSwitchState();
}

class _ResponsiveSwitchState extends State<ResponsiveSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleChanged(bool value) {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    InteractionOptimizer.mediumImpact();
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    Widget switchWidget = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Switch(
            value: widget.value,
            onChanged: widget.onChanged != null ? _handleChanged : null,
          ),
        );
      },
    );

    if (widget.label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(widget.label!), const SizedBox(width: 8), switchWidget],
      );
    }

    return switchWidget;
  }
}

/// 全局交互配置
class InteractionConfig {
  static bool enableHapticFeedback = true;
  static bool enableSoundFeedback = false;
  static bool enableVisualFeedback = true;
  static double animationScale = 1.0;
  static Duration defaultAnimationDuration = const Duration(milliseconds: 250);
}
