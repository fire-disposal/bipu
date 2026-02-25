import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_service.dart';
import 'token_service.dart';
import '../models/user_model.dart';

/// 认证服务 - 替换AuthRepo
class AuthService extends BaseService {
  static AuthService get instance => Get.find();

  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxString error = ''.obs;

  // Token服务
  TokenService get _tokenService => Get.find<TokenService>();

  /// 登录
  Future<ServiceResponse<Token>> login(String username, String password) async {
    isLoading.value = true;
    error.value = '';

    final response = await post<Token>(
      '/api/public/login',
      data: {'username': username, 'password': password},
      fromJson: (json) => Token.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      // 保存Token到TokenService
      final token = response.data!;
      await _tokenService.saveTokens(token);

      // 加载用户信息
      await loadCurrentUser();

      Get.snackbar('成功', '登录成功！', duration: const Duration(seconds: 2));
      return ServiceResponse.success(token);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 注册
  Future<ServiceResponse<Map<String, dynamic>>> register(
    String username,
    String password, {
    String? nickname,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await post<Map<String, dynamic>>(
      '/api/public/register',
      data: {
        'username': username,
        'password': password,
        if (nickname != null) 'nickname': nickname,
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      Get.snackbar('成功', '注册成功！请登录');
      Get.back(); // 返回登录页
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 加载当前用户信息
  Future<void> loadCurrentUser() async {
    final response = await get<UserModel>(
      '/api/profile/me',
      fromJson: (json) => UserModel.fromJson(json),
    );

    if (response.success && response.data != null) {
      currentUser.value = response.data;
      isLoggedIn.value = true;
      error.value = '';
    } else {
      // 加载用户失败，可能是token过期
      if (response.error?.type == ServiceErrorType.unauthorized ||
          response.error?.type == ServiceErrorType.tokenExpired) {
        await logout();
      } else if (response.error != null) {
        error.value = response.error!.message;
      }
    }
  }

  /// 检查认证状态
  Future<void> checkAuthStatus() async {
    // 检查token是否有效
    final tokenValid = await _tokenService.isTokenValid();

    if (tokenValid) {
      await loadCurrentUser();
    } else {
      isLoggedIn.value = false;
      currentUser.value = null;

      // 如果token即将过期，尝试刷新
      final aboutToExpire = await _tokenService.isTokenAboutToExpire();
      if (aboutToExpire) {
        await _tokenService.refreshToken();
      }
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await post('/api/public/logout');
    } catch (_) {
      // 忽略登出API错误
    }

    // 清除TokenService中的token
    await _tokenService.clearTokens();

    // 重置状态
    isLoggedIn.value = false;
    currentUser.value = null;
    error.value = '';

    Get.snackbar('成功', '已登出');
  }

  /// 获取当前token
  Future<String?> getCurrentToken() async {
    return await _tokenService.getAccessToken();
  }

  /// 获取当前用户信息
  UserModel? get user => currentUser.value;

  /// 刷新token
  Future<bool> refreshToken() async {
    return await _tokenService.refreshToken();
  }

  /// 强制刷新token
  Future<bool> forceRefreshToken() async {
    return await _tokenService.forceRefreshToken();
  }

  /// 检查token是否即将过期
  Future<bool> isTokenAboutToExpire() async {
    return await _tokenService.isTokenAboutToExpire();
  }

  /// 获取token剩余时间
  Future<int> getTokenRemainingTime() async {
    return await _tokenService.getTokenRemainingTime();
  }

  /// 初始化认证状态
  Future<void> initialize() async {
    await checkAuthStatus();
  }
}
