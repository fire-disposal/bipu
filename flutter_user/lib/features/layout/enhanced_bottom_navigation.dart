import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/state/app_state_management.dart';
import '../../core/animations/animation_system.dart';
import '../../core/services/im_service.dart';

/// 优化的底部导航栏
class EnhancedBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onPagerLongPress;
  final VoidCallback? onPagerLongPressEnd;
  final bool isPagerListening;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onPagerLongPress,
    this.onPagerLongPressEnd,
    this.isPagerListening = false,
  });

  @override
  State<EnhancedBottomNavigation> createState() =>
      _EnhancedBottomNavigationState();
}

class _EnhancedBottomNavigationState extends State<EnhancedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _selectionController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _selectionAnimation;

  late List<NavItem> _navItems;
  late ImService _imService;

  @override
  void initState() {
    super.initState();

    _imService = ImService();
    _imService.addListener(_onImServiceChanged);

    _navItems = [
      NavItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: '首页',
        route: '/home',
      ),
      NavItem(
        index: 1,
        icon: Icons.mic_outlined,
        activeIcon: Icons.mic_rounded,
        label: '对讲',
        route: '/pager',
        isSpecial: true,
      ),
      NavItem(
        index: 2,
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble_rounded,
        label: '消息',
        route: '/messages',
        badge: _imService.unreadCount,
      ),
      NavItem(
        index: 3,
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: '我的',
        route: '/profile',
      ),
    ];

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: AnimationConfig.normal,
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _selectionController,
        curve: AnimationConfig.easeOut,
      ),
    );

    if (widget.currentIndex == 1 && widget.isPagerListening) {
      _breathingController.repeat(reverse: true);
    }

    _selectionController.forward();
  }

  @override
  void didUpdateWidget(EnhancedBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPagerListening != oldWidget.isPagerListening) {
      if (widget.isPagerListening) {
        _breathingController.repeat(reverse: true);
      } else {
        _breathingController.stop();
        _breathingController.reset();
      }
    }

    if (widget.currentIndex != oldWidget.currentIndex) {
      _selectionController.reset();
      _selectionController.forward();
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _selectionController.dispose();
    _imService.removeListener(_onImServiceChanged);
    super.dispose();
  }

  void _onImServiceChanged() {
    setState(() {
      _navItems[2] = _navItems[2].copyWith(badge: _imService.unreadCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<UiCubit, UiState>(
      builder: (context, uiState) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08,
                ),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.map((item) {
                  return _buildNavItem(context, item, colorScheme);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavItem item,
    ColorScheme colorScheme,
  ) {
    final isSelected = item.index == widget.currentIndex;
    final isSpecial = item.isSpecial;

    if (isSpecial) {
      return _buildSpecialNavItem(context, item, colorScheme, isSelected);
    }

    return _buildRegularNavItem(context, item, colorScheme, isSelected);
  }

  Widget _buildRegularNavItem(
    BuildContext context,
    NavItem item,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(item.index),
        child: AnimatedBuilder(
          animation: _selectionAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AnimationConfig.normal,
                  curve: AnimationConfig.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: AnimationConfig.fast,
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                          size: 24,
                        ),
                      ),
                      if (item.badge != null && item.badge! > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: AnimatedScale(
                            scale: isSelected ? 1.0 : 0.8,
                            duration: AnimationConfig.normal,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                item.badge!.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: AnimationConfig.normal,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(item.label),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecialNavItem(
    BuildContext context,
    NavItem item,
    ColorScheme colorScheme,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(item.index),
        onLongPressStart: (_) {
          if (isSelected) {
            widget.onPagerLongPress?.call();
          } else {
            widget.onTap(item.index);
          }
        },
        onLongPressEnd: (_) => widget.onPagerLongPressEnd?.call(),
        onLongPressCancel: () => widget.onPagerLongPressEnd?.call(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: widget.isPagerListening
                  ? _breathingAnimation
                  : _selectionAnimation,
              builder: (context, child) {
                final scale = widget.isPagerListening
                    ? _breathingAnimation.value
                    : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: AnimationConfig.normal,
                    curve: AnimationConfig.easeOut,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: isSelected || widget.isPagerListening
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: widget.isPagerListening ? 12 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.isPagerListening)
                          AnimatedBuilder(
                            animation: _breathingController,
                            builder: (context, child) {
                              return Container(
                                width: 48 * _breathingAnimation.value,
                                height: 48 * _breathingAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withValues(
                                    alpha:
                                        0.1 * (1 - _breathingController.value),
                                  ),
                                ),
                              );
                            },
                          ),
                        AnimatedSwitcher(
                          duration: AnimationConfig.fast,
                          child: Icon(
                            widget.isPagerListening
                                ? Icons.stop_rounded
                                : (isSelected ? item.activeIcon : item.icon),
                            key: ValueKey(
                              '${isSelected}_${widget.isPagerListening}',
                            ),
                            color: isSelected || widget.isPagerListening
                                ? colorScheme.onPrimary
                                : colorScheme.primary,
                            size: widget.isPagerListening ? 28 : 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AnimationConfig.normal,
              style: TextStyle(
                color: isSelected || widget.isPagerListening
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: isSelected || widget.isPagerListening
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
              child: Text(widget.isPagerListening ? '录音中' : item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// 导航项目模型
class NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isSpecial;
  final int? badge;

  const NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isSpecial = false,
    this.badge,
  });

  NavItem copyWith({
    int? index,
    IconData? icon,
    IconData? activeIcon,
    String? label,
    String? route,
    bool? isSpecial,
    int? badge,
  }) {
    return NavItem(
      index: index ?? this.index,
      icon: icon ?? this.icon,
      activeIcon: activeIcon ?? this.activeIcon,
      label: label ?? this.label,
      route: route ?? this.route,
      isSpecial: isSpecial ?? this.isSpecial,
      badge: badge ?? this.badge,
    );
  }
}
