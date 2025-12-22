/// 认证服务
/// 处理用户登录、注销和JWT令牌管理
library;

import 'package:openapi/openapi.dart';
import 'package:dio/dio.dart';
import '../utils/jwt_manager.dart';
import '../utils/logger.dart';

/// 认证结果
class AuthResult {
  final bool success;
  final String? message;
  final JwtToken? token;
  final UserResponse? user;

  const AuthResult({
    required this.success,
    this.message,
    this.token,
    this.user,
  });

  factory AuthResult.success(JwtToken token, UserResponse? user) {
    return AuthResult(success: true, token: token, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }
}

/// 认证服务
class AuthService {
  final Openapi _openapi;
  final JwtManager _jwtManager;

  AuthService({required Openapi openapi, required JwtManager jwtManager})
    : _openapi = openapi,
      _jwtManager = jwtManager;

  /// 用户登录
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      Logger.info('用户登录: $username');

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
        // 根据expiresIn计算过期时间
        final expiresAt = DateTime.now().add(
          Duration(seconds: tokenData.expiresIn),
        );
        final jwtToken = JwtToken(
          accessToken: tokenData.accessToken,
          refreshToken: null, // Token模型没有refreshToken字段
          expiresAt: expiresAt,
        );

        // 保存令牌
        await _jwtManager.saveToken(jwtToken);

        // 设置API客户端的认证信息
        _openapi.setBearerAuth('HTTPBearer', jwtToken.accessToken);

        // 获取用户信息
        UserResponse? userInfo;
        try {
          final userResponse = await _openapi
              .getUsersApi()
              .getCurrentUserInfoApiUsersMeGet();
          userInfo = userResponse.data;
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

  /// 用户注册
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('用户注册: $username');

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

  /// 用户注销
  Future<void> logout() async {
    try {
      Logger.info('用户注销');

      // 清除本地存储的令牌
      await _jwtManager.clearToken();

      // 清除API客户端的认证信息
      _openapi.setBearerAuth('HTTPBearer', '');

      Logger.info('用户注销完成');
    } catch (e) {
      Logger.error('用户注销失败', e);
      rethrow;
    }
  }

  /// 检查是否已认证
  bool isAuthenticated() {
    return _jwtManager.hasValidToken();
  }

  /// 获取当前用户信息
  Future<UserResponse?> getCurrentUser() async {
    try {
      if (!isAuthenticated()) {
        return null;
      }

      final response = await _openapi
          .getUsersApi()
          .getCurrentUserInfoApiUsersMeGet();
      return response.data;
    } catch (e) {
      Logger.error('获取当前用户信息失败', e);
      return null;
    }
  }

  /// 更新用户信息
  Future<bool> updateUser({String? username, String? email}) async {
    try {
      if (!isAuthenticated()) {
        return false;
      }

      final updateBody = UserUpdate((b) {
        if (username != null) b..username = username;
        if (email != null) b..email = email;
      });

      final response = await _openapi
          .getUsersApi()
          .updateCurrentUserApiUsersMePut(userUpdate: updateBody);

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('更新用户信息失败', e);
      return false;
    }
  }

  /// 刷新访问令牌
  Future<bool> refreshToken() async {
    try {
      final refreshToken = _jwtManager.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      Logger.info('刷新访问令牌');

      // 这里应该调用刷新令牌的API端点
      // 由于OpenAPI规范中可能没有定义，这里需要根据实际的API设计来实现
      // 暂时返回false，后续根据实际API补充
      Logger.warning('刷新令牌API未实现');
      return false;
    } catch (e) {
      Logger.error('刷新令牌失败', e);
      return false;
    }
  }

  /// 获取当前JWT令牌
  JwtToken? getCurrentToken() {
    return _jwtManager.getCurrentToken();
  }

  /// 从令牌获取用户信息
  Map<String, dynamic>? getUserInfoFromToken() {
    return _jwtManager.getUserInfoFromToken();
  }

  /// 初始化认证状态
  Future<void> initializeAuth() async {
    try {
      final token = _jwtManager.getCurrentToken();
      if (token != null && !token.isExpired) {
        // 设置API客户端的认证信息
        _openapi.setBearerAuth('HTTPBearer', token.accessToken);
        Logger.info('认证状态已初始化');
      } else if (token != null && token.isExpired) {
        // 尝试刷新令牌
        await refreshToken();
      }
    } catch (e) {
      Logger.error('初始化认证状态失败', e);
    }
  }
}
