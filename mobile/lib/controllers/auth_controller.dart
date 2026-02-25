import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../models/user_model.dart';

/// 极简认证控制器 - 使用新的AuthService
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // 依赖服务
  final AuthService _auth = AuthService.instance;
  final TokenService _token = TokenService.instance;

  // UI状态
  final username = ''.obs;
  final password = ''.obs;
  final showPassword = false.obs;
  final RxString error = ''.obs;

  // 计算属性
  bool get canLogin => username.value.isNotEmpty && password.value.isNotEmpty;
  bool get isLoggedIn {
    final loggedIn = _auth.isLoggedIn.value;
    print('🔍 AuthController.isLoggedIn getter: $loggedIn');
    return loggedIn;
  }

  bool get isLoading => _auth.isLoading.value;
  UserModel? get currentUser => _auth.currentUser.value;
  bool get hasValidToken => _token.hasValidToken.value;

  /// 登录（直接调用AuthService）
  Future<void> login() async {
    print('🔐 AuthController.login() 被调用');

    // 先验证表单
    if (!validateForm()) {
      print('❌ AuthController: 表单验证失败');
      return;
    }

    error.value = '';
    print('🔐 调用AuthService.login()');
    final response = await _auth.login(username.value, password.value);

    print('🔐 AuthService.login() 返回: success=${response.success}');
    if (response.success) {
      print('✅ AuthController: 登录成功，清空表单');
      // 登录成功，清空表单
      clearForm();
      print('✅ AuthController: 准备跳转到首页');
      // 使用延迟确保状态完全更新
      await Future.delayed(const Duration(milliseconds: 50));
      Get.offAllNamed('/');
      print('✅ AuthController: 跳转指令已发送');
    } else if (response.error != null) {
      error.value = response.error!.message;
      print('❌ AuthController: 登录失败: ${error.value}');
    }
  }

  /// 直接登录（供页面调用）
  Future<void> directLogin(String username, String password) async {
    print('🔐 AuthController.directLogin() 被调用');
    error.value = '';
    final response = await _auth.login(username, password);

    if (response.success) {
      print('✅ AuthController.directLogin: 登录成功');
      // 登录成功
      clearForm();
    } else if (response.error != null) {
      error.value = response.error!.message;
      print('❌ AuthController.directLogin: 登录失败: ${error.value}');
    }
  }

  /// 注册
  Future<void> register({String? nickname}) async {
    if (username.value.isEmpty) {
      error.value = '请输入用户名';
      // 使用安全的方式显示错误消息
      Future.microtask(() {
        if (Get.isSnackbarOpen) {
          Get.back();
        }
        Get.snackbar('提示', error.value);
      });
      return;
    }

    if (password.value.isEmpty) {
      error.value = '请输入密码';
      // 使用安全的方式显示错误消息
      Future.microtask(() {
        if (Get.isSnackbarOpen) {
          Get.back();
        }
        Get.snackbar('提示', error.value);
      });
      return;
    }

    error.value = '';
    final response = await _auth.register(
      username.value,
      password.value,
      nickname: nickname,
    );

    if (response.success) {
      // 注册成功，清空表单
      clearForm();
      Get.back(); // 返回登录页
    } else if (response.error != null) {
      error.value = response.error!.message;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed('/login');
  }

  /// 强制刷新Token
  Future<bool> forceRefreshToken() async {
    return await _token.forceRefreshToken();
  }

  /// 检查Token是否即将过期
  Future<bool> isTokenAboutToExpire() async {
    return await _token.isTokenAboutToExpire();
  }

  /// 获取Token剩余时间
  Future<int> getTokenRemainingTime() async {
    return await _token.getTokenRemainingTime();
  }

  /// 检查认证状态
  Future<void> checkAuthStatus() async {
    print('🔍 AuthController.checkAuthStatus() 被调用');
    await _auth.checkAuthStatus();
    print('🔍 AuthController.checkAuthStatus() 完成: isLoggedIn=$isLoggedIn');
  }

  /// 验证表单
  bool validateForm() {
    if (username.value.isEmpty) {
      error.value = '请输入用户名';
      return false;
    }

    if (password.value.isEmpty) {
      error.value = '请输入密码';
      return false;
    }

    if (username.value.length < 3) {
      error.value = '用户名至少3个字符';
      return false;
    }

    if (password.value.length < 6) {
      error.value = '密码至少6个字符';
      return false;
    }

    error.value = '';
    return true;
  }

  /// 清空表单
  void clearForm() {
    username.value = '';
    password.value = '';
    error.value = '';
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  /// 设置用户名
  void setUsername(String value) {
    username.value = value;
  }

  /// 设置密码
  void setPassword(String value) {
    password.value = value;
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    print('🚀 AuthController.onInit() 被调用');
    checkAuthStatus();
  }

  /// 重置所有状态
  void resetAll() {
    username.value = '';
    password.value = '';
    showPassword.value = false;
    error.value = '';
  }
}
