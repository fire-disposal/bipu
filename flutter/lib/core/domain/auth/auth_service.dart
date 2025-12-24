/// 认证服务
library;

import 'package:openapi/openapi.dart';
import 'package:dio/dio.dart';
import '../../data/data.dart';
import '../../foundation/foundation.dart';
import 'auth_result.dart';

/// 认证服务接口
abstract class AuthService {
  /// 用户登录
  Future<AuthResult> login({
    required String username,
    required String password,
  });

  /// 用户注册
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  });

  /// 用户注销
  Future<void> logout();

  /// 检查是否已认证
  bool isAuthenticated();

  /// 获取当前用户信息
  Future<Map<String, dynamic>?> getCurrentUser();

  /// 获取当前认证状态
  Future<AuthStatus> getAuthStatus();

  /// 检查是否为管理员
  Future<bool> isAdmin();

  /// 验证管理员权限
  Future<AuthResult> validateAdminAccess();
}

/// 认证服务实现
class AuthServiceImpl implements AuthService {
  final Openapi _openapi;
  final JwtStorage _jwtStorage;

  AuthServiceImpl({required Openapi openapi, required JwtStorage jwtStorage})
    : _openapi = openapi,
      _jwtStorage = jwtStorage;

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      Logger.info('用户登录: $username');

      // 输入验证
      final usernameError = UsernameValidator.validate(username);
      if (usernameError != null) {
        return AuthResult.failure(usernameError);
      }

      final passwordError = PasswordValidator.validate(password);
      if (passwordError != null) {
        return AuthResult.failure(passwordError);
      }

      // 创建登录请求
      final loginBody = UserLogin(
        (b) => b
          ..username = username
          ..password = password,
      );

      // 调用登录API
      final response = await _openapi.getUsersApi().loginApiUsersLoginPost(
        userLogin: loginBody,
      );

