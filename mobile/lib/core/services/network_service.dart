import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络连接状态
enum NetworkStatus {
  /// 已连接（WiFi）
  connectedWifi,

  /// 已连接（移动数据）
  connectedMobile,

  /// 已连接（其他）
  connectedOther,

  /// 未连接
  disconnected,

  /// 检查中
  checking,
}

/// 网络状态服务
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  /// 检查当前网络连接状态
  Future<NetworkStatus> checkConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      // connectivity_plus 6.x 返回 List<ConnectivityResult>，取第一个结果
      if (connectivityResult.isNotEmpty) {
        return _mapConnectivityResult(connectivityResult.first);
      }
      return NetworkStatus.disconnected;
    } catch (e) {
      debugPrint('[NetworkService] 检查网络连接失败: $e');
      return NetworkStatus.disconnected;
    }
  }

  /// 监听网络连接状态变化
  Stream<NetworkStatus> get onConnectionChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      if (results.isNotEmpty) {
        return _mapConnectivityResult(results.first);
      }
      return NetworkStatus.disconnected;
    });
  }

  /// 将 ConnectivityResult 映射为 NetworkStatus
  NetworkStatus _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkStatus.connectedWifi;
      case ConnectivityResult.mobile:
        return NetworkStatus.connectedMobile;
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.other:
        return NetworkStatus.connectedOther;
      case ConnectivityResult.none:
        return NetworkStatus.disconnected;
    }
  }

  /// 检查是否有任何网络连接
  Future<bool> hasConnection() async {
    final status = await checkConnection();
    return status != NetworkStatus.disconnected;
  }

  /// 获取网络连接类型描述
  String getConnectionDescription(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connectedWifi:
        return 'WiFi网络';
      case NetworkStatus.connectedMobile:
        return '移动网络';
      case NetworkStatus.connectedOther:
        return '其他网络';
      case NetworkStatus.disconnected:
        return '无网络连接';
      case NetworkStatus.checking:
        return '检查网络中...';
    }
  }

  /// 获取网络连接图标
  String getConnectionIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connectedWifi:
        return '📶'; // WiFi图标
      case NetworkStatus.connectedMobile:
        return '📱'; // 移动网络图标
      case NetworkStatus.connectedOther:
        return '🔗'; // 其他网络图标
      case NetworkStatus.disconnected:
        return '❌'; // 无连接图标
      case NetworkStatus.checking:
        return '⏳'; // 加载中图标
    }
  }
}

/// 网络状态提供者
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

/// 当前网络状态提供者
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final networkService = ref.watch(networkServiceProvider);
  return networkService.onConnectionChanged;
});

/// 是否有网络连接提供者
final hasNetworkConnectionProvider = Provider<bool>((ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.when(
    data: (status) => status != NetworkStatus.disconnected,
    loading: () => true, // 加载时假设有连接，避免阻塞
    error: (_, __) => false, // 出错时假设无连接
  );
});

/// 网络连接类型描述提供者
final networkDescriptionProvider = Provider<String>((ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  final networkService = ref.watch(networkServiceProvider);

  return networkStatus.when(
    data: (status) => networkService.getConnectionDescription(status),
    loading: () => '检查网络中...',
    error: (_, __) => '网络状态未知',
  );
});

/// 网络连接工具类
class NetworkUtils {
  /// 检查网络连接并显示提示
  static Future<bool> checkAndShowToast(
    WidgetRef ref, {
    String? noConnectionMessage,
  }) async {
    final networkService = ref.read(networkServiceProvider);
    final hasConnection = await networkService.hasConnection();

    if (!hasConnection) {
      // 这里可以集成Toast显示，但为了解耦，我们返回false让调用方处理
      debugPrint('[NetworkUtils] 无网络连接');
      return false;
    }

    return true;
  }

  /// 监听网络状态变化并执行回调
  static StreamSubscription<NetworkStatus>? listenToNetworkChanges(
    WidgetRef ref,
    void Function(NetworkStatus status) onChanged,
  ) {
    final networkService = ref.read(networkServiceProvider);
    return networkService.onConnectionChanged.listen(onChanged);
  }

  /// 等待网络连接恢复
  static Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final networkService = NetworkService();
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      final hasConnection = await networkService.hasConnection();
      if (hasConnection) {
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    return false;
  }
}
