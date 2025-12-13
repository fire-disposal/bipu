/// BLE 数据模型
/// 定义蓝牙相关的数据模型
library;

/// 蓝牙设备模型
class BleDevice {
  final String id;
  final String name;
  final String? manufacturerData;
  final int rssi;
  final bool isConnected;
  final DateTime lastSeen;

  BleDevice({
    required this.id,
    required this.name,
    this.manufacturerData,
    required this.rssi,
    this.isConnected = false,
    required this.lastSeen,
  });

  /// 从 JSON 创建
  factory BleDevice.fromJson(Map<String, dynamic> json) {
    return BleDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturerData: json['manufacturerData'] as String?,
      rssi: json['rssi'] as int,
      isConnected: json['isConnected'] as bool? ?? false,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturerData': manufacturerData,
      'rssi': rssi,
      'isConnected': isConnected,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  /// 复制对象
  BleDevice copyWith({
    String? id,
    String? name,
    String? manufacturerData,
    int? rssi,
    bool? isConnected,
    DateTime? lastSeen,
  }) {
    return BleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturerData: manufacturerData ?? this.manufacturerData,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  String toString() {
    return 'BleDevice(id: $id, name: $name, rssi: $rssi, isConnected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// BLE 服务模型
class BleService {
  final String uuid;
  final List<BleCharacteristic> characteristics;
  final bool isPrimary;

  BleService({
    required this.uuid,
    required this.characteristics,
    this.isPrimary = true,
  });

  /// 从 JSON 创建
  factory BleService.fromJson(Map<String, dynamic> json) {
    return BleService(
      uuid: json['uuid'] as String,
      characteristics: (json['characteristics'] as List)
          .map((e) => BleCharacteristic.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPrimary: json['isPrimary'] as bool? ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'characteristics': characteristics.map((e) => e.toJson()).toList(),
      'isPrimary': isPrimary,
    };
  }
}

/// BLE 特征模型
class BleCharacteristic {
  final String uuid;
  final List<String> properties;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;
  final bool canIndicate;

  BleCharacteristic({
    required this.uuid,
    required this.properties,
    this.canRead = false,
    this.canWrite = false,
    this.canNotify = false,
    this.canIndicate = false,
  });

  /// 从 JSON 创建
  factory BleCharacteristic.fromJson(Map<String, dynamic> json) {
    final properties = (json['properties'] as List).cast<String>();
    return BleCharacteristic(
      uuid: json['uuid'] as String,
      properties: properties,
      canRead: properties.contains('read'),
      canWrite:
          properties.contains('write') ||
          properties.contains('writeWithoutResponse'),
      canNotify: properties.contains('notify'),
      canIndicate: properties.contains('indicate'),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'uuid': uuid, 'properties': properties};
  }
}

/// BLE 扫描结果模型
class BleScanResult {
  final BleDevice device;
  final List<String> serviceUuids;
  final Map<String, dynamic> manufacturerData;
  final DateTime timestamp;

  BleScanResult({
    required this.device,
    required this.serviceUuids,
    required this.manufacturerData,
    required this.timestamp,
  });

  /// 从 JSON 创建
  factory BleScanResult.fromJson(Map<String, dynamic> json) {
    return BleScanResult(
      device: BleDevice.fromJson(json['device'] as Map<String, dynamic>),
      serviceUuids: (json['serviceUuids'] as List).cast<String>(),
      manufacturerData: json['manufacturerData'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'serviceUuids': serviceUuids,
      'manufacturerData': manufacturerData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// BLE 连接状态枚举
enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// BLE 连接信息模型
class BleConnectionInfo {
  final BleDevice device;
  final BleConnectionState state;
  final DateTime connectionTime;
  final DateTime? disconnectionTime;
  final String? errorMessage;

  BleConnectionInfo({
    required this.device,
    required this.state,
    required this.connectionTime,
    this.disconnectionTime,
    this.errorMessage,
  });

  /// 从 JSON 创建
  factory BleConnectionInfo.fromJson(Map<String, dynamic> json) {
    return BleConnectionInfo(
      device: BleDevice.fromJson(json['device'] as Map<String, dynamic>),
      state: BleConnectionState.values[json['state'] as int],
      connectionTime: DateTime.parse(json['connectionTime'] as String),
      disconnectionTime: json['disconnectionTime'] != null
          ? DateTime.parse(json['disconnectionTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'state': state.index,
      'connectionTime': connectionTime.toIso8601String(),
      'disconnectionTime': disconnectionTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// 复制对象
  BleConnectionInfo copyWith({
    BleDevice? device,
    BleConnectionState? state,
    DateTime? connectionTime,
    DateTime? disconnectionTime,
    String? errorMessage,
  }) {
    return BleConnectionInfo(
      device: device ?? this.device,
      state: state ?? this.state,
      connectionTime: connectionTime ?? this.connectionTime,
      disconnectionTime: disconnectionTime ?? this.disconnectionTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
