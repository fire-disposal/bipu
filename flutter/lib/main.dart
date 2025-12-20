import 'app_user/main.dart' as app_user;
import 'app_admin/main.dart' as app_admin;

/// 应用启动选择器
/// 根据运行参数决定启动用户端还是管理端
void main() {
  // 获取启动参数
  const String appType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'user',
  );

  if (appType == 'admin') {
    app_admin.main();
  } else {
    app_user.main();
  }
}
