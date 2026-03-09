import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/pager_vm.dart';

/// 新架构确认视图
class NewReviewingView extends StatelessWidget {
  const NewReviewingView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagerVM>();
    final cs = Theme.of(context).colorScheme;
    final op = vm.operator;
    final themeColor = op?.themeColor ?? cs.primary;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // 标题
              Text(
                '确认消息',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 目标号码
              _InfoChip(label: '目标号码', value: vm.targetId, cs: cs),
              const SizedBox(height: 12),
              // 消息内容
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vm.messageContent,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Spacer(),
              // 操作按钮
              OutlinedButton(
                onPressed: () => vm.backToVoiceInput(),
                child: const Text('重新录制'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: vm.isSending ? null : () => vm.sendMessage(),
                  icon: vm.isSending 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Icon(Icons.send),
                  label: Text(vm.isSending ? '发送中...' : '发送'),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  const _InfoChip({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
