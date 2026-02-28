import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';

class DialingPrepPageMinimal extends StatefulWidget {
  final PagerCubit cubit;

  const DialingPrepPageMinimal({super.key, required this.cubit});

  @override
  State<DialingPrepPageMinimal> createState() => _DialingPrepPageMinimalState();
}

class _DialingPrepPageMinimalState extends State<DialingPrepPageMinimal>
    with SingleTickerProviderStateMixin {
  late TextEditingController _idController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- 逻辑处理 ---
  void _handleNumpadInput(String digit) {
    if (_idController.text.length < 12) {
      // 缩短长度限制，适配常见 ID
      setState(() => _idController.text += digit);
      widget.cubit.updateTargetId(_idController.text);
    }
  }

  void _handleBackspace() {
    if (_idController.text.isNotEmpty) {
      setState(() {
        _idController.text = _idController.text.substring(
          0,
          _idController.text.length - 1,
        );
      });
      widget.cubit.updateTargetId(_idController.text);
    }
  }

  void _handleClear() {
    setState(() => _idController.clear());
    widget.cubit.updateTargetId('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! DialingPrepState) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 1. 标题 (缩小)
                  Text(
                    '传呼',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 4,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 2. 目标显示区域 (精简尺寸)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TARGET ID',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _idController.text.isEmpty
                                ? '---'
                                : _idController.text,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              // 缩小字体
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 3. 紧凑拨号盘
                  _buildCompactNumpad(colorScheme),

                  const SizedBox(height: 24),

                  // 4. 拨号主按钮 (确保可见)
                  _buildMainDialButton(colorScheme, state, theme),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactNumpad(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double btnSize = 62.0; // 统一按钮大小
        final spacing = (constraints.maxWidth - (btnSize * 3)) / 2;

        return Column(
          children: [
            _buildNumpadRow(['1', '2', '3'], btnSize, spacing, colorScheme),
            _buildNumpadRow(['4', '5', '6'], btnSize, spacing, colorScheme),
            _buildNumpadRow(['7', '8', '9'], btnSize, spacing, colorScheme),
            _buildNumpadRow(
              ['clear', '0', 'backspace'],
              btnSize,
              spacing,
              colorScheme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildNumpadRow(
    List<String> labels,
    double size,
    double spacing,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.map((label) {
          bool isFunc = label == 'clear' || label == 'backspace';
          return InkWell(
            onTap: () {
              if (label == 'clear')
                _handleClear();
              else if (label == 'backspace')
                _handleBackspace();
              else
                _handleNumpadInput(label);
            },
            borderRadius: BorderRadius.circular(size),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFunc
                    ? Colors.transparent
                    : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isFunc
                      ? colorScheme.outlineVariant
                      : Colors.transparent,
                ),
              ),
              child: Center(child: _getLabelWidget(label, colorScheme)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getLabelWidget(String label, ColorScheme colorScheme) {
    if (label == 'backspace')
      return Icon(
        Icons.backspace_outlined,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      );
    if (label == 'clear')
      return Icon(
        Icons.delete_sweep_outlined,
        size: 22,
        color: colorScheme.error.withOpacity(0.7),
      );
    return Text(
      label,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildMainDialButton(
    ColorScheme colorScheme,
    PagerState state,
    ThemeData theme,
  ) {
    bool isLoading = state is DialingPrepState && state.isLoading;
    return InkWell(
      onTap: isLoading
          ? null
          : () => widget.cubit.startDialing(_idController.text.trim()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56, // 缩小高度
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.call, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '开始传呼',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
