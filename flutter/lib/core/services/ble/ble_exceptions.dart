/// BLE相关异常
library;

/// BLE基础异常
class BleException implements Exception {
  final String message;
  final String? deviceId;

  const BleException(this.message, [this.deviceId]);

  @override
  String toString() {
    return 'BleException: $message${deviceId != null ? ' (设备: $deviceId)' : ''}';
  }
}

/// 蓝牙不支持异常
class BluetoothNotSupportedException extends BleException {
  const BluetoothNotSupportedException([String? deviceId])
    : super('设备不支持蓝牙功能', deviceId);
}

/// 蓝牙未开启异常
class BluetoothNotEnabledException extends BleException {
  const BluetoothNotEnabledException([String? deviceId])
    : super('蓝牙未开启', deviceId);
}

/// 设备未找到异常
class DeviceNotFoundException extends BleException {
  const DeviceNotFoundException(String deviceId) : super('未找到指定设备', deviceId);
}

/// 设备连接失败异常
class DeviceConnectionException extends BleException {
  const DeviceConnectionException(String deviceId, String message)
    : super(message, deviceId);
}

/// 服务未找到异常
class ServiceNotFoundException extends BleException {
  const ServiceNotFoundException(String deviceId)
    : super('未找到设备控制服务', deviceId);
}

/// 特征值未找到异常
class CharacteristicNotFoundException extends BleException {
  const CharacteristicNotFoundException(
    String deviceId,
    String characteristicName,
  ) : super('未找到$characteristicName特征值', deviceId);
}

/// 消息发送失败异常
class MessageSendException extends BleException {
  const MessageSendException(String deviceId, String message)
    : super(message, deviceId);
}

/// 消息过大异常
class MessageTooLargeException extends BleException {
  const MessageTooLargeException(String deviceId, int messageSize)
    : super('消息过大 (大小: $messageSize)', deviceId);
}

/// 设备控制异常
class DeviceControlException extends BleException {
  const DeviceControlException(super.message, [super.deviceId]);
}
