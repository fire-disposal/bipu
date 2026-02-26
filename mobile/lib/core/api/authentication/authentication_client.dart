// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/success_response.dart';
import '../models/token.dart';
import '../models/token_refresh.dart';
import '../models/user_create.dart';
import '../models/user_login.dart';
import '../models/user_private.dart';

part 'authentication_client.g.dart';

@RestApi()
abstract class AuthenticationClient {
  factory AuthenticationClient(Dio dio, {String? baseUrl}) = _AuthenticationClient;

  /// Register User.
  ///
  /// 用户注册.
  ///
  /// 参数：.
  /// - username: 用户名，用于登录.
  /// - password: 密码，长度限制为6-128字符.
  /// - nickname: 昵称，可选.
  ///
  /// 返回：.
  /// - 成功：返回新创建的用户信息.
  /// - 失败：400（验证失败）或500（数据库操作失败）.
  ///
  /// 特性：.
  /// - 密码自动哈希存储.
  /// - 自动生成唯一的 bipupu_id.
  /// - 验证用户名和密码格式.
  ///
  /// 注意：.
  /// - 用户名必须是唯一的.
  /// - 密码在传输和存储中都会加密.
  /// - 注册后用户自动处于活跃状态.
  @POST('/api/public/register')
  Future<UserPrivate> postApiPublicRegister({
    @Body() required UserCreate body,
  });

  /// Login User.
  ///
  /// 用户登录.
  ///
  /// 参数：.
  /// - username: 用户名.
  /// - password: 密码.
  ///
  /// 返回：.
  /// - 成功：返回访问令牌和刷新令牌.
  /// - 失败：401（认证失败）或400（验证失败）.
  ///
  /// 特性：.
  /// - 支持JWT令牌.
  /// - 令牌有过期时间.
  /// - 支持刷新令牌机制.
  ///
  /// 注意：.
  /// - 只允许活跃用户登录.
  /// - 令牌存储在安全的地方.
  @POST('/api/public/login')
  Future<Token> postApiPublicLogin({
    @Body() required UserLogin body,
  });

  /// Refresh Token.
  ///
  /// 刷新访问令牌.
  ///
  /// 参数：.
  /// - refresh_token: 刷新令牌.
  ///
  /// 返回：.
  /// - 成功：返回新的访问令牌和刷新令牌.
  /// - 失败：401（令牌无效或过期）或400（验证失败）.
  ///
  /// 特性：.
  /// - 使用刷新令牌获取新的访问令牌.
  /// - 刷新令牌可以轮换.
  /// - 支持令牌黑名单.
  ///
  /// 注意：.
  /// - 刷新令牌只能使用一次.
  /// - 旧的刷新令牌会被加入黑名单.
  @POST('/api/public/refresh')
  Future<Token> postApiPublicRefresh({
    @Body() required TokenRefresh body,
  });

  /// Logout User.
  ///
  /// 用户登出.
  ///
  /// 参数：.
  /// - Authorization: Bearer令牌.
  ///
  /// 返回：.
  /// - 成功：返回登出成功消息.
  /// - 失败：401（认证失败）.
  ///
  /// 特性：.
  /// - 将访问令牌加入黑名单.
  /// - 支持立即令牌失效.
  ///
  /// 注意：.
  /// - 登出后令牌立即失效.
  /// - 需要有效的访问令牌.
  @POST('/api/public/logout')
  Future<SuccessResponse> postApiPublicLogout();

  /// Verify Token.
  ///
  /// 验证令牌有效性.
  ///
  /// 参数：.
  /// - Authorization: Bearer令牌.
  ///
  /// 返回：.
  /// - 成功：返回验证成功消息.
  /// - 失败：401（令牌无效）.
  ///
  /// 特性：.
  /// - 快速令牌验证.
  /// - 不执行数据库查询.
  ///
  /// 注意：.
  /// - 只验证令牌格式和签名.
  /// - 不检查用户状态.
  @GET('/api/public/verify-token')
  Future<SuccessResponse> getApiPublicVerifyToken();
}
