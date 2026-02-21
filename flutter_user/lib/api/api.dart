// 核心API客户端
export 'core/api_client.dart';
export 'core/exceptions.dart';
export 'core/token_storage.dart';

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
