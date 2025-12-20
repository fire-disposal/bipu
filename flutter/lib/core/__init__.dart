/// Core 模块初始化文件
/// 包含应用的核心功能，供 app_user 和 app_admin 共用
///
/// 主要功能：
/// - API 通信
/// - BLE 蓝牙连接
/// - 数据模型定义
/// - 状态管理
/// - 消息处理
/// - 通知管理
/// - 工具函数
/// - 页面基础组件
/// - 仪表板组件
library;

export 'api/api.dart';
export 'ble/ble.dart';
export 'models/models.dart';
export 'state/state.dart';
export 'utils/utils.dart';
export 'utils/logger.dart';
