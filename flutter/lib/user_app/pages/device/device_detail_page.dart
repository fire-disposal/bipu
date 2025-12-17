import 'package:flutter/material.dart';

class DeviceDetailPage extends StatelessWidget {
  const DeviceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 示例数据
    const deviceName = 'pupu机001';
    const batteryLevel = 78;
    const isConnected = true;
    final receivedMessages = ['收到：你好，世界！', '收到：测试消息', '收到：设备状态正常'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 刷新设备状态
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                const Icon(Icons.devices, size: 40),
                const SizedBox(width: 12),
                const Text(
                  deviceName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: const Text(isConnected ? '已连接' : '未连接'),
                  backgroundColor: isConnected
                      ? Colors.green[100]
                      : Colors.red[100],
                  labelStyle: TextStyle(
                    color: isConnected ? Colors.green[800]! : Colors.red[800]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.battery_full, color: Colors.amber),
                SizedBox(width: 8),
                Text('电量：$batteryLevel%'),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('发送消息到设备'),
              onPressed: () {
                // 发送消息逻辑
              },
            ),
            const SizedBox(height: 24),
            Text('接收信息', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...receivedMessages.map(
              (msg) => ListTile(
                leading: const Icon(Icons.message),
                title: Text(msg),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text('断开连接'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
              onPressed: () {
                // 断开连接逻辑
              },
            ),
          ],
        ),
      ),
    );
  }
}
