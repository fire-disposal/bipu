import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repos/auth_repo.dart';
import '../shared/models/user_model.dart';

/// 极简认证控制器 - GetX风格
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // 状态
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final user = Rxn<UserModel>();
  final error = ''.obs;

  // 仓库
  final AuthRepo _repo = AuthRepo();

  /// 登录
  Future<void> login(String username, String password) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.login(username, password);

      if (result['success'] == true) {
        // 保存token
        final prefs = await SharedPreferences.getInstance();
        final data = result['data'] as Map<String, dynamic>;

        await prefs.setString('access_token', data['access_token'] as String);
        if (data['refresh_token'] != null) {
          await prefs.setString(
            'refresh_token',
            data['refresh_token'] as String,
          );
        }
        if (data['expires_in'] != null) {
          final expiry =
              DateTime.now().millisecondsSinceEpoch ~/ 1000 +
              (data['expires_in'] as num).toInt();
          await prefs.setInt('token_expiry', expiry);
        }

        // 获取用户信息
        await loadUser();

        Get.snackbar('成功', '登录成功！');
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '登录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 注册
  Future<void> register(
    String username,
    String password, {
    String? nickname,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.register(
        username,
        password,
        nickname: nickname,
      );

      if (result['success'] == true) {
        Get.snackbar('成功', '注册成功！请登录');
        Get.back(); // 返回登录页
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '注册失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载用户信息
  Future<void> loadUser() async {
    try {
      final result = await _repo.getCurrentUser();

      if (result['success'] == true) {
        user.value = UserModel.fromJson(result['data'] as Map<String, dynamic>);
        isLoggedIn.value = true;
      } else {
        // token可能失效，尝试刷新
        await tryRefreshToken();
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  /// 尝试刷新token
  Future<void> tryRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken != null && refreshToken.isNotEmpty) {
      final result = await _repo.refreshToken(refreshToken);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;

        await prefs.setString('access_token', data['access_token'] as String);
        if (data['refresh_token'] != null) {
          await prefs.setString(
            'refresh_token',
            data['refresh_token'] as String,
          );
        }
        if (data['expires_in'] != null) {
          final expiry =
              DateTime.now().millisecondsSinceEpoch ~/ 1000 +
              (data['expires_in'] as num).toInt();
          await prefs.setInt('token_expiry', expiry);
        }

        await loadUser();
      } else {
        await logout();
      }
    } else {
      await logout();
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // 忽略登出API错误
    }

    // 清除本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');

    // 重置状态
    isLoggedIn.value = false;
    user.value = null;
    error.value = '';

    Get.snackbar('成功', '已登出');
  }

  /// 检查登录状态
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final expiry = prefs.getInt('token_expiry');

    if (token != null && token.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (expiry != null && expiry > now) {
        // token有效，加载用户
        await loadUser();
      } else {
        // token过期，尝试刷新
        await tryRefreshToken();
      }
    }
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }
}
