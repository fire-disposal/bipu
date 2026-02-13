import 'package:flutter/material.dart';
import 'package:flutter_user/core/services/bluetooth_device_service.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({super.key});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () async {
              final currentContext = context;
              await _bluetoothService.disconnect();
              if (mounted) {
                Navigator.of(currentContext).pop();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter message to forward',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _bluetoothService.forwardMessage(_messageController.text);
                  _messageController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message sent!')),
                  );
                }
              },
              child: const Text('Forward to Device'),
            ),
            const Divider(height: 40),
            ElevatedButton(
              onPressed: () {
                _bluetoothService.syncTime();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Time sync command sent!')),
                );
              },
              child: const Text('Sync Time'),
            ),
          ],
        ),
      ),
    );
  }
}
