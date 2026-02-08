# 蓝牙固件参考文档 - 简化版

本文档为固件工程师提供Flutter应用中蓝牙通信相关的关键代码摘要。**注意：RGB颜色传讯功能已移除**，简化协议以提升稳定性和性能。

## 1. 蓝牙服务和特征值UUID

```dart
// 主要服务UUID
static const String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static const String writeCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
static const String notifyCharUuid = "6E400004-B5A3-F393-E0A9-E50E24DCCA9E";

// 标准电池服务
static const String batteryServiceUuid = "180F";
static const String batteryLevelCharUuid = "2A19";
```

## 2. 电量信息传输

### 2.1 电量服务发现和处理

```dart
Future<void> readBatteryLevel() async {
  if (!_isConnected) return;

  try {
    final services = await _bluetoothDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().toUpperCase() == BleConstants.batteryServiceUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase() == BleConstants.batteryLevelCharUuid) {
            final value = await characteristic.read();
            if (value.isNotEmpty) {
              final batteryLevel = value[0]; // 0-100
              debugPrint('Battery Level: $batteryLevel%');
              // Update UI or store the battery level
            }
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Failed to read battery level: $e');
  }
}
```

### 2.2 电量数据格式
- **数据类型**: 单字节无符号整数 (Uint8)
- **数值范围**: 0-100 (表示电量百分比)
- **更新方式**: 支持主动读取和通知订阅

## 3. 时间同步功能

### 3.1 时间同步协议

```dart
/// 时间同步
Future<void> syncTime() async {
  if (!_isConnected) {
    throw Exception('Device not connected');
  }

  final now = DateTime.now();
  final packet = _createTimeSyncPacket(now);
  await sendData(packet);
  debugPrint('Time synchronized: ${now.hour}:${now.minute}');
}

List<int> _createTimeSyncPacket(DateTime time) {
  final packet = BytesBuilder();
  packet.addByte(BleConstants.cmdTimeSync);  // 命令类型: 0x02
  packet.addByte(time.hour);                 // 小时 (0-23)
  packet.addByte(time.minute);               // 分钟 (0-59)
  packet.addByte(time.second);               // 秒钟 (0-59)
  packet.addByte(time.weekday - 1);          // 星期 (0-6, 0=周一)
  
  final bytes = packet.toBytes();
  int checksum = 0;
  for (final byte in bytes) {
    checksum += byte.toInt();
  }
  packet.addByte(checksum & 0xFF);           // 校验和

  return packet.toBytes();
}
```

### 3.2 时间同步数据格式

| 字节位置 | 字段 | 长度 | 说明 |
|---------|------|------|------|
| 0 | 命令类型 | 1 | 0x02 (时间同步命令) |
| 1 | 小时 | 1 | 0-23 |
| 2 | 分钟 | 1 | 0-59 |
| 3 | 秒钟 | 1 | 0-59 |
| 4 | 星期 | 1 | 0-6 (0=周一, 6=周日) |
| 5 | 校验和 | 1 | 前面所有字节的和 & 0xFF |

## 4. 消息发送协议（简化版）

### 4.1 主要数据发送接口

```dart
/// 发送协议消息 - 简化版（移除RGB颜色功能）
Future<void> sendMessage({
  VibrationType vibration = VibrationType.none,
  ScreenEffect screenEffect = ScreenEffect.none,
  String text = '',
}) async {
  final packet = BleProtocol.createPacket(
    vibration: vibration,
    screenEffect: screenEffect,
    text: text,
  );

  await sendData(packet);
}
```

### 4.2 简化的协议数据格式

| 字节位置 | 字段 | 长度 | 说明 |
|---------|------|------|------|
| 0 | 协议版本 | 1 | 0x01 |
| 1 | 命令类型 | 1 | 0x01 (消息命令) |
| 2-3 | 序列号 | 2 | Little Endian |
| 4 | 震动模式 | 1 | 0x00-0x04 |
| 5 | 震动强度 | 1 | 固定为 1 |
| 6 | 文本长度 | 1 | 0-64 字节 |
| 7+(n-1) | 文本内容 | n | UTF-8 编码，最大64字节 |
| 7+n | 屏幕效果 | 1 | 0x00-0x03 |
| 8+n | 校验和 | 1 | 前面所有字节的和 & 0xFF |

### 4.3 震动类型枚举

```dart
enum VibrationType {
  none(0x00),      // 无震动
  standard(0x01),  // 标准震动
  urgent(0x02),    // 紧急震动
  gentle(0x03),    // 轻柔震动
  notification(0x04); // 通知震动
}
```

### 4.4 屏幕效果枚举

```dart
enum ScreenEffect {
  none(0x00),      // 无效果
  scroll(0x01),    // 滚动
  blink(0x02),     // 闪烁
  breathing(0x03); // 呼吸效果
}
```

### 4.5 数据发送重试机制

```dart
/// 发送数据 - 统一的数据发送接口
Future<void> sendData(List<int> data) async {
  if (!_isConnected) {
    throw Exception("Device not connected");
  }

  final writeCharacteristic = await _findWriteCharacteristic();
  if (writeCharacteristic == null) {
    throw Exception("Write characteristic not found");
  }

  // 重试机制
  const maxRetries = 3;
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await writeCharacteristic.write(data, withoutResponse: true);
      debugPrint('Data sent successfully');
      return;
    } catch (e) {
      if (attempt == maxRetries) {
        throw Exception('Failed to send data after $maxRetries attempts: $e');
      }
      await Future.delayed(Duration(milliseconds: 100 * attempt));
    }
  }
}
```

## 5. 固件实现建议

### 5.1 电量服务实现
1. 实现标准的蓝牙电池服务 (0x180F)
2. 电池电量特征值 (0x2A19) 支持读取和通知
3. 电量值以百分比形式返回 (0-100)

### 5.2 时间同步实现
1. 监听自定义服务 (6E400001-B5A3-F393-E0A9-E50E24DCCA9E) 的写入特征值
2. 解析时间同步命令 (0x02)
3. 验证校验和并更新设备时间
4. 可选择在时间同步成功后发送确认响应

### 5.3 消息处理实现
1. 解析简化的消息协议（已移除RGB颜色字段）
2. 根据震动类型执行相应的震动模式
3. 在屏幕上显示文本内容，应用屏幕效果
4. 验证校验和确保数据完整性

### 5.4 连接稳定性
1. 实现心跳机制保持连接活跃
2. 支持自动重连功能
3. 合理的超时处理和错误恢复

## 6. 调试建议

1. **电量监控**: 实现电量低警告通知
2. **时间同步确认**: 可选择发送同步成功确认包
3. **错误处理**: 对无效命令或数据格式返回错误响应
4. **日志记录**: 记录关键操作便于调试
5. **性能优化**: 协议简化后减少数据传输量，提升响应速度

## 7. 重要更新说明

- **移除RGB颜色传讯**: 为简化协议和提升性能，已完全移除RGB灯光颜色传讯功能
- **协议简化**: 减少数据包大小，提高传输效率和稳定性
- **专注核心功能**: 专注于文本显示、震动和屏幕效果，保持功能实用性

---

*本文档基于简化后的Flutter应用代码生成，如有更新请及时同步。*