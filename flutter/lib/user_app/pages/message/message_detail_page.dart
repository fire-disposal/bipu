import 'package:flutter/material.dart';

class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息详情')),
      body: const Center(child: Text('Message Detail Page')),
    );
  }
}
