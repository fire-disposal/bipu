import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/speech_recognition_service.dart';

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final TextEditingController _textController = TextEditingController();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  StreamSubscription<String>? _speechSubscription;

  // Local history for demo purposes
  final List<String> _sentMessages = [];

  String? _selectedOperator;
  final List<String> _operators = [
    'Operator A',
    'Operator B',
    'Operator C',
    'Bot X',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing buffer if any
    _textController.text = _speechService.currentText;

    // Listen for live updates
    _speechSubscription = _speechService.onResult.listen((text) {
      if (mounted) {
        setState(() {
          _textController.text = text;
          // Keep cursor at end if user is not editing somewhere else?
          // For simplicity, just jump to end.
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Simulate sending
    setState(() {
      _sentMessages.insert(0, text); // Add to history
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message sent!')));

    _textController.clear();
    _speechService.clearBuffer();
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pager Station'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clear Buffer',
            onPressed: () {
              _speechService.clearBuffer();
              _textController.clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Operator Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Operator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _operators.length,
                    itemBuilder: (context, index) {
                      final op = _operators[index];
                      final isSelected = _selectedOperator == op;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOperator = op;
                          });
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1)
                                : Colors.grey[200],
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.support_agent, size: 40),
                              const SizedBox(height: 5),
                              Text(op, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Interaction Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // History Area (Small)
                  if (_sentMessages.isNotEmpty) ...[
                    const Text(
                      'Recent History:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _sentMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${_sentMessages[index]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                  ],

                  const Text(
                    'Message Buffer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Hold "Pager" tab to speak, or type here...',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Message'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
