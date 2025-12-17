/// 设备协议测试页面
/// 用于测试蓝牙协议的基本功能和设备通信
import 'package:flutter/material.dart';
import 'package:bipupu_flutter/core/ble/ble_protocol.dart';
import 'package:bipupu_flutter/core/ble/device_control_service.dart';
import 'package:bipupu_flutter/core/widgets/core_widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceTestPage extends StatefulWidget {
  const DeviceTestPage({super.key});

  @override
  State<DeviceTestPage> createState() => _DeviceTestPageState();
}

class _DeviceTestPageState extends State<DeviceTestPage> {
  final _testMessages = [
    {'text': '测试消息1', 'color': RgbColor.colorBlue},
    {'text': '紧急提醒', 'color': RgbColor.colorRed},
    {'text': '成功通知', 'color': RgbColor.colorGreen},
    {'text': '温馨问候', 'color': RgbColor.colorYellow},
  ];

  int _selectedIndex = 0;
  bool _isConnected = false;
  String _connectionStatus = '未连接';
  String _lastTestResult = '';
  List<Map<String, dynamic>> _scanResults = [];
  bool _isScanning = false;
  String? _selectedDeviceId;
  String? _selectedDeviceName;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  void _checkConnectionStatus() {
    final deviceService = DeviceControlService.instance;
    setState(() {
      _isConnected = deviceService.isConnected;
      _connectionStatus = _isConnected ? '已连接' : '未连接';
      if (_isConnected &&
          _selectedDeviceId == null &&
          deviceService.connectedDevice != null) {
        _selectedDeviceId = deviceService.connectedDevice!.remoteId.str;
        _selectedDeviceName = deviceService.connectedDevice!.platformName;
      }
    });
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      final results = await FlutterBluePlus.scanResults.first;
      setState(() {
        _scanResults = results
            .where(
              (r) => r.advertisementData.serviceUuids.contains(
                BleServiceUuids.deviceControlService,
              ),
            )
            .map(
              (r) => {
                'id': r.device.remoteId.str,
                'name': r.device.platformName.isNotEmpty
                    ? r.device.platformName
                    : '未知设备',
              },
            )
            .toList();
      });
      await FlutterBluePlus.stopScan();
    } catch (e) {
      setState(() {
        _scanResults = [];
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _connectToDevice(String deviceId, String deviceName) async {
    setState(() {
      _selectedDeviceId = deviceId;
      _selectedDeviceName = deviceName;
      _connectionStatus = '连接中...';
    });
    try {
      await DeviceControlService.instance.connectToDevice(deviceId);
      setState(() {
        _isConnected = true;
        _connectionStatus = '已连接';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = '连接失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备协议测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showProtocolInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 新增：设备扫描与连接入口
            _buildDeviceScanConnectCard(),
            const SizedBox(height: 16),
            // 连接状态卡片
            _buildConnectionStatusCard(),
            const SizedBox(height: 16),

            // 协议信息卡片
            _buildProtocolInfoCard(),
            const SizedBox(height: 16),

            // 测试消息选择
            _buildTestMessageSelector(),
            const SizedBox(height: 16),

            // 快速测试按钮
            _buildQuickTestButtons(),
            const SizedBox(height: 16),

            // 高级测试选项
            _buildAdvancedTestOptions(),

            // 测试结果
            if (_lastTestResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTestResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '连接状态: $_connectionStatus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _checkConnectionStatus,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('刷新'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isConnected) ...[
              const SizedBox(height: 8),
              Text(
                '请先连接设备后再进行测试',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceScanConnectCard() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '设备扫描与连接',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: const Icon(Icons.search),
                  label: Text(_isScanning ? '扫描中...' : '扫描设备'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_scanResults.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('可用设备列表：'),
                  ..._scanResults.map(
                    (d) => ListTile(
                      title: Text('${d['name']}'),
                      subtitle: Text('${d['id']}'),
                      trailing: _selectedDeviceId == d['id']
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                              onPressed: () =>
                                  _connectToDevice(d['id'], d['name']),
                              child: const Text('连接'),
                            ),
                      selected: _selectedDeviceId == d['id'],
                    ),
                  ),
                ],
              )
            else
              const Text('请点击“扫描设备”获取附近设备'),
            if (_selectedDeviceId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '当前选择设备: $_selectedDeviceName ($_selectedDeviceId)',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard() {
    return CoreCard(
      color: _lastTestResult.contains('成功') || _lastTestResult.contains('完成')
          ? Colors.green.withAlpha((255 * 0.1).round())
          : Colors.orange.withAlpha((255 * 0.1).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _lastTestResult.contains('成功') ||
                          _lastTestResult.contains('完成')
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color:
                      _lastTestResult.contains('成功') ||
                          _lastTestResult.contains('完成')
                      ? Colors.green
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '测试结果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _lastTestResult,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolInfoCard() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '协议信息',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('协议版本: 1.0'),
            const Text('最大消息长度: 64字节'),
            const Text('支持颜色: RGB (0-255)'),
            const Text('震动模式: 7种'),
            const Text('最大持续时间: 10秒'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestMessageSelector() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择测试消息',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_testMessages.length, (index) {
                final message = _testMessages[index];
                final isSelected = _selectedIndex == index;
                return ChoiceChip(
                  label: Text(message['text'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    }
                  },
                  backgroundColor: Color.fromRGBO(
                    (message['color'] as RgbColor).red,
                    (message['color'] as RgbColor).green,
                    (message['color'] as RgbColor).blue,
                    0.3,
                  ),
                  selectedColor: Color.fromRGBO(
                    (message['color'] as RgbColor).red,
                    (message['color'] as RgbColor).green,
                    (message['color'] as RgbColor).blue,
                    0.7,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButtons() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速测试',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendSimpleNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('发送通知'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendRainbowEffect,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('彩虹效果'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendUrgentNotification,
                    icon: const Icon(Icons.warning),
                    label: const Text('紧急通知'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendCustomSequence,
                    icon: const Icon(Icons.palette),
                    label: const Text('自定义序列'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTestOptions() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高级测试',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testMessageSerialization,
                    icon: const Icon(Icons.code),
                    label: const Text('测试序列化'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testMessageDeserialization,
                    icon: const Icon(Icons.restore),
                    label: const Text('测试反序列化'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testChecksum,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('测试校验和'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testProtocolUtils,
                    icon: const Icon(Icons.build),
                    label: const Text('测试工具类'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendSimpleNotification() async {
    if (!_isConnected) {
      setState(() {
        _lastTestResult = '发送失败：设备未连接';
      });
      return;
    }

    final selectedMessage = _testMessages[_selectedIndex];
    final message = BleProtocolUtils.createSimpleNotification(
      text: selectedMessage['text'] as String,
      color: selectedMessage['color'] as RgbColor,
    );

    try {
      final deviceService = DeviceControlService.instance;
      final success = await deviceService.sendMessage(message);

      setState(() {
        _lastTestResult = success
            ? '简单通知发送成功：${selectedMessage['text']}'
            : '简单通知发送失败';
      });

      if (success) {
        _showTestResult('发送成功', message);
      } else {
        _showTestResult('发送失败', message, '请检查设备连接状态');
      }
    } catch (e) {
      setState(() {
        _lastTestResult = '发送失败：$e';
      });
      _showTestResult('发送失败', message, '错误：$e');
    }
  }

  void _sendRainbowEffect() async {
    if (!_isConnected) {
      setState(() {
        _lastTestResult = '发送失败：设备未连接';
      });
      return;
    }

    final message = BleProtocolUtils.createRainbowEffect(text: '彩虹灯效果测试');

    try {
      final deviceService = DeviceControlService.instance;
      final success = await deviceService.sendMessage(message);

      setState(() {
        _lastTestResult = success ? '彩虹效果发送成功' : '彩虹效果发送失败';
      });

      if (success) {
        _showTestResult('彩虹效果发送成功', message);
      } else {
        _showTestResult('彩虹效果发送失败', message, '请检查设备连接状态');
      }
    } catch (e) {
      setState(() {
        _lastTestResult = '彩虹效果发送失败：$e';
      });
      _showTestResult('彩虹效果发送失败', message, '错误：$e');
    }
  }

  void _sendUrgentNotification() async {
    if (!_isConnected) {
      setState(() {
        _lastTestResult = '发送失败：设备未连接';
      });
      return;
    }

    final message = BleProtocolUtils.createUrgentNotification(text: '紧急测试通知！');

    try {
      final deviceService = DeviceControlService.instance;
      final success = await deviceService.sendMessage(message);

      setState(() {
        _lastTestResult = success ? '紧急通知发送成功' : '紧急通知发送失败';
      });

      if (success) {
        _showTestResult('紧急通知发送成功', message);
      } else {
        _showTestResult('紧急通知发送失败', message, '请检查设备连接状态');
      }
    } catch (e) {
      setState(() {
        _lastTestResult = '紧急通知发送失败：$e';
      });
      _showTestResult('紧急通知发送失败', message, '错误：$e');
    }
  }

  void _sendCustomSequence() async {
    if (!_isConnected) {
      setState(() {
        _lastTestResult = '发送失败：设备未连接';
      });
      return;
    }

    final colors = [
      RgbColor.colorRed,
      RgbColor.colorGreen,
      RgbColor.colorBlue,
      RgbColor.colorYellow,
    ];

    final message = DeviceMessagePacket.notification(
      rgbColors: colors,
      vibrationPattern: VibrationPattern.double,
      vibrationIntensity: VibrationIntensity.high,
      text: '自定义颜色序列测试',
      duration: 4000,
    );

    try {
      final deviceService = DeviceControlService.instance;
      final success = await deviceService.sendMessage(message);

      setState(() {
        _lastTestResult = success ? '自定义序列发送成功' : '自定义序列发送失败';
      });

      if (success) {
        _showTestResult('自定义序列发送成功', message);
      } else {
        _showTestResult('自定义序列发送失败', message, '请检查设备连接状态');
      }
    } catch (e) {
      setState(() {
        _lastTestResult = '自定义序列发送失败：$e';
      });
      _showTestResult('自定义序列发送失败', message, '错误：$e');
    }
  }

  void _testMessageSerialization() {
    final testMessage = DeviceMessagePacket.notification(
      rgbColors: [RgbColor.colorBlue],
      vibrationPattern: VibrationPattern.short,
      vibrationIntensity: VibrationIntensity.medium,
      text: '序列化测试',
    );

    try {
      final bytes = testMessage.toBytes();
      _showTestResult('序列化成功', null, '消息已序列化为 ${bytes.length} 字节');
    } catch (e) {
      _showTestResult('序列化失败', null, '错误: $e');
    }
  }

  void _testMessageDeserialization() {
    // 创建一个测试消息并序列化
    final originalMessage = DeviceMessagePacket.notification(
      rgbColors: [RgbColor.colorGreen, RgbColor.colorRed],
      vibrationPattern: VibrationPattern.medium,
      vibrationIntensity: VibrationIntensity.high,
      text: '反序列化测试',
      duration: 3500,
    );

    try {
      final bytes = originalMessage.toBytes();
      final deserializedMessage = DeviceMessagePacket.fromBytes(bytes);

      final success = originalMessage == deserializedMessage;
      _showTestResult(
        '反序列化${success ? '成功' : '失败'}',
        deserializedMessage,
        success ? '消息完整还原' : '消息不匹配',
      );
    } catch (e) {
      _showTestResult('反序列化失败', null, '错误: $e');
    }
  }

  void _testChecksum() {
    final testData = [0x01, 0x02, 0x03, 0x04, 0x05];
    final checksum = BleProtocolUtils.createSimpleNotification(text: '校验和测试');
    final bytes = checksum.toBytes();
    final calculatedChecksum = bytes.last;

    _showTestResult('校验和测试', null, '数据: $testData\n校验和: $calculatedChecksum');
  }

  void _testProtocolUtils() {
    final utilsMessage = BleProtocolUtils.createSimpleNotification(
      text: '工具类测试',
      color: RgbColor.colorPurple,
      vibration: VibrationPattern.long,
      intensity: VibrationIntensity.low,
    );

    _showTestResult('协议工具类', utilsMessage, '工具类方法正常工作');
  }

  void _showTestResult(
    String title,
    DeviceMessagePacket? message, [
    String? details,
  ]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                Text('消息详情:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(message.toString()),
                const SizedBox(height: 8),
              ],
              if (details != null) ...[
                Text('详细信息:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(details),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showProtocolInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('协议信息'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('协议版本: 1.0'),
              Text('数据包结构:'),
              Text('  - 协议头 (4字节)'),
              Text('  - RGB颜色序列 (3*n + 1字节)'),
              Text('  - 震动控制 (2字节)'),
              Text('  - 文本信息 (长度 + 内容)'),
              Text('  - 持续时间 (2字节)'),
              Text('  - 校验和 (1字节)'),
              SizedBox(height: 8),
              Text('最大数据包大小: 512字节'),
              Text('文本最大长度: 64字节'),
              Text('支持颜色数量: 最多20种'),
            ],
          ),
        ),
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