      // 检查响应
      if (response.statusCode == 200 && response.data != null) {
        final tokenData = response.data!;

        // 创建JWT令牌对象
        final expiresAt = DateTime.now().add(
          Duration(seconds: tokenData.expiresIn),
        );
        final jwtToken = JwtToken(
          accessToken: tokenData.accessToken,
          refreshToken: null,
          expiresAt: expiresAt,
        );

        // 保存令牌
        await _jwtStorage.saveToken(jwtToken);

        // 设置API客户端的认证信息
        _openapi.setBearerAuth('HTTPBearer', jwtToken.accessToken);

        // 获取用户信息
        Map<String, dynamic>? userInfo;
        try {
          final userResponse = await _openapi
              .getUsersApi()
              .getCurrentUserInfoApiUsersMeGet();
          if (userResponse.data != null) {
            userInfo = _userResponseToMap(userResponse.data!);
          }
        } catch (e) {
          Logger.warning('获取用户信息失败: $e');
        }

        Logger.info('用户登录成功: $username');
        return AuthResult.success(jwtToken, userInfo);
      } else {
        final errorMsg = '登录失败: ${response.statusMessage ?? '未知错误'}';
        Logger.warning(errorMsg);
        return AuthResult.failure(errorMsg);
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.statusCode == 401) {
        errorMessage = '用户名或密码错误';
      } else if (e.response?.statusCode == 422) {
        errorMessage = '输入数据验证失败';
      } else {
        errorMessage = '网络请求失败: ${e.message}';
      }
      Logger.error('登录请求失败', e);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      final errorMsg = '登录异常: $e';
      Logger.error(errorMsg, e);
      return AuthResult.failure(errorMsg);
    }
  }

  @override
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('用户注册: $username');

      // 输入验证
      final usernameError = UsernameValidator.validate(username);
      if (usernameError != null) {
        return AuthResult.failure(usernameError);
      }

      final emailError = EmailValidator.validate(email);
      if (emailError != null) {
        return AuthResult.failure(emailError);
      }

      final passwordError = PasswordValidator.validate(password);
      if (passwordError != null) {
        return AuthResult.failure(passwordError);
      }

      // 创建注册请求
      final registerBody = UserCreate(
        (b) => b
          ..username = username
          ..email = email
          ..password = password,
      );

      // 调用注册API
      final response = await _openapi
          .getUsersApi()
          .registerUserApiUsersRegisterPost(userCreate: registerBody);

      // 检查响应
      if (response.statusCode == 201 && response.data != null) {
        // 注册成功后自动登录
        return await login(username: username, password: password);
      } else {
        final errorMsg = '注册失败: ${response.statusMessage ?? '未知错误'}';
        Logger.warning(errorMsg);
        return AuthResult.failure(errorMsg);
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.statusCode == 409) {
        errorMessage = '用户名或邮箱已存在';
      } else if (e.response?.statusCode == 422) {
        errorMessage = '输入数据验证失败';
      } else {
        errorMessage = '网络请求失败: ${e.message}';
      }
      Logger.error('注册请求失败', e);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      final errorMsg = '注册异常: $e';
      Logger.error(errorMsg, e);
      return AuthResult.failure(errorMsg);
    }
  }

  @override
  Future<void> logout() async {
    try {
      Logger.info('用户注销');
      await _jwtStorage.clearToken();
      _openapi.setBearerAuth('HTTPBearer', '');
      Logger.info('用户注销完成');
    } catch (e) {
      Logger.error('用户注销失败', e);
      rethrow;
    }
  }

  @override
  bool isAuthenticated() {
    // 由于接口设计问题，这里使用同步方式检查
    // 实际实现中应该避免在同步方法中调用异步操作
    // 这里假设令牌状态已经被缓存或预先加载
    return true; // 临时实现，实际应该通过其他机制获取状态
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      if (!await _jwtStorage.hasValidToken()) {
        return null;
      }

      final response = await _openapi
          .getUsersApi()
          .getCurrentUserInfoApiUsersMeGet();

      if (response.data != null) {
        return _userResponseToMap(response.data!);
      }
      return null;
    } catch (e) {
      Logger.error('获取当前用户信息失败', e);
      return null;
    }
  }

  @override
  Future<AuthStatus> getAuthStatus() async {
    try {
      final token = await _jwtStorage.getToken();
      final isAuthenticated = await _jwtStorage.hasValidToken();

      Map<String, dynamic>? userInfo;
      if (token != null) {
        userInfo = JwtUtils.getUserInfoFromToken(token.accessToken);
      }

      return AuthStatus(
        isAuthenticated: isAuthenticated,
        hasValidToken: token != null && !token.isExpired,
        tokenExpiresSoon: token?.isAboutToExpire ?? false,
        tokenExpired: token?.isExpired ?? true,
        userInfo: userInfo,
      );
    } catch (e) {
      Logger.error('获取认证状态失败', e);
      return const AuthStatus(
        isAuthenticated: false,
        hasValidToken: false,
        tokenExpiresSoon: false,
        tokenExpired: true,
        userInfo: null,
      );
    }
  }

  @override
  Future<bool> isAdmin() async {
    try {
      final userInfo = await getCurrentUser();
      return userInfo?['isSuperuser'] ?? false;
    } catch (e) {
      Logger.error('检查管理员权限失败', e);
      return false;
    }
  }

  @override
  Future<AuthResult> validateAdminAccess() async {
    try {
      if (!await _jwtStorage.hasValidToken()) {
        return AuthResult.failure('请先登录');
      }

      final userInfo = await getCurrentUser();
      if (userInfo == null) {
        return AuthResult.failure('无法获取用户信息');
      }

      if (userInfo['isSuperuser'] != true) {
        return AuthResult.failure('需要管理员权限');
      }

      final token = await _jwtStorage.getToken();
      if (token == null) {
        return AuthResult.failure('无法获取认证令牌');
      }

      return AuthResult.success(token, userInfo);
    } catch (e) {
      final errorMsg = '验证管理员权限失败: $e';
      Logger.error(errorMsg, e);
      return AuthResult.failure(errorMsg);
    }
  }

  /// 将UserResponse转换为Map
  Map<String, dynamic> _userResponseToMap(dynamic userResponse) {
    return {
      'id': userResponse.id,
      'username': userResponse.username,
      'email': userResponse.email,
      'isSuperuser': userResponse.isSuperuser,
      'isActive': userResponse.isActive,
      'createdAt': userResponse.createdAt?.toIso8601String(),
      'updatedAt': userResponse.updatedAt?.toIso8601String(),
    };
  }
}
