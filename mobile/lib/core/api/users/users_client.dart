// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_public.dart';

part 'users_client.g.dart';

@RestApi()
abstract class UsersClient {
  factory UsersClient(Dio dio, {String? baseUrl}) = _UsersClient;

  /// Get User By Bipupu Id.
  ///
  /// 通过 bipupu_id 获取用户公开信息.
  ///
  /// 参数：.
  /// - bipupu_id: 用户的业务标识符.
  ///
  /// 返回：.
  /// - 成功：返回用户公开信息.
  /// - 失败：404（用户不存在）.
  ///
  /// 包含信息：.
  /// - 用户名、昵称、bipupu_id.
  /// - 头像URL.
  /// - 用户状态（是否活跃）.
  /// - 创建时间等基本信息.
  ///
  /// 注意：.
  /// - 无需认证，公开接口.
  /// - 不返回敏感信息（如邮箱、密码等）.
  /// - 只返回 is_active=True 的用户信息.
  @GET('/api/users/users/{bipupu_id}')
  Future<UserPublic> getApiUsersUsersBipupuId({
    @Path('bipupu_id') required String bipupuId,
  });

  /// Get User Avatar By Bipupu Id.
  ///
  /// 通过 bipupu_id 获取用户头像.
  ///
  /// 参数：.
  /// - bipupu_id: 用户的业务标识符.
  ///
  /// 特性：.
  /// - 支持ETag缓存，减少带宽消耗.
  /// - 支持HTTP 304 Not Modified响应.
  /// - 头像数据缓存24小时.
  /// - 自动处理头像版本更新.
  ///
  /// 返回：.
  /// - 成功：返回JPEG格式的头像图片.
  /// - 失败：404（用户或头像不存在）.
  ///
  /// 注意：.
  /// - 无需认证，公开接口.
  /// - 支持缓存控制头（Cache-Control, ETag）.
  /// - 如果用户没有头像，返回404错误.
  /// - 前端应处理无头像情况（如显示首字母）.
  @GET('/api/users/users/{bipupu_id}/avatar')
  Future<void> getApiUsersUsersBipupuIdAvatar({
    @Path('bipupu_id') required String bipupuId,
  });
}
