import 'package:get/get.dart';
import 'base_service.dart';
import '../models/poster_model.dart';

/// 海报服务 - 处理海报相关API
class PosterService extends BaseService {
  static PosterService get instance => Get.find();

  final posters = <PosterResponse>[].obs;
  final activePosters = <PosterResponse>[].obs;
  final isLoading = false.obs;
  final RxString error = ''.obs;

  /// 获取激活的海报列表（前端轮播用）
  Future<ServiceResponse<List<PosterResponse>>> getActivePosters({
    int? limit,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/posters/active',
      query: {if (limit != null) 'limit': limit.toString()},
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final posterList = response.data!
          .map((json) => PosterResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      activePosters.assignAll(posterList);
      return ServiceResponse.success(posterList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取激活海报失败', ServiceErrorType.unknown),
    );
  }

  /// 获取海报列表（管理用）
  Future<ServiceResponse<List<PosterResponse>>> getPosters({
    int? page,
    int? pageSize,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/posters/',
      query: {
        if (page != null) 'page': page.toString(),
        if (pageSize != null) 'page_size': pageSize.toString(),
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final posterList = response.data!
          .map((json) => PosterResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      posters.assignAll(posterList);
      return ServiceResponse.success(posterList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取海报列表失败', ServiceErrorType.unknown),
    );
  }

  /// 获取单个海报详情
  Future<ServiceResponse<PosterResponse>> getPoster(int posterId) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<PosterResponse>(
      '/api/posters/$posterId',
      fromJson: (json) => PosterResponse.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 获取海报图片URL
  String getPosterImageUrl(int posterId) {
    return '${dio.options.baseUrl}/api/posters/$posterId/image';
  }

  /// 获取海报图片（二进制格式，直接用于img标签）
  Future<ServiceResponse<List<int>>> getPosterImage(int posterId) async {
    final response = await get<List<int>>('/api/posters/$posterId/image');

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    }

    return response;
  }

  /// 根据ID查找海报
  PosterResponse? findPosterById(int posterId) {
    return posters.firstWhereOrNull((poster) => poster.id == posterId);
  }

  /// 获取激活的海报（用于轮播）
  List<PosterResponse> get postersForCarousel {
    return activePosters.where((poster) => poster.isActive).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// 获取海报统计
  Map<String, int> getPosterStats() {
    final activeCount = posters.where((poster) => poster.isActive).length;

    return {
      'total': posters.length,
      'active': activeCount,
      'inactive': posters.length - activeCount,
    };
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 清空所有数据
  void clearAll() {
    posters.clear();
    activePosters.clear();
    error.value = '';
  }

  /// 初始化海报数据
  Future<void> initialize() async {
    if (posters.isEmpty) {
      await getPosters();
    }
    if (activePosters.isEmpty) {
      await getActivePosters();
    }
  }

  /// 检查海报是否有效（激活状态）
  bool isPosterValid(PosterResponse poster) {
    return poster.isActive;
  }

  /// 获取当前有效的海报数量
  int get validPosterCount {
    return posters.where(isPosterValid).length;
  }

  /// 获取需要显示的海报（用于首页展示）
  List<PosterResponse> get displayPosters {
    return postersForCarousel.take(5).toList(); // 最多显示5张
  }

  /// 获取有链接的海报
  List<PosterResponse> get postersWithLinks {
    return posters.where((poster) => poster.linkUrl != null).toList();
  }

  /// 获取最近创建的海报
  List<PosterResponse> get recentlyCreatedPosters {
    return List.from(posters)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取最近更新的海报
  List<PosterResponse> get recentlyUpdatedPosters {
    return List.from(posters)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
