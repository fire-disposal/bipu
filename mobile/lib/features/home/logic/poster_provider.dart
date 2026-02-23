import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/api/api_provider.dart';
import '../../../../shared/models/poster_model.dart';

/// 海报状态
enum PosterStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 已加载
  loaded,

  /// 错误
  error,
}

/// 海报提供者
final posterProvider = NotifierProvider<PosterNotifier, PosterStatus>(
  () => PosterNotifier(),
);

class PosterNotifier extends Notifier<PosterStatus> {
  final List<PosterResponse> _posters = [];

  List<PosterResponse> get posters => _posters;

  @override
  PosterStatus build() {
    return PosterStatus.initial;
  }

  /// 刷新海报数据
  Future<void> refresh() async {
    state = PosterStatus.loading;

    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.getActivePosters(limit: 10);

      if (response.response.statusCode == 200) {
        final data = response.data as List;
        _posters.clear();
        _posters.addAll(
          data.map((json) => PosterResponse.fromJson(json)).toList(),
        );
        state = PosterStatus.loaded;
      } else {
        debugPrint('[Poster] 获取海报失败: ${response.response.statusCode}');
        state = PosterStatus.error;
      }
    } catch (e) {
      debugPrint('[Poster] 刷新海报数据失败：$e');
      state = PosterStatus.error;
    }
  }

  /// 获取激活的海报列表
  Future<List<PosterResponse>> loadActivePosters({int limit = 10}) async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.getActivePosters(limit: limit);

      if (response.response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => PosterResponse.fromJson(json)).toList();
      } else {
        debugPrint('[Poster] 获取激活海报失败: ${response.response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[Poster] 加载激活海报失败：$e');
      return [];
    }
  }
}

/// 激活海报列表提供者
final activePostersProvider = FutureProvider<List<PosterResponse>>((ref) async {
  try {
    final posterNotifier = ref.read(posterProvider.notifier);
    return await posterNotifier.loadActivePosters(limit: 10);
  } catch (e) {
    debugPrint('[Poster] 获取激活海报失败：$e');
    return [];
  }
});

/// 海报图片缓存提供者
final posterImageProvider = FutureProvider.family<String?, int>((
  ref,
  posterId,
) async {
  try {
    final restClient = ref.read(restClientProvider);
    final response = await restClient.getPosterImageBinary(posterId);

    if (response.response.statusCode == 200) {
      // 对于二进制图片，我们返回完整的URL
      // 前端可以直接使用这个URL加载图片
      return '/api/posters/$posterId/image/binary';
    } else {
      debugPrint('[Poster] 获取海报图片失败: ${response.response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('[Poster] 加载海报图片失败：$e');
    return null;
  }
});
