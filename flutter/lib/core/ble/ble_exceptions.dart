/// BLE 异常定义
/// 定义各种蓝牙相关的异常类型
library;

/// 基础 BLE 异常
class BleException implements Exception {
  final String message;
  final dynamic data;

  BleException({required this.message, this.data});

  @override
  String toString() => 'BleException: $message';
}

/// 蓝牙未开启异常
class BluetoothNotEnabledException extends BleException {
  BluetoothNotEnabledException({super.message = '蓝牙未开启'});
}

/// 蓝牙权限异常
class BluetoothPermissionException extends BleException {
  BluetoothPermissionException({super.message = '蓝牙权限不足'});
}

/// 设备未找到异常
class DeviceNotFoundException extends BleException {
  DeviceNotFoundException({super.message = '设备未找到'});
}

/// 设备连接异常
class DeviceConnectionException extends BleException {
  DeviceConnectionException({super.message = '设备连接失败'});
}

/// 设备断开异常
class DeviceDisconnectionException extends BleException {
  DeviceDisconnectionException({super.message = '设备断开连接'});
}

/// 服务发现异常
class ServiceDiscoveryException extends BleException {
  ServiceDiscoveryException({super.message = '服务发现失败'});
}

/// 特征发现异常
class CharacteristicDiscoveryException extends BleException {
  CharacteristicDiscoveryException({super.message = '特征发现失败'});
}

/// 数据发送异常
class DataSendException extends BleException {
  DataSendException({super.message = '数据发送失败'});
}

/// 数据接收异常
class DataReceiveException extends BleException {
  DataReceiveException({super.message = '数据接收失败'});
}

/// 扫描异常
class ScanException extends BleException {
  ScanException({super.message = '设备扫描失败'});
}

/// 配对异常
class PairingException extends BleException {
  PairingException({super.message = '设备配对失败'});
}

/// 不支持的设备异常
class UnsupportedDeviceException extends BleException {
  UnsupportedDeviceException({super.message = '不支持的设备类型'});
}

/// 设备已连接异常
class DeviceAlreadyConnectedException extends BleException {
  DeviceAlreadyConnectedException({super.message = '设备已连接'});
}

/// 设备未连接异常
class DeviceNotConnectedException extends BleException {
  DeviceNotConnectedException({super.message = '设备未连接'});
}
