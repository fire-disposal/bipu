import 'package:flutter/material.dart';

class DeviceBindingPage extends StatelessWidget {
  const DeviceBindingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备绑定')),
      body: const Center(child: Text('Device Binding Page')),
    );
  }
}
