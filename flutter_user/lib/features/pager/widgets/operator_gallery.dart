import 'package:flutter/material.dart';
import 'package:bipupu/features/assistant/assistant_config.dart';
import 'package:bipupu/features/assistant/intent_driven_assistant_controller.dart';

class OperatorGallery extends StatefulWidget {
  const OperatorGallery({super.key});

  @override
  State<OperatorGallery> createState() => _OperatorGalleryState();
}

class _OperatorGalleryState extends State<OperatorGallery> {
  final int totalSlots = 6;
  final IntentDrivenAssistantController _assistant =
      IntentDrivenAssistantController();
  final AssistantConfig _config = AssistantConfig();

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
    final defaultOperators = _config.defaultOperators;
    final List<Widget> cards = [];
    for (var i = 0; i < totalSlots; i++) {
      if (i < defaultOperators.length) {
        final op = defaultOperators[i];
        final selected = op.id == _assistant.currentOperatorId;
        cards.add(_buildOperatorCard(context, op, selected));
      } else {
        cards.add(_buildEmptySlotCard(context, i));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('选择接线员'), centerTitle: true),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: cards,
      ),
    );
  }

  Widget _buildOperatorCard(
    BuildContext context,
    VirtualOperator op,
    bool selected,
  ) {
    return Card(
      elevation: selected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? op.themeColor : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectOperator(op),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: op.themeColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: op.themeColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    op.name.isNotEmpty ? op.name[0] : 'O',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: op.themeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                op.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selected ? op.themeColor : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                op.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: op.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '已选择',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: op.themeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlotCard(BuildContext context, int index) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showComingSoonDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 32, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '空位',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '敬请期待',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectOperator(VirtualOperator op) {
    _assistant.setOperator(op.id);
    Navigator.of(context).pop();
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('敬请期待'),
        content: const Text('更多接线员正在开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
