/// 统一的蓝牙模块导�?
/// 提供简化的蓝牙操作接口
library bluetooth;

// 核心管道
export 'ble_pipeline.dart' show BlePipeline;

// 简化UI组件
export 'ble_simple_ui.dart'
    show
        SimpleBleState,
        SimpleBleDeviceInfo,
        SimpleBleDeviceListItem,
        SimpleBleStatusIndicator;

// 协议相关
export '../protocol/ble_protocol.dart'
    show ColorData, VibrationType, ScreenEffect, BleCommandType;
export '../protocol/ble_cts_protocol.dart'
    show
        BleCtsSyncState,
        BleCtsProtocol,
        BleCtsCurrentTime,
        BleCtsLocalTimeInfo;
