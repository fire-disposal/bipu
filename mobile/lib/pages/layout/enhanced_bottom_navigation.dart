import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/state/app_state_management.dart';
import '../../core/animations/animation_system.dart';
import '../../core/services/im_service.dart';

/// 优化的底部导航栏
class EnhancedBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onPagerLongPress;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onPagerLongPress,
  });

  @override
  State<EnhancedBottomNavigation> createState() =>
      _EnhancedBottomNavigationState();
}

class _EnhancedBottomNavigationState extends State<EnhancedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
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
        label: 'home_tab'.tr(),
        route: '/home',
      ),
      NavItem(
        index: 1,
        icon: Icons.mic_outlined,
        activeIcon: Icons.mic_rounded,
        label: 'pager_tab'.tr(),
        route: '/pager',
        isSpecial: true,
      ),
      NavItem(
        index: 2,
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'messages_tab'.tr(),
        route: '/messages',
        badge: _imService.unreadCount,
      ),
      NavItem(
        index: 3,
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'profile_tab'.tr(),
        route: '/profile',
      ),
    ];

    _selectionController = AnimationController(
      duration: AnimationConfig.normal,
      vsync: this,
    );

    _selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _selectionController,
        curve: AnimationConfig.easeOut,
      ),
    );

    _selectionController.forward();
  }

  @override
  void didUpdateWidget(EnhancedBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentIndex != oldWidget.currentIndex) {
      _selectionController.reset();
      _selectionController.forward();
    }
  }

  @override
  void dispose() {
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
    return _PagerNavButton(
      item: item,
      colorScheme: colorScheme,
      isSelected: isSelected,
      onTap: () => widget.onTap(item.index),
      onLongPressTriggered: widget.onPagerLongPress,
    );
  }
}

// ─────────────────────────────────────────────────────
//  传呼按钮（含蓄力环绕动画）
// ─────────────────────────────────────────────────────

class _PagerNavButton extends StatefulWidget {
  final NavItem item;
  final ColorScheme colorScheme;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPressTriggered;

  const _PagerNavButton({
    required this.item,
    required this.colorScheme,
    required this.isSelected,
    required this.onTap,
    this.onLongPressTriggered,
  });

  @override
  State<_PagerNavButton> createState() => _PagerNavButtonState();
}

class _PagerNavButtonState extends State<_PagerNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _charge;
  // 动画已走完并触发了长按动作
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _charge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _charge.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_fired) {
        _fired = true;
        // 触感反馈 + 触发长按动作
        HapticFeedback.heavyImpact();
        widget.onLongPressTriggered?.call();
        // 短暂停留后收回蓄力环
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) {
            _charge.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _charge.dispose();
    super.dispose();
  }

  /// 取消蓄力，动画回弹到 0
  void _cancelCharge() {
    if (!_fired) {
      _charge.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        // 使用 onTapDown/onTapUp/onTapCancel 替代 onLongPress* 系列，
        // 避免 Flutter 手势竞技场中 TapRecognizer 与 LongPressRecognizer 的冲突：
        //   - onTapDown  : 手指按下 → 启动蓄力动画
        //   - onTapUp    : 手指抬起 → 若动画未完成则视为短按（导航），否则忽略
        //   - onTapCancel: 手势取消（滑走等）→ 回弹动画
        onTapDown: (_) {
          _fired = false;
          _charge.forward(from: 0);
        },
        onTapUp: (_) {
          if (!_fired) {
            // 短按：回弹动画 + 执行导航
            _cancelCharge();
            widget.onTap();
          }
          // 若 _fired == true，长按已触发，什么都不做
        },
        onTapCancel: _cancelCharge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _charge,
              builder: (context, child) {
                final progress = _charge.value;
                final isActive = widget.isSelected || progress > 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 蓄力环（稍大于按钮，环绕一圈）
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                        color: widget.colorScheme.primary,
                        backgroundColor: progress > 0
                            ? widget.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                    ),
                    // 核心按钮（随蓄力程度增强发光）
                    AnimatedContainer(
                      duration: AnimationConfig.normal,
                      curve: AnimationConfig.easeOut,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.colorScheme.primary
                            : widget.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: widget.colorScheme.primary.withValues(
                                    alpha: 0.2 + progress * 0.25,
                                  ),
                                  blurRadius: 8 + progress * 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: AnimatedSwitcher(
                        duration: AnimationConfig.fast,
                        child: Icon(
                          widget.isSelected
                              ? widget.item.activeIcon
                              : widget.item.icon,
                          key: ValueKey(widget.isSelected),
                          color: isActive
                              ? widget.colorScheme.onPrimary
                              : widget.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AnimationConfig.normal,
              style: TextStyle(
                color: widget.isSelected
                    ? widget.colorScheme.primary
                    : widget.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                fontSize: 10,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
              child: Text(widget.item.label),
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
