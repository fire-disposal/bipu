import 'package:get/get.dart';

/// 极简全局状态控制器
class AppController extends GetxController {
  static AppController get to => Get.find();

  // 应用状态
  final isDarkMode = false.obs;
  final isLoading = false.obs;
  final appVersion = '1.0.0'.obs;
  final currentRoute = '/'.obs;

  // 网络状态
  final isOnline = true.obs;
  final serverStatus = 'unknown'.obs;

  // 通知状态
  final unreadCount = 0.obs;
  final hasNewMessage = false.obs;

  // 蓝牙状态（保持现有）
  final isBluetoothEnabled = false.obs;
  final isBluetoothConnected = false.obs;
  final bluetoothDeviceName = ''.obs;

  // 切换主题
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.snackbar('提示', isDarkMode.value ? '深色模式已开启' : '浅色模式已开启');
  }

  // 显示加载
  void showLoading([String? message]) {
    isLoading.value = true;
    if (message != null) {
      Get.snackbar('加载中', message);
    }
  }

  // 隐藏加载
  void hideLoading() {
    isLoading.value = false;
  }

  // 更新网络状态
  void updateNetworkStatus(bool online, {String? serverStatus}) {
    isOnline.value = online;
    if (serverStatus != null) {
      this.serverStatus.value = serverStatus;
    }

    if (!online) {
      Get.snackbar('网络提示', '网络连接已断开');
    }
  }

  // 更新通知计数
  void updateUnreadCount(int count) {
    unreadCount.value = count;
    hasNewMessage.value = count > 0;
  }

  // 更新蓝牙状态（保持现有接口）
  void updateBluetoothStatus({
    required bool enabled,
    required bool connected,
    String deviceName = '',
  }) {
    isBluetoothEnabled.value = enabled;
    isBluetoothConnected.value = connected;
    bluetoothDeviceName.value = deviceName;
  }

  // 导航
  void navigateTo(String route) {
    currentRoute.value = route;
    Get.toNamed(route);
  }

  // 返回
  void goBack() {
    Get.back();
  }

  // 显示错误
  void showError(String message, {String title = '错误'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  // 显示成功
  void showSuccess(String message, {String title = '成功'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  // 重置所有状态（登出时使用）
  void resetAll() {
    unreadCount.value = 0;
    hasNewMessage.value = false;
    isBluetoothEnabled.value = false;
    isBluetoothConnected.value = false;
    bluetoothDeviceName.value = '';
    currentRoute.value = '/';
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化逻辑
    _initialize();
  }

  void _initialize() async {
    // 这里可以添加初始化逻辑
    // 比如检查网络、加载设置等
  }
}
