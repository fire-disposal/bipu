import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api/rest_client.dart';
import '../shared/models/poster_model.dart';

/// 极简海报仓库 - 直接调用API
class PosterRepo {
  static PosterRepo get to => Get.find();

  late final RestClient _api;

  PosterRepo() {
    _api = RestClient(Dio());
  }

  /// 获取激活的海报列表
  Future<Map<String, dynamic>> getActivePosters({int? limit}) async {
    try {
      final response = await _api.getActivePosters(limit: limit);

      if (response.response.statusCode == 200) {
        final posters = (response.data as List)
            .map((json) => PosterResponse.fromJson(json))
            .toList();
        return {'success': true, 'data': posters};
      } else {
        return {
          'success': false,
          'error': '获取海报失败: ${response.response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取海报图片URL
  String getPosterImageUrl(int posterId) {
    return '/api/posters/$posterId/image';
  }
}
