import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/pager_vm.dart';

/// 新架构通话中视图
class NewInCallView extends StatelessWidget {
  const NewInCallView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagerVM>();
    final cs = Theme.of(context).colorScheme;
    final op = vm.operator;
    final themeColor = op?.themeColor ?? cs.primary;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部状态栏
            _buildTopBar(cs, themeColor),
            
            // 接线员信息区域（可滚动）
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildOperatorInfo(context, op, cs),
                    const Spacer(flex: 2),
                    _buildInputArea(vm, cs, themeColor),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, Color themeColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.12), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('通话中', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.signal_cellular_4_bar, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildOperatorInfo(BuildContext context, dynamic op, ColorScheme cs) {
    if (op == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 立绘
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                op.portraitUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: cs.surfaceContainerHighest),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 名字
          Text(op.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // 台词
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '请输入目标用户号码',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(PagerVM vm, ColorScheme cs, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 目标 ID 输入框
          TextField(
            onChanged: (v) => vm.updateTargetId(v),
            decoration: InputDecoration(
              hintText: '目标用户号码',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 确认按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: vm.isConfirming ? null : () => vm.confirmTargetId(),
              icon: const Icon(Icons.check),
              label: const Text('确认号码'),
              style: FilledButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
