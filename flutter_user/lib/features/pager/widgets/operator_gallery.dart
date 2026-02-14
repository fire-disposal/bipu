import 'package:flutter/material.dart';
import 'package:flutter_user/features/assistant/assistant_config.dart';
import 'package:flutter_user/features/assistant/assistant_controller.dart';
// VoiceGuideService calls removed — use AssistantController for operator state

class OperatorGallery extends StatefulWidget {
  const OperatorGallery({super.key});

  @override
  State<OperatorGallery> createState() => _OperatorGalleryState();
}

class _OperatorGalleryState extends State<OperatorGallery> {
  // total slots (3 per row * 2 rows)
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
    // Prepare list of items: unlocked from defaultOperators, remainder locked placeholders
    final List<Widget> cards = [];
    for (var i = 0; i < totalSlots; i++) {
      if (i < defaultOperators.length) {
        final op = defaultOperators[i];
        final selected = op.id == _assistant.currentOperatorId;
        cards.add(_buildCard(context, op, false, selected));
      } else {
        cards.add(_buildLockedCard(context));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('选择接线员'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: cards,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    VirtualOperator op,
    bool locked,
    bool selected,
  ) {
    return GestureDetector(
      onTap: () {
        _showDetail(context, op);
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: op.themeColor.withOpacity(0.06),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    color: op.themeColor.withOpacity(0.08),
                    border: selected
                        ? Border.all(color: op.themeColor, width: 2)
                        : null,
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
                const SizedBox(height: 8),
                Text(
                  op.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  op.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.check_circle,
                    color: op.themeColor,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('此接线员尚未解锁')));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock, size: 36, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text('未解锁', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              '完成任务后可解锁',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, VirtualOperator op) {
    showDialog(
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
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                op.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(op.description, textAlign: TextAlign.center),
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
                      // select operator: delegate to AssistantController
                      _assistant.setOperator(op.id);
                      Navigator.of(c).pop();
                      Navigator.of(context).pop(); // close gallery
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
