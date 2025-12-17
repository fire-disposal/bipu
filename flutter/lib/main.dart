import 'main_user.dart' as user_app;
import 'main_admin.dart' as admin_app;

/// 应用启动选择器
/// 根据运行参数决定启动用户端还是管理端
void main() {
  // 获取启动参数
  const String appType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'user',
  );

  if (appType == 'admin') {
    admin_app.main();
  } else {
    user_app.main();
  }
}
