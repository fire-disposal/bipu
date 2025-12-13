import 'package:flutter/material.dart';

class ExportPrintPage extends StatelessWidget {
  const ExportPrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导出/打印')),
      body: const Center(child: Text('Export/Print Page')),
    );
  }
}
