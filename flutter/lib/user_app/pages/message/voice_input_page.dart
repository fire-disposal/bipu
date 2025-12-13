import 'package:flutter/material.dart';

class VoiceInputPage extends StatelessWidget {
  const VoiceInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语音输入')),
      body: const Center(child: Text('Voice Input Page')),
    );
  }
}
