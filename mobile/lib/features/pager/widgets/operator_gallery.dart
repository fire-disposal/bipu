import 'package:flutter/material.dart';
import 'package:flutter_user/features/assistant/assistant_config.dart';
import 'package:flutter_user/features/assistant/assistant_controller.dart';

class OperatorGallery extends StatefulWidget {
  const OperatorGallery({super.key});

  @override
  State<OperatorGallery> createState() => _OperatorGalleryState();
}

class _OperatorGalleryState extends State<OperatorGallery> {
  final int totalSlots = 6;
  final AssistantController _assistant = AssistantController();

  @override
  void initState() {
    super.initState();
    _assistant.addListener(_onAssistantUpdate);
  }

  void _onAssistantUpdate() => setState(() {});

  @override
  void dispose() {
    _assistant.removeListener(_onAssistantUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [];
    for (var i = 0; i < totalSlots; i++) {
      if (i < defaultOperators.length) {
        final op = defaultOperators[i];
        final selected = op.id == _assistant.currentOperatorId;
        cards.add(_buildOperatorCard(context, op, selected));
      } else {
        cards.add(_buildLockedCard(context));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择接线员'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择您的接线员',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '不同的接线员提供独特的语音风格和功能',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: cards,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(
    BuildContext context,
    VirtualOperator op,
    bool selected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _assistant.setOperator(op.id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已选择接线员: ${op.name}')));
      },
      onLongPress: () => _showOperatorDialog(context, op),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? op.themeColor.withOpacity(0.06)
              : Theme.of(context).colorScheme.surface,
          border: selected ? Border.all(color: op.themeColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: op.themeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: op.themeColor.withOpacity(0.18)),
              ),
              alignment: Alignment.center,
              child: Text(
                op.name.isNotEmpty ? op.name[0] : 'O',
                style: TextStyle(
                  color: op.themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              op.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              op.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此接线员尚未解锁'))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '未解锁',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '完成任务后可解锁',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showOperatorDialog(BuildContext context, VirtualOperator op) {
    showDialog<void>(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: op.themeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  op.name.isNotEmpty ? op.name[0] : 'O',
                  style: TextStyle(
                    color: op.themeColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                op.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                op.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(c).pop(),
                    child: const Text('返回'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _assistant.setOperator(op.id);
                      Navigator.of(c).pop();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('已选择 ${op.name}')));
                    },
                    child: const Text('选择'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
