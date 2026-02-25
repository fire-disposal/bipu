import 'package:get/get.dart';
import '../services/poster_service.dart';
import '../services/system_service.dart';
import '../models/poster_model.dart';

/// 首页控制器 - 管理首页相关状态
class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // 依赖服务
  final PosterService _poster = PosterService.instance;
  final SystemService _system = SystemService.instance;

  // UI状态
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt selectedPosterIndex = 0.obs;
  final RxInt lastUpdateTime = 0.obs;

  // 计算属性 - 直接暴露服务的状态
  List<PosterResponse> get posters => _poster.postersForCarousel;
  List<PosterResponse> get displayPosters => _poster.displayPosters;
  bool get systemHealthy => _system.isHealthy.value;
  bool get systemReady => _system.isReady.value;
  bool get systemLive => _system.isLive.value;

  /// 初始化首页数据
  Future<void> initializeHome() async {
    isLoading.value = true;
    error.value = '';

    try {
      // 并行加载海报和系统状态
      await Future.wait([
        _poster.getActivePosters(),
        _system.checkAllSystems(),
      ]);
    } catch (e) {
      error.value = '首页初始化失败: $e';
      Get.snackbar('错误', error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// 处理海报点击
  void handlePosterTap(PosterResponse poster) {
    if (poster.linkUrl != null && poster.linkUrl!.isNotEmpty) {
      // 如果有链接，打开链接
      Get.snackbar('海报点击', '打开链接: ${poster.linkUrl}');
      // 在实际项目中，这里应该使用url_launcher打开链接
    } else {
      // 如果没有链接，显示海报详情
      Get.snackbar('海报详情', poster.title, duration: const Duration(seconds: 2));
    }
  }

  /// 选择海报
  void selectPoster(int index) {
    if (index >= 0 && index < posters.length) {
      selectedPosterIndex.value = index;
      handlePosterTap(posters[index]);
    }
  }

  /// 刷新首页数据
  Future<void> refreshHome() async {
    await initializeHome();
    Get.snackbar('刷新成功', '首页数据已更新', duration: const Duration(seconds: 2));
  }

  /// 获取首页统计信息
  Map<String, dynamic> get homeStats {
    return {
      'posterCount': posters.length,
      'displayPosterCount': displayPosters.length,
      'systemHealthy': systemHealthy,
      'systemReady': systemReady,
      'systemLive': systemLive,
      'selectedPosterIndex': selectedPosterIndex.value,
    };
  }

  /// 检查是否有海报可显示
  bool get hasPosters => posters.isNotEmpty;

  /// 获取当前选中的海报
  PosterResponse? get selectedPoster {
    if (selectedPosterIndex.value < posters.length) {
      return posters[selectedPosterIndex.value];
    }
    return null;
  }

  /// 检查是否处于初始加载状态
  bool isInitialLoading() {
    return isLoading.value;
  }

  /// 检查是否应该显示错误
  bool shouldShowError() {
    return error.value.isNotEmpty;
  }

  /// 检查是否为空状态
  bool isEmptyState() {
    return !isLoading.value && posters.isEmpty && error.value.isEmpty;
  }

  /// 更新页面索引
  void updatePageIndex(int index) {
    if (index >= 0 && index < posters.length) {
      selectedPosterIndex.value = index;
    }
  }

  /// 获取海报图片URL
  String getPosterImageUrl(int posterId) {
    return _poster.getPosterImageUrl(posterId);
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 重置首页状态
  void reset() {
    selectedPosterIndex.value = 0;
    error.value = '';
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    // 可以在这里初始化首页数据
    // initializeHome();
  }

  /// 清理资源
  @override
  void onClose() {
    reset();
    super.onClose();
  }
}
