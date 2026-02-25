import 'package:get/get.dart';
import '../services/system_service.dart';
import '../services/auth_service.dart';

/// 应用控制器 - 管理应用级别的状态
class AppController extends GetxController {
  static AppController get to => Get.find();

  // 依赖服务
  final SystemService _system = SystemService.instance;
  final AuthService _auth = AuthService.instance;

  // 应用状态
  final RxBool appInitialized = false.obs;
  final RxString appError = ''.obs;
  final RxBool isDarkMode = false.obs;

  /// 初始化应用
  Future<void> initializeApp() async {
    try {
      // 1. 检查系统状态
      await _system.checkAllSystems();

      // 2. 检查认证状态（AuthService已经在main.dart中初始化）

      // 3. 标记应用已初始化
      appInitialized.value = true;

      Get.snackbar('应用已就绪', '系统状态正常', duration: const Duration(seconds: 2));
    } catch (e) {
      appError.value = '应用初始化失败: $e';
      Get.snackbar('错误', appError.value);
    }
  }

  /// 切换主题模式
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }

  /// 检查应用是否完全就绪
  bool get isAppReady {
    return appInitialized.value &&
        _system.isSystemFullyOperational &&
        appError.value.isEmpty;
  }

  /// 获取应用状态摘要
  Map<String, dynamic> get appStatus {
    return {
      'initialized': appInitialized.value,
      'systemReady': _system.isSystemFullyOperational,
      'userLoggedIn': _auth.isLoggedIn.value,
      'darkMode': isDarkMode.value,
      'error': appError.value,
      'fullyReady': isAppReady,
    };
  }

  /// 重置应用状态
  void reset() {
    appInitialized.value = false;
    appError.value = '';
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    // 可以在这里启动应用初始化
  }

  /// 清理资源
  @override
  void onClose() {
    reset();
    super.onClose();
  }
}
