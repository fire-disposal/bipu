import 'package:dio/dio.dart';
import 'package:flutter_user/models/poster/poster_response.dart';
import 'package:flutter_user/models/poster/poster_create.dart';
import 'package:flutter_user/models/poster/poster_update.dart';
import 'package:flutter_user/models/common/paginated_response.dart';

class PosterApi {
  final Dio _dio;

  PosterApi(this._dio);

  /// 获取海报列表
  Future<PaginatedResponse<PosterResponse>> getPosters({
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/posters/',
      queryParameters: {'page': page, 'page_size': size},
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['posters'] as List)
        .map((e) => PosterResponse.fromJson(e))
        .toList();

    return PaginatedResponse<PosterResponse>(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      size: data['page_size'] as int,
    );
  }

  /// 获取活跃海报
  Future<List<PosterResponse>> getActivePosters({int limit = 10}) async {
    final response = await _dio.get(
      '/api/posters/active',
      queryParameters: {'limit': limit},
    );

    final data = response.data as List<dynamic>;
    return data.map((e) => PosterResponse.fromJson(e)).toList();
  }

  /// 创建海报
  Future<PosterResponse> createPoster(PosterCreate body) async {
    final formData = FormData.fromMap({
      'title': body.title,
      if (body.linkUrl != null) 'link_url': body.linkUrl,
      'display_order': body.displayOrder,
      'is_active': body.isActive,
    });

    final response = await _dio.post('/api/posters/', data: formData);
    return PosterResponse.fromJson(response.data);
  }

  /// 创建简单海报
  Future<PosterResponse> createSimplePoster({
    required String title,
    String? linkUrl,
    int displayOrder = 0,
    bool isActive = true,
  }) async {
    final body = PosterCreate(
      title: title,
      linkUrl: linkUrl,
      displayOrder: displayOrder,
      isActive: isActive,
    );
    return createPoster(body);
  }

  /// 获取单个海报
  Future<PosterResponse> getPosterById(int posterId) async {
    final response = await _dio.get('/api/posters/$posterId');
    return PosterResponse.fromJson(response.data);
  }

  /// 更新海报
  Future<PosterResponse> updatePoster(int posterId, PosterUpdate body) async {
    final response = await _dio.put(
      '/api/posters/$posterId',
      data: body.toJson(),
    );
    return PosterResponse.fromJson(response.data);
  }

  /// 更新海报图片
  Future<PosterResponse> updatePosterImage(
    int posterId,
    String imageFilePath,
  ) async {
    final formData = FormData.fromMap({
      'image_file': await MultipartFile.fromFile(imageFilePath),
    });

    final response = await _dio.put(
      '/api/posters/$posterId/image',
      data: formData,
    );
    return PosterResponse.fromJson(response.data);
  }

  /// 删除海报
  Future<void> deletePoster(int posterId) async {
    await _dio.delete('/api/posters/$posterId');
  }

  /// 获取海报图片URL
  Future<String> getPosterImageUrl(int posterId) async {
    final response = await _dio.get('/api/posters/$posterId/image');
    final data = response.data as Map<String, dynamic>;
    return data['image_url'] as String? ?? '';
  }

  /// 搜索海报
  Future<List<PosterResponse>> searchPosters(String query) async {
    final response = await _dio.get(
      '/api/search',
      queryParameters: {'q': query, 'type': 'poster', 'limit': 20},
    );

    final data = response.data as List<dynamic>;
    return data.map((e) => PosterResponse.fromJson(e)).toList();
  }
}
