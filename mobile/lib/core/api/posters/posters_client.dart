// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/poster_list_response.dart';
import '../models/poster_response.dart';
import '../models/poster_update.dart';

part 'posters_client.g.dart';

@RestApi()
abstract class PostersClient {
  factory PostersClient(Dio dio, {String? baseUrl}) = _PostersClient;

  /// Get Posters.
  ///
  /// 获取海报列表（管理用）.
  ///
  /// [page] - 页码.
  ///
  /// [pageSize] - 每页数量.
  @GET('/api/posters/')
  Future<PosterListResponse> getApiPosters({
    @Query('page') int? page = 1,
    @Query('page_size') int? pageSize = 20,
  });

  /// Create Poster.
  ///
  /// 创建海报.
  ///
  /// [title] - 海报标题.
  ///
  /// [linkUrl] - 点击跳转链接.
  ///
  /// [displayOrder] - 显示顺序.
  ///
  /// [isActive] - 是否激活.
  ///
  /// [imageFile] - 海报图片.
  @MultiPart()
  @POST('/api/posters/')
  Future<PosterResponse> postApiPosters({
    @Part(name: 'title') required String title,
    @Part(name: 'image_file') required File imageFile,
    @Part(name: 'display_order') int? displayOrder = 0,
    @Part(name: 'is_active') bool? isActive = true,
    @Part(name: 'link_url') String? linkUrl,
  });

  /// Get Active Posters.
  ///
  /// 获取激活的海报列表（前端轮播用）.
  ///
  /// 业务逻辑：.
  /// 1. 从数据库查询激活的海报（is_active=True）.
  /// 2. 按 display_order 排序.
  /// 3. 限制返回数量.
  /// 4. 业务层构建响应，动态生成 image_url.
  ///
  /// [limit] - 返回数量.
  @GET('/api/posters/active')
  Future<List<PosterResponse>> getApiPostersActive({
    @Query('limit') int? limit = 10,
  });

  /// Get Poster.
  ///
  /// 获取单个海报详情（管理用）.
  @GET('/api/posters/{poster_id}')
  Future<PosterResponse> getApiPostersPosterId({
    @Path('poster_id') required int posterId,
  });

  /// Update Poster.
  ///
  /// 更新海报信息.
  @PUT('/api/posters/{poster_id}')
  Future<PosterResponse> putApiPostersPosterId({
    @Path('poster_id') required int posterId,
    @Body() required PosterUpdate body,
  });

  /// Delete Poster.
  ///
  /// 删除海报.
  @DELETE('/api/posters/{poster_id}')
  Future<void> deleteApiPostersPosterId({
    @Path('poster_id') required int posterId,
  });

  /// Get Poster Image.
  ///
  /// 获取海报图片（二进制格式，直接用于img标签）.
  ///
  /// 参数：.
  /// - poster_id: 海报ID.
  ///
  /// 返回：.
  /// - 成功：返回JPEG格式的二进制图片数据.
  /// - 失败：404（海报或图片不存在）.
  ///
  /// 特性：.
  /// - 支持ETag缓存，减少带宽消耗.
  /// - 支持HTTP 304 Not Modified响应.
  /// - 图片数据缓存24小时.
  /// - 自动处理图片版本更新.
  ///
  /// 注意：.
  /// - 无需认证，公开接口.
  /// - 支持缓存控制头（Cache-Control, ETag）.
  /// - 统一返回JPEG格式二进制数据.
  /// - 前端可直接用于img标签的src属性.
  @GET('/api/posters/{poster_id}/image')
  Future<void> getApiPostersPosterIdImage({
    @Path('poster_id') required int posterId,
  });

  /// Update Poster Image.
  ///
  /// 更新海报图片.
  ///
  /// [imageFile] - 新海报图片.
  @MultiPart()
  @PUT('/api/posters/{poster_id}/image')
  Future<PosterResponse> putApiPostersPosterIdImage({
    @Path('poster_id') required int posterId,
    @Part(name: 'image_file') required File imageFile,
  });
}
