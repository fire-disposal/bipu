/// 设备数据模型
/// 定义设备相关的数据结构
library;

/// 设备模型
class Device {
  final String id;
  final String name;
  final String? model;
  final String? manufacturer;
  final String? serialNumber;
  final String? firmwareVersion;
  final DeviceType type;
  final DeviceStatus status;
  final String? userId;
  final DateTime? lastConnectionTime;
  final DateTime? lastSyncTime;
  final DeviceBatteryInfo? batteryInfo;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Device({
    required this.id,
    required this.name,
    this.model,
    this.manufacturer,
    this.serialNumber,
    this.firmwareVersion,
    this.type = DeviceType.pupu,
    this.status = DeviceStatus.offline,
    this.userId,
    this.lastConnectionTime,
    this.lastSyncTime,
    this.batteryInfo,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 创建
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      model: json['model'] as String?,
      manufacturer: json['manufacturer'] as String?,
      serialNumber: json['serial_number'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      type: DeviceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviceType.pupu,
      ),
      status: DeviceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeviceStatus.offline,
      ),
      userId: json['user_id'] as String?,
      lastConnectionTime: json['last_connection_time'] != null
          ? DateTime.parse(json['last_connection_time'] as String)
          : null,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'] as String)
          : null,
      batteryInfo: json['battery_info'] != null
          ? DeviceBatteryInfo.fromJson(
              json['battery_info'] as Map<String, dynamic>,
            )
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'manufacturer': manufacturer,
      'serial_number': serialNumber,
      'firmware_version': firmwareVersion,
      'type': type.name,
      'status': status.name,
      'user_id': userId,
      'last_connection_time': lastConnectionTime?.toIso8601String(),
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'battery_info': batteryInfo?.toJson(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 复制对象
  Device copyWith({
    String? id,
    String? name,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? firmwareVersion,
    DeviceType? type,
    DeviceStatus? status,
    String? userId,
    DateTime? lastConnectionTime,
    DateTime? lastSyncTime,
    DeviceBatteryInfo? batteryInfo,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      type: type ?? this.type,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      lastConnectionTime: lastConnectionTime ?? this.lastConnectionTime,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      batteryInfo: batteryInfo ?? this.batteryInfo,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 设备类型枚举
enum DeviceType {
  pupu, // pupu机
  cosmos, // cosmos设备
  gateway, // 网关设备
  sensor, // 传感器
  actuator, // 执行器
  other, // 其他
}

/// 设备状态枚举
enum DeviceStatus {
  online, // 在线
  offline, // 离线
  connecting, // 连接中
  error, // 错误
  maintenance, // 维护中
  updating, // 更新中
}

/// 设备电池信息模型
class DeviceBatteryInfo {
  final int? level; // 电量百分比 (0-100)
  final bool? isCharging;
  final DateTime? lastUpdated;

  DeviceBatteryInfo({this.level, this.isCharging, this.lastUpdated});

  /// 从 JSON 创建
  factory DeviceBatteryInfo.fromJson(Map<String, dynamic> json) {
    return DeviceBatteryInfo(
      level: json['level'] as int?,
      isCharging: json['is_charging'] as bool?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'is_charging': isCharging,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  /// 获取电池状态描述
  String get batteryStatus {
    if (level == null) return '未知';
    if (level! <= 20) return '低电量';
    if (level! <= 50) return '中等电量';
    if (level! <= 80) return '充足电量';
    return '满电';
  }

  /// 是否需要充电
  bool get needsCharging => level != null && level! <= 20;
}

/// 设备配置模型
class DeviceConfig {
  final String deviceId;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> calibration;
  final DateTime updatedAt;

  DeviceConfig({
    required this.deviceId,
    required this.settings,
    required this.calibration,
    required this.updatedAt,
  });

  /// 从 JSON 创建
  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    return DeviceConfig(
      deviceId: json['device_id'] as String,
      settings: json['settings'] as Map<String, dynamic>,
      calibration: json['calibration'] as Map<String, dynamic>,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'settings': settings,
      'calibration': calibration,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// 设备统计数据模型
class DeviceStats {
  final String deviceId;
  final int totalMessagesSent;
  final int totalMessagesReceived;
  final int totalConnections;
  final int totalSyncTime;
  final double averageBatteryLevel;
  final DateTime lastCalculated;

  DeviceStats({
    required this.deviceId,
    required this.totalMessagesSent,
    required this.totalMessagesReceived,
    required this.totalConnections,
    required this.totalSyncTime,
    required this.averageBatteryLevel,
    required this.lastCalculated,
  });

  /// 从 JSON 创建
  factory DeviceStats.fromJson(Map<String, dynamic> json) {
    return DeviceStats(
      deviceId: json['device_id'] as String,
      totalMessagesSent: json['total_messages_sent'] as int,
      totalMessagesReceived: json['total_messages_received'] as int,
      totalConnections: json['total_connections'] as int,
      totalSyncTime: json['total_sync_time'] as int,
      averageBatteryLevel: (json['average_battery_level'] as num).toDouble(),
      lastCalculated: DateTime.parse(json['last_calculated'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'total_messages_sent': totalMessagesSent,
      'total_messages_received': totalMessagesReceived,
      'total_connections': totalConnections,
      'total_sync_time': totalSyncTime,
      'average_battery_level': averageBatteryLevel,
      'last_calculated': lastCalculated.toIso8601String(),
    };
  }
}
