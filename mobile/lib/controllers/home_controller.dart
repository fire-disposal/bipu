import 'package:get/get.dart';
import '../repos/poster_repo.dart';
import '../shared/models/poster_model.dart';

/// 极简首页控制器 - GetX风格
class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // 状态
  final posters = <PosterResponse>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final lastUpdateTime = DateTime.now().obs;

  // 仓库
  final PosterRepo _repo = PosterRepo();

  /// 加载海报
  Future<void> loadPosters({int? limit}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.getActivePosters(limit: limit);

      if (result['success'] == true) {
        posters.value = result['data'] as List<PosterResponse>;
        lastUpdateTime.value = DateTime.now();
      } else {
        error.value = result['error'] as String;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadPosters();
  }

  /// 获取首页统计
  Map<String, dynamic> getHomeStats() {
    return {
      'posterCount': posters.length,
      'lastUpdate': lastUpdateTime.value,
      'hasError': error.value.isNotEmpty,
    };
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    loadPosters();
  }
}
