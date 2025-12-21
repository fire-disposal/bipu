// lib/core/api/auth_service.dart
import 'package:openapi/openapi.dart';
import 'api_service.dart'; // 包含 CoreApi.client 的那个文件

class AuthService {
  // 单例模式，匹配你 UI 中的调用：AuthService.instance
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  /// 核心登录逻辑
  Future<bool> login(
    String username,
    String password, {
    bool adminOnly = false,
  }) async {
    try {
      // 1. 使用生成的 Body 类创建请求对象 (built_value 风格)
      // 注意：具体的类名取决于你 Swagger 里的定义，通常是 LoginRequest
      final loginBody = BodyLoginLoginPost(
        (b) => b
          ..username = username
          ..password = password,
      );

      // 2. 调用生成的 API 方法
      final response = await CoreApi.client.getAuthApi().loginLoginPost(
        bodyLoginLoginPost: loginBody,
      );

      // 3. 假设后端返回一个包含 access_token 的对象
      final token = response.data?.accessToken;

      if (token != null) {
        // 4. 将 Token 存入全局 Dio 拦截器或持久化存储
        _handleLoginSuccess(token);
        return true;
      }
      return false;
    } catch (e) {
      print('登录异常: $e');
      rethrow; // 抛出异常让 UI 的 catch 捕获并显示 SnackBar
    }
  }

  void _handleLoginSuccess(String token) {
    // 设置全局 Token，这样后续所有请求都会自动带上
    // 之前我们建议用拦截器，这里是直接设置生成的 SDK 内部的认证方式
    CoreApi.client.setBearerAuth('HTTPBearer', token);

    // TODO: 使用 shared_preferences 存到本地，防止刷新掉登录
  }
}
