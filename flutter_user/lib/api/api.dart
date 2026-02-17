/// 新的API层入口文件
/// 导出所有API相关的类和函数

// 核心API客户端
export 'core/api_client.dart';
export 'core/exceptions.dart';

// API服务
export 'api_service.dart';

// 具体的API类
export 'auth_api.dart';
export 'message_api.dart';
export 'contact_api.dart';
export 'user_api.dart';
export 'block_api.dart';
export 'service_account_api.dart';

// 工具扩展
extension ApiEnum on Enum {
  String get apiValue => name;
}
