import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

/// 轮播数据
class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? link;

  BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.link,
  });
}

/// 广场动态数据
class FeedItem {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  FeedItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });
}

/// 首页状态
enum HomeStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 已加载
  loaded,

  /// 错误
  error,
}

/// 首页提供者
final homeProvider = NotifierProvider<HomeNotifier, HomeStatus>(
  () => HomeNotifier(),
);

class HomeNotifier extends Notifier<HomeStatus> {
  final List<BannerItem> _banners = [];
  final List<FeedItem> _feeds = [];

  List<BannerItem> get banners => _banners;
  List<FeedItem> get feeds => _feeds;

  @override
  HomeStatus build() {
    return HomeStatus.initial;
  }

  /// 刷新首页数据
  Future<void> refresh() async {
    state = HomeStatus.loading;

    try {
      // TODO: 调用 API 获取首页数据
      await Future.delayed(const Duration(seconds: 1));

      // 模拟数据
      _banners.clear();
      _feeds.clear();

      state = HomeStatus.loaded;
    } catch (e) {
      debugPrint('[Home] 刷新首页数据失败：$e');
      state = HomeStatus.error;
    }
  }

  /// 获取轮播数据
  Future<List<BannerItem>> loadBanners() async {
    try {
      // TODO: 调用 API
      return _banners;
    } catch (e) {
      debugPrint('[Home] 加载轮播数据失败：$e');
      return [];
    }
  }

  /// 获取广场动态
  Future<List<FeedItem>> loadFeeds() async {
    try {
      // TODO: 调用 API
      return _feeds;
    } catch (e) {
      debugPrint('[Home] 加载广场动态失败：$e');
      return [];
    }
  }
}

/// 轮播数据提供者（简化版）
final bannersProvider = FutureProvider<List<BannerItem>>((ref) async {
  // TODO: 从 API 获取轮播数据
  return [];
});

/// 广场动态提供者（简化版）
final feedsProvider = FutureProvider<List<FeedItem>>((ref) async {
  // TODO: 从 API 获取动态数据
  return [];
});
