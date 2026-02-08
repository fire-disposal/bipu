import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// 动画配置类
class AnimationConfig {
  // 持续时间配置
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // 缓动曲线配置
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;
  static const Curve spring = Curves.elasticInOut;

  // 弹簧物理配置
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 30.0,
  );

  static const SpringDescription bouncySpring = SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 8.0,
  );
}

/// 页面转场动画
class PageTransitions {
  /// 滑动转场
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: end).animate(
        CurvedAnimation(parent: animation, curve: AnimationConfig.easeOut),
      ),
      child: child,
    );
  }

  /// 淡入转场
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// 缩放转场
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(parent: animation, curve: AnimationConfig.easeOut),
      ),
      child: child,
    );
  }

  /// 旋转转场
  static Widget rotationTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return RotationTransition(
      turns: Tween<double>(begin: begin, end: end).animate(animation),
      child: child,
    );
  }

  /// 组合转场（滑动+淡入）
  static Widget slideAndFadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: AnimationConfig.easeOut),
      ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// 简化的共享轴转场
  static Widget sharedAxisTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: AnimationConfig.easeOut,
              ),
            ),
        child: child,
      ),
    );
  }
}

/// 智能动画控制器
class SmartAnimationController extends AnimationController {
  SmartAnimationController({
    required super.vsync,
    super.duration = AnimationConfig.normal,
    super.debugLabel,
  });

  /// 智能播放动画（考虑设备性能）
  Future<void> smartForward() async {
    // 检查设备性能，低性能设备减少动画时长
    final shouldOptimize = await _shouldOptimizeAnimations();
    if (shouldOptimize) {
      duration = Duration(milliseconds: (duration?.inMilliseconds ?? 300) ~/ 2);
    }
    return forward();
  }

  /// 智能反向播放动画
  Future<void> smartReverse() async {
    final shouldOptimize = await _shouldOptimizeAnimations();
    if (shouldOptimize) {
      duration = Duration(milliseconds: (duration?.inMilliseconds ?? 300) ~/ 2);
    }
    return reverse();
  }

  /// 检查是否需要优化动画（简化版本，实际应用中可以更复杂）
  Future<bool> _shouldOptimizeAnimations() async {
    // 这里可以添加更复杂的性能检测逻辑
    return false; // 暂时返回false
  }
}

/// 动画构建器工具类
class AnimationBuilders {
  /// 弹性缩放动画
  static Widget elasticScale({
    required Widget child,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = AnimationConfig.elastic,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: Tween<double>(
            begin: begin,
            end: end,
          ).evaluate(CurvedAnimation(parent: controller, curve: curve)),
          child: child,
        );
      },
      child: child,
    );
  }

  /// 摇摆动画
  static Widget shake({
    required Widget child,
    required AnimationController controller,
    double offset = 10.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final animation = Tween<double>(
          begin: -offset,
          end: offset,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticIn));

        return Transform.translate(
          offset: Offset(animation.value, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// 波纹展开动画
  static Widget rippleExpand({
    required Widget child,
    required AnimationController controller,
    Color color = Colors.blue,
    double maxRadius = 100.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RipplePainter(
            animation: controller,
            color: color,
            maxRadius: maxRadius,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// 列表项目出现动画
  static Widget staggeredListAnimation({
    required Widget child,
    required int index,
    required AnimationController controller,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          (index * 0.1).clamp(0.0, 1.0),
          ((index * 0.1) + 0.5).clamp(0.0, 1.0),
          curve: AnimationConfig.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - itemAnimation.value)),
          child: Opacity(opacity: itemAnimation.value, child: child),
        );
      },
      child: child,
    );
  }
}

/// 波纹绘制器
class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double maxRadius;

  RipplePainter({
    required this.animation,
    required this.color,
    required this.maxRadius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1 - animation.value)
      ..style = PaintingStyle.fill;

    final radius = animation.value * maxRadius;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 自定义路由动画
class CustomRouteTransition<T> extends PageRoute<T> {
  final Widget child;
  final Duration transitionDuration;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  transitionBuilder;

  CustomRouteTransition({
    required this.child,
    required this.transitionBuilder,
    this.transitionDuration = AnimationConfig.normal,
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionBuilder(context, animation, secondaryAnimation, child);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }
}

/// 高级动画混合器
class AnimationMixer {
  final List<AnimationController> controllers = [];
  final List<Animation<double>> animations = [];

  /// 添加动画控制器
  void addController(AnimationController controller) {
    controllers.add(controller);
  }

  /// 添加动画
  void addAnimation(Animation<double> animation) {
    animations.add(animation);
  }

  /// 同时播放所有动画
  Future<void> playAll() async {
    final futures = controllers.map((controller) => controller.forward());
    await Future.wait(futures);
  }

  /// 依次播放动画
  Future<void> playSequentially({Duration delay = AnimationConfig.fast}) async {
    for (final controller in controllers) {
      await controller.forward();
      await Future.delayed(delay);
    }
  }

  /// 停止所有动画
  void stopAll() {
    for (final controller in controllers) {
      controller.stop();
    }
  }

  /// 重置所有动画
  void resetAll() {
    for (final controller in controllers) {
      controller.reset();
    }
  }

  /// 释放资源
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    animations.clear();
  }
}

/// 动画性能监测器
class AnimationPerformanceMonitor {
  static final Map<String, List<int>> _frameTimes = {};
  static final Map<String, DateTime> _animationStartTimes = {};

  /// 开始监测动画性能
  static void startMonitoring(String animationName) {
    _animationStartTimes[animationName] = DateTime.now();
    _frameTimes[animationName] = [];
  }

  /// 记录帧时间
  static void recordFrameTime(String animationName, int frameTime) {
    _frameTimes[animationName]?.add(frameTime);
  }

  /// 停止监测并获取结果
  static AnimationPerformanceResult stopMonitoring(String animationName) {
    final startTime = _animationStartTimes[animationName];
    final frameTimes = _frameTimes[animationName] ?? [];

    final result = AnimationPerformanceResult(
      animationName: animationName,
      totalDuration: startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero,
      frameTimes: List.from(frameTimes),
      averageFrameTime: frameTimes.isEmpty
          ? 0
          : frameTimes.reduce((a, b) => a + b) / frameTimes.length,
      droppedFrames: frameTimes.where((time) => time > 16).length,
    );

    // 清理数据
    _animationStartTimes.remove(animationName);
    _frameTimes.remove(animationName);

    return result;
  }
}

/// 动画性能结果
class AnimationPerformanceResult {
  final String animationName;
  final Duration totalDuration;
  final List<int> frameTimes;
  final double averageFrameTime;
  final int droppedFrames;

  const AnimationPerformanceResult({
    required this.animationName,
    required this.totalDuration,
    required this.frameTimes,
    required this.averageFrameTime,
    required this.droppedFrames,
  });

  /// 是否性能良好（60fps，平均帧时间 < 16.67ms，掉帧 < 5%）
  bool get isPerformanceGood {
    return averageFrameTime < 16.67 &&
        (droppedFrames / frameTimes.length) < 0.05;
  }

  @override
  String toString() {
    return 'AnimationPerformance($animationName): '
        'duration=${totalDuration.inMilliseconds}ms, '
        'avgFrameTime=${averageFrameTime.toStringAsFixed(2)}ms, '
        'droppedFrames=$droppedFrames/${frameTimes.length}';
  }
}
