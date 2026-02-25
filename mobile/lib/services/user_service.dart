import 'package:get/get.dart';
import 'base_service.dart';
import '../models/user_model.dart';

/// 用户查询服务 - 处理用户查询相关API
class UserService extends BaseService {
  static UserService get instance => Get.find();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxMap<String, UserModel> userCache = <String, UserModel>{}.obs;

  /// 通过 bipupu_id 获取用户信息
  Future<ServiceResponse<UserModel>> getUserByBipupuId(String bipupuId) async {
    isLoading.value = true;
    error.value = '';

    // 检查缓存
    if (userCache.containsKey(bipupuId)) {
      isLoading.value = false;
      return ServiceResponse.success(userCache[bipupuId]!);
    }

    final response = await get<UserModel>(
      '/api/users/$bipupuId',
      fromJson: (json) => UserModel.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      // 缓存用户信息
      userCache[bipupuId] = response.data!;
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 批量获取用户信息
  Future<ServiceResponse<List<UserModel>>> getUsersByBipupuIds(
    List<String> bipupuIds,
  ) async {
    isLoading.value = true;
    error.value = '';

    final results = <UserModel>[];
    final missingIds = <String>[];

    // 首先从缓存中获取已有的用户
    for (final id in bipupuIds) {
      if (userCache.containsKey(id)) {
        results.add(userCache[id]!);
      } else {
        missingIds.add(id);
      }
    }

    // 如果所有用户都在缓存中，直接返回
    if (missingIds.isEmpty) {
      isLoading.value = false;
      return ServiceResponse.success(results);
    }

    // 批量查询缺失的用户
    final missingUsers = <UserModel>[];
    for (final id in missingIds) {
      final response = await getUserByBipupuId(id);
      if (response.success && response.data != null) {
        missingUsers.add(response.data!);
      }
    }

    isLoading.value = false;
    results.addAll(missingUsers);
    return ServiceResponse.success(results);
  }

  /// 搜索用户（根据后端API设计，这里可能需要扩展）
  Future<ServiceResponse<List<UserModel>>> searchUsers({
    String? keyword,
    int? limit,
  }) async {
    isLoading.value = true;
    error.value = '';

    // 注意：后端可能没有专门的搜索API
    // 这里先实现一个简单的缓存搜索
    final searchResults = <UserModel>[];

    if (keyword != null && keyword.isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();
      for (final user in userCache.values) {
        if (user.username.toLowerCase().contains(lowerKeyword) ||
            (user.nickname != null &&
                user.nickname!.toLowerCase().contains(lowerKeyword)) ||
            user.bipupuId.toLowerCase().contains(lowerKeyword)) {
          searchResults.add(user);
        }
      }
    } else {
      // 如果没有关键词，返回所有缓存用户
      searchResults.addAll(userCache.values.toList());
    }

    // 应用限制
    if (limit != null && searchResults.length > limit) {
      searchResults.length = limit;
    }

    isLoading.value = false;
    return ServiceResponse.success(searchResults);
  }

  /// 验证用户是否存在
  Future<ServiceResponse<bool>> validateUserExists(String bipupuId) async {
    final response = await getUserByBipupuId(bipupuId);
    return ServiceResponse.success(response.success);
  }

  /// 获取用户基本信息（轻量级查询）
  Future<ServiceResponse<Map<String, dynamic>>> getUserBasicInfo(
    String bipupuId,
  ) async {
    final response = await getUserByBipupuId(bipupuId);

    if (response.success && response.data != null) {
      final user = response.data!;
      final basicInfo = {
        'bipupuId': user.bipupuId,
        'username': user.username,
        'nickname': user.nickname,
        'avatarUrl': user.avatarUrl,
        'isActive': user.isActive,
        'lastActive': user.lastActive?.toIso8601String(),
      };
      return ServiceResponse.success(basicInfo);
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取用户信息失败', ServiceErrorType.unknown),
    );
  }

  /// 清除用户缓存
  void clearCache() {
    userCache.clear();
    error.value = '';
  }

  /// 清除特定用户的缓存
  void clearUserCache(String bipupuId) {
    userCache.remove(bipupuId);
  }

  /// 更新用户缓存
  void updateUserCache(UserModel user) {
    userCache[user.bipupuId] = user;
  }

  /// 批量更新用户缓存
  void updateUsersCache(List<UserModel> users) {
    for (final user in users) {
      userCache[user.bipupuId] = user;
    }
  }

  /// 获取缓存中的用户数量
  int get cachedUserCount => userCache.length;

  /// 获取最近查询的用户（按查询时间排序，这里简化处理）
  List<UserModel> get recentlyQueriedUsers {
    return userCache.values.toList();
  }

  /// 获取活跃用户（最近有活动的用户）
  List<UserModel> get activeUsers {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return userCache.values
        .where(
          (user) =>
              user.lastActive != null && user.lastActive!.isAfter(oneWeekAgo),
        )
        .toList();
  }

  /// 初始化用户服务
  Future<void> initialize() async {
    // 可以在这里预加载一些常用用户
    // 例如：当前用户的好友、联系人等
    clearCache();
  }

  /// 预加载用户信息
  Future<void> preloadUsers(List<String> bipupuIds) async {
    if (bipupuIds.isEmpty) return;

    // 过滤掉已经在缓存中的用户
    final idsToLoad = bipupuIds
        .where((id) => !userCache.containsKey(id))
        .toList()
        .take(10); // 限制一次最多预加载10个用户

    if (idsToLoad.isEmpty) return;

    // 并行加载用户信息
    final futures = <Future<ServiceResponse<UserModel>>>[];
    for (final id in idsToLoad) {
      futures.add(getUserByBipupuId(id));
    }

    await Future.wait(futures);
  }

  /// 获取用户统计信息
  Map<String, dynamic> get userStats {
    final totalUsers = userCache.length;
    final activeUsersCount = activeUsers.length;
    final superusers = userCache.values
        .where((user) => user.isSuperuser)
        .length;

    return {
      'totalCached': totalUsers,
      'activeUsers': activeUsersCount,
      'inactiveUsers': totalUsers - activeUsersCount,
      'superusers': superusers,
      'cacheHitRate': totalUsers > 0 ? (totalUsers / (totalUsers + 1)) : 0,
    };
  }

  /// 查找用户（支持多种条件）
  List<UserModel> findUsers({
    String? username,
    String? nickname,
    bool? isActive,
    bool? isSuperuser,
    int? limit,
  }) {
    var results = userCache.values.toList();

    // 应用过滤条件
    if (username != null && username.isNotEmpty) {
      final lowerUsername = username.toLowerCase();
      results = results
          .where((user) => user.username.toLowerCase().contains(lowerUsername))
          .toList();
    }

    if (nickname != null && nickname.isNotEmpty) {
      final lowerNickname = nickname.toLowerCase();
      results = results
          .where(
            (user) =>
                user.nickname != null &&
                user.nickname!.toLowerCase().contains(lowerNickname),
          )
          .toList();
    }

    if (isActive != null) {
      results = results.where((user) => user.isActive == isActive).toList();
    }

    if (isSuperuser != null) {
      results = results
          .where((user) => user.isSuperuser == isSuperuser)
          .toList();
    }

    // 应用限制
    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }
}
