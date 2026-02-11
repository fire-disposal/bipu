import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/services/voice_guide_service.dart';
import '../../../../models/operator/virtual_operator.dart';

class FloatingOperatorWidget extends StatefulWidget {
  final VoidCallback? onPressed;

  const FloatingOperatorWidget({super.key, this.onPressed});

  @override
  State<FloatingOperatorWidget> createState() => _FloatingOperatorWidgetState();
}

class _FloatingOperatorWidgetState extends State<FloatingOperatorWidget>
    with TickerProviderStateMixin {
  final VoiceGuideService _voiceService = VoiceGuideService();

  late AnimationController _floatController;
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late AnimationController _tapController;

  late Animation<double> _floatAnimation;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();

    // 浮动动画 - 缓慢的上下浮动
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 呼吸动画 - 轻微的缩放
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    // 脉冲动画 - 用于活跃状态
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // 点击反馈动画
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _breathController.dispose();
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward().then((_) => _tapController.reverse());
    _pulseController.forward().then((_) => _pulseController.reverse());

    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      _showOperatorMenu();
    }
  }

  void _handleLongPress() {
    _switchNextOperator();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _voiceService,
      builder: (context, _) {
        final operator = _voiceService.currentOperator;

        return GestureDetector(
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _floatController,
              _breathController,
              _pulseController,
              _tapController,
            ]),
            builder: (context, child) {
              final floatOffset = _floatAnimation.value;
              final breathScale = _breathAnimation.value;
              final pulseScale = _pulseAnimation.value;
              final tapScale = _tapAnimation.value;

              // 添加轻微的随机旋转
              final randomRotation =
                  math.sin(_floatController.value * 0.1) * 0.05;

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.rotate(
                  angle: randomRotation,
                  child: Transform.scale(
                    scale: breathScale * pulseScale * tapScale,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            operator.themeColor.withValues(alpha: 0.8),
                            operator.themeColor.withValues(alpha: 0.4),
                            operator.themeColor.withValues(alpha: 0.1),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        border: Border.all(
                          color: operator.themeColor.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: operator.themeColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: operator.themeColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            // 头像
                            _buildAvatar(operator.avatarAssetPath),
                            // 活跃指示器
                            if (_voiceService.isEnabled)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // 脉冲效果
                            if (_pulseController.isAnimating)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: operator.themeColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String path) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: _voiceService.currentOperator.themeColor.withValues(
            alpha: 0.2,
          ),
          child: Icon(
            Icons.support_agent,
            size: 32,
            color: _voiceService.currentOperator.themeColor,
          ),
        );
      },
    );
  }

  void _switchNextOperator() {
    // 添加切换时的脉冲效果
    _pulseController.forward().then((_) => _pulseController.reverse());

    final currentIndex = defaultOperators.indexOf(
      _voiceService.currentOperator,
    );
    final nextIndex = (currentIndex + 1) % defaultOperators.length;
    _voiceService.setOperator(defaultOperators[nextIndex]);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${defaultOperators[nextIndex].name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showOperatorMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_voice,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Operator Settings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _voiceService.isEnabled ? Icons.volume_up : Icons.volume_off,
                  color: _voiceService.isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: const Text('Voice Guidance'),
                subtitle: Text(
                  _voiceService.isEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: Switch(
                  value: _voiceService.isEnabled,
                  onChanged: (_) {
                    _voiceService.toggleEnabled();
                    // 添加切换时的微动画
                    _pulseController.forward().then(
                      (_) => _pulseController.reverse(),
                    );
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Operator:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: defaultOperators.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final op = defaultOperators[index];
                  final isSelected = op.id == _voiceService.currentOperator.id;

                  return GestureDetector(
                    onTap: () {
                      _voiceService.setOperator(op);
                      _pulseController.forward().then(
                        (_) => _pulseController.reverse(),
                      );
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      transform: Matrix4.diagonal3Values(
                        isSelected ? 1.1 : 1.0,
                        isSelected ? 1.1 : 1.0,
                        1.0,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        op.themeColor.withValues(alpha: 0.8),
                                        op.themeColor.withValues(alpha: 0.4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              border: Border.all(
                                color: isSelected
                                    ? op.themeColor
                                    : Theme.of(context).colorScheme.outline
                                          .withValues(alpha: 0.3),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: op.themeColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                op.avatarAssetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: op.themeColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: op.themeColor,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            op.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? op.themeColor
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
