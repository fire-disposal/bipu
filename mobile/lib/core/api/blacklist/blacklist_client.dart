// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/block_user_request.dart';
import '../models/blocked_user_response.dart';
import '../models/count_response.dart';
import '../models/paginated_response_blocked_user_response.dart';
import '../models/success_response.dart';

part 'blacklist_client.g.dart';

@RestApi()
abstract class BlacklistClient {
  factory BlacklistClient(Dio dio, {String? baseUrl}) = _BlacklistClient;

  /// Block User.
  ///
  /// 拉黑用户.
  ///
  /// 参数：.
  /// - bipupu_id: 要拉黑的用户ID.
  ///
  /// 返回：.
  /// - 成功：返回成功消息.
  /// - 失败：400（参数错误）或404（用户不存在）或409（已拉黑）.
  @POST('/api/blocks/')
  Future<SuccessResponse> postApiBlocks({
    @Body() required BlockUserRequest body,
  });

  /// Get Blocked Users.
  ///
  /// 获取黑名单列表.
  ///
  /// 参数：.
  /// - page: 页码（从1开始）.
  /// - size: 每页数量（1-100）.
  ///
  /// 返回：.
  /// - 成功：返回黑名单用户列表.
  /// - 失败：400（参数错误）.
  ///
  /// [page] - 页码.
  ///
  /// [size] - 每页数量.
  @GET('/api/blocks/')
  Future<PaginatedResponseBlockedUserResponse> getApiBlocks({
    @Query('page') int? page = 1,
    @Query('size') int? size = 20,
  });

  /// Unblock User.
  ///
  /// 取消拉黑用户.
  ///
  /// 参数：.
  /// - bipupu_id: 要取消拉黑的用户ID.
  ///
  /// 返回：.
  /// - 成功：返回成功消息.
  /// - 失败：404（未拉黑该用户）.
  @DELETE('/api/blocks/{bipupu_id}')
  Future<SuccessResponse> deleteApiBlocksBipupuId({
    @Path('bipupu_id') required String bipupuId,
  });

  /// Check Block Status.
  ///
  /// 检查用户是否被拉黑.
  ///
  /// 参数：.
  /// - bipupu_id: 要检查的用户ID.
  ///
  /// 返回：.
  /// - 成功：返回检查结果.
  /// - 失败：404（用户不存在）.
  @GET('/api/blocks/check/{bipupu_id}')
  Future<dynamic> getApiBlocksCheckBipupuId({
    @Path('bipupu_id') required String bipupuId,
  });

  /// Search Blocked Users.
  ///
  /// 搜索黑名单用户.
  ///
  /// 参数：.
  /// - query: 搜索关键词.
  /// - limit: 返回结果数量（1-50）.
  ///
  /// 返回：.
  /// - 成功：返回匹配的黑名单用户列表.
  /// - 失败：400（参数错误）.
  ///
  /// [query] - 搜索关键词（用户名或昵称）.
  ///
  /// [limit] - 返回结果数量.
  @GET('/api/blocks/search')
  Future<List<BlockedUserResponse>> getApiBlocksSearch({
    @Query('query') required String query,
    @Query('limit') int? limit = 10,
  });

  /// Get Blocked Users Count.
  ///
  /// 获取黑名单用户数量.
  ///
  /// 返回：.
  /// - 成功：返回黑名单用户数量.
  @GET('/api/blocks/count')
  Future<CountResponse> getApiBlocksCount();
}
