import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_cubit.dart';
import '../models/operator_model.dart';

class ConnectingPage extends StatefulWidget {
  final OperatorPersonality? assignedOperator;

  const ConnectingPage({super.key, this.assignedOperator});

  @override
  State<ConnectingPage> createState() => _ConnectingPageState();
}

class _ConnectingPageState extends State<ConnectingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // 接线员名 / 通用提示
            Text(
              widget.assignedOperator?.name ?? 'BIPUPU',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '正在连接传呼服务...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const Spacer(),

            // 呼叫波纹动画
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRipple(colorScheme, 0),
                    _buildRipple(colorScheme, 0.5),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.phone_in_talk,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            // 挂断按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FloatingActionButton.large(
                onPressed: () {
                  context.read<PagerCubit>().cancelDialing();
                },
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.call_end),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRipple(ColorScheme colorScheme, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = ((_controller.value + delay) % 1.0);
        final opacity = (1.0 - value).clamp(0.0, 1.0);
        final scale = 1.0 + (value * 1.5);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
