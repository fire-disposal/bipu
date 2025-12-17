/// 手环设备控制页面
/// 用于编辑和发送包含RGB灯光、震动和文本的消息到蓝牙设备
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bipupu_flutter/core/ble/ble_protocol.dart';
import 'package:bipupu_flutter/core/ble/device_control_service.dart';
import 'package:bipupu_flutter/core/widgets/core_widgets.dart';
import 'package:bipupu_flutter/core/utils/injected_dependencies.dart';
import 'package:bipupu_flutter/user_app/state/device_control_state.dart';

class DeviceControlPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const DeviceControlPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late DeviceControlCubit _cubit;

  // 当前选择的配置
  List<RgbColor> _selectedColors = [RgbColor.colorBlue];
  VibrationPattern _vibrationPattern = VibrationPattern.medium;
  VibrationIntensity _vibrationIntensity = VibrationIntensity.medium;
  int _duration = 3000;

  @override
  void initState() {
    super.initState();
    // 使用依赖注入的服务创建Cubit
    final deviceControlService = get<DeviceControlService>();
    _cubit = DeviceControlCubit(deviceControlService: deviceControlService);
    // 连接到设备
    _cubit.connectToDevice(widget.deviceId, widget.deviceName);
  }

  @override
  void dispose() {
    _textController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('控制 ${widget.deviceName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => context.push('/device-test'),
            tooltip: '协议测试',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeviceInfo,
          ),
        ],
      ),
      body: BlocConsumer<DeviceControlCubit, DeviceControlState>(
        listener: (context, state) {
          if (state is MessageSent) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('消息发送成功')));
          }
        },
        builder: (context, state) {
          if (state is DeviceConnecting) {
            return const Center(
              child: CoreLoadingIndicator(message: '正在连接设备...'),
            );
          }

          if (state is DeviceDisconnected) {
            return Center(
              child: CoreErrorWidget(
                message: '设备连接失败，请返回重新连接',
                onRetry: () => context.pop(),
                retryText: '返回',
              ),
            );
          }

          if (state is MessageSending) {
            return const Center(
              child: CoreLoadingIndicator(message: '正在发送消息...'),
            );
          }

          return _buildControlPanel(state);
        },
      ),
    );
  }

  Widget _buildControlPanel(DeviceControlState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 连接状态
            _buildConnectionStatus(state),
            const SizedBox(height: 24),

            // 文本消息
            _buildTextInput(),
            const SizedBox(height: 24),

            // RGB颜色选择
            _buildColorSelection(),
            const SizedBox(height: 24),

            // 震动设置
            _buildVibrationSettings(),
            const SizedBox(height: 24),

            // 持续时间
            _buildDurationSetting(),
            const SizedBox(height: 32),

            // 快速预设
            _buildQuickPresets(),
            const SizedBox(height: 24),

            // 发送按钮
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(DeviceControlState state) {
    if (state is DeviceConnected) {
      return CoreCard(
        child: ListTile(
          leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
          title: Text('已连接: ${state.deviceName}'),
          subtitle: Text('设备ID: ${state.deviceId}'),
          trailing: IconButton(
            icon: const Icon(Icons.battery_std),
            onPressed: _checkBatteryLevel,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextInput() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '消息内容',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textController,
              maxLines: 3,
              maxLength: 64,
              decoration: const InputDecoration(
                hintText: '输入要发送到手环的消息...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入消息内容';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelection() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RGB灯光颜色',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildColorOption(RgbColor.colorRed, '红色'),
                _buildColorOption(RgbColor.colorGreen, '绿色'),
                _buildColorOption(RgbColor.colorBlue, '蓝色'),
                _buildColorOption(RgbColor.colorYellow, '黄色'),
                _buildColorOption(RgbColor.colorPurple, '紫色'),
                _buildColorOption(RgbColor.colorCyan, '青色'),
                _buildColorOption(RgbColor.colorWhite, '白色'),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedColors.length > 1)
              Text(
                '已选择 ${_selectedColors.length} 种颜色',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(RgbColor color, String label) {
    final isSelected = _selectedColors.contains(color);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedColors.remove(color);
            if (_selectedColors.isEmpty) {
              _selectedColors.add(RgbColor.colorBlue); // 默认颜色
            }
          } else {
            _selectedColors.add(color);
          }
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Color.fromRGBO(color.red, color.green, color.blue, 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: _isColorDark(color) ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  bool _isColorDark(RgbColor color) {
    final brightness =
        (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness < 128;
  }

  Widget _buildVibrationSettings() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '震动设置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<VibrationPattern>(
                    value: _vibrationPattern,
                    decoration: const InputDecoration(
                      labelText: '震动模式',
                      border: OutlineInputBorder(),
                    ),
                    items: VibrationPattern.values.map((pattern) {
                      return DropdownMenuItem(
                        value: pattern,
                        child: Text(_getVibrationPatternName(pattern)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _vibrationPattern = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<VibrationIntensity>(
                    value: _vibrationIntensity,
                    decoration: const InputDecoration(
                      labelText: '震动强度',
                      border: OutlineInputBorder(),
                    ),
                    items: VibrationIntensity.values.map((intensity) {
                      return DropdownMenuItem(
                        value: intensity,
                        child: Text(_getVibrationIntensityName(intensity)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _vibrationIntensity = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSetting() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '持续时间',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _duration.toDouble(),
              min: 1000,
              max: 10000,
              divisions: 9,
              label: '${(_duration / 1000).toStringAsFixed(1)}秒',
              onChanged: (value) {
                setState(() {
                  _duration = value.round();
                });
              },
            ),
            Text(
              '持续时间: ${(_duration / 1000).toStringAsFixed(1)}秒',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPresets() {
    return CoreCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速预设',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton(
                  '通知提醒',
                  Icons.notifications,
                  () => _applyPreset(_notificationPreset()),
                ),
                _buildPresetButton(
                  '紧急提醒',
                  Icons.warning,
                  () => _applyPreset(_urgentPreset()),
                ),
                _buildPresetButton(
                  '彩虹效果',
                  Icons.auto_awesome,
                  () => _applyPreset(_rainbowPreset()),
                ),
                _buildPresetButton(
                  '温馨提醒',
                  Icons.favorite,
                  () => _applyPreset(_gentlePreset()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendMessage,
        icon: const Icon(Icons.send),
        label: const Text('发送到手环'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedColors.isEmpty) return;

    final cubit = context.read<DeviceControlCubit>();
    cubit.sendRgbSequence(
      colors: _selectedColors,
      text: _textController.text,
      vibration: _vibrationPattern,
      intensity: _vibrationIntensity,
      duration: _duration,
    );
  }

  void _checkBatteryLevel() async {
    final batteryLevel = await context
        .read<DeviceControlCubit>()
        .getBatteryLevel();
    if (mounted && batteryLevel != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('设备电量: $batteryLevel%')));
    }
  }

  void _showDeviceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('设备名称: ${widget.deviceName}'),
            Text('设备ID: ${widget.deviceId}'),
            const SizedBox(height: 8),
            const Text('协议版本: 1.0'),
            const Text('支持功能: RGB灯光、震动、文本显示'),
          ],
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

  // 预设配置
  Map<String, dynamic> _notificationPreset() {
    return {
      'colors': [RgbColor.colorBlue],
      'vibration': VibrationPattern.short,
      'intensity': VibrationIntensity.medium,
      'duration': 2000,
      'text': '新消息提醒',
    };
  }

  Map<String, dynamic> _urgentPreset() {
    return {
      'colors': [RgbColor.colorRed, RgbColor.colorRed, RgbColor.colorRed],
      'vibration': VibrationPattern.triple,
      'intensity': VibrationIntensity.high,
      'duration': 5000,
      'text': '紧急提醒！',
    };
  }

  Map<String, dynamic> _rainbowPreset() {
    return {
      'colors': [
        RgbColor.colorRed,
        RgbColor.colorGreen,
        RgbColor.colorBlue,
        RgbColor.colorYellow,
        RgbColor.colorPurple,
        RgbColor.colorCyan,
      ],
      'vibration': VibrationPattern.medium,
      'intensity': VibrationIntensity.medium,
      'duration': 4000,
      'text': '彩虹效果',
    };
  }

  Map<String, dynamic> _gentlePreset() {
    return {
      'colors': [RgbColor.colorGreen],
      'vibration': VibrationPattern.short,
      'intensity': VibrationIntensity.low,
      'duration': 2500,
      'text': '温馨提醒',
    };
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _selectedColors = preset['colors'] as List<RgbColor>;
      _vibrationPattern = preset['vibration'] as VibrationPattern;
      _vibrationIntensity = preset['intensity'] as VibrationIntensity;
      _duration = preset['duration'] as int;
      _textController.text = preset['text'] as String;
    });
  }

  String _getVibrationPatternName(VibrationPattern pattern) {
    switch (pattern) {
      case VibrationPattern.none:
        return '无震动';
      case VibrationPattern.short:
        return '短震动';
      case VibrationPattern.medium:
        return '中等震动';
      case VibrationPattern.long:
        return '长震动';
      case VibrationPattern.double:
        return '双震动';
      case VibrationPattern.triple:
        return '三震动';
      case VibrationPattern.custom:
        return '自定义';
    }
  }

  String _getVibrationIntensityName(VibrationIntensity intensity) {
    switch (intensity) {
      case VibrationIntensity.low:
        return '低';
      case VibrationIntensity.medium:
        return '中';
      case VibrationIntensity.high:
        return '高';
    }
  }
}
