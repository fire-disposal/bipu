/// 好友管理Cubit
/// 管理好友关系、好友请求等社交功能
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/core.dart';
import 'package:openapi/openapi.dart';

/// 自定义好友状态枚举
enum FriendshipStatus { pending, accepted, blocked, none }

/// 扩展AppSchemasFriendshipFriendshipStatus转换
extension FriendshipStatusExtension on AppSchemasFriendshipFriendshipStatus {
  FriendshipStatus toCustomStatus() {
    switch (this) {
      case AppSchemasFriendshipFriendshipStatus.pending:
        return FriendshipStatus.pending;
      case AppSchemasFriendshipFriendshipStatus.accepted:
        return FriendshipStatus.accepted;
      case AppSchemasFriendshipFriendshipStatus.blocked:
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.none;
    }
  }
}

/// 好友管理状态
abstract class FriendshipState extends Equatable {
  const FriendshipState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class FriendshipInitial extends FriendshipState {
  const FriendshipInitial();
}

/// 加载中状态
class FriendshipLoading extends FriendshipState {
  const FriendshipLoading();
}

/// 数据加载完成
class FriendshipLoaded extends FriendshipState {
  final List<FriendInfo> friends;
  final List<FriendRequestInfo> friendRequests;
  final List<FriendshipInfo> friendships;
  final bool hasPendingRequests;

  const FriendshipLoaded({
    required this.friends,
    required this.friendRequests,
    required this.friendships,
    this.hasPendingRequests = false,
  });

  @override
  List<Object?> get props => [
    friends,
    friendRequests,
    friendships,
    hasPendingRequests,
  ];
}

/// 错误状态
class FriendshipError extends FriendshipState {
  final String message;

  const FriendshipError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 好友信息
class FriendInfo {
  final String id;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final FriendshipStatus status;

  const FriendInfo({
    required this.id,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.status,
  });
}

/// 好友请求信息
class FriendRequestInfo {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderNickname;
  final String? message;
  final DateTime createdAt;
  final FriendshipStatus status;

  const FriendRequestInfo({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderNickname,
    this.message,
    required this.createdAt,
    required this.status,
  });
}

/// 好友关系信息
class FriendshipInfo {
  final String id;
  final String userId;
  final String friendId;
  final String friendUsername;
  final String? friendNickname;
  final FriendshipStatus status;
  final DateTime createdAt;

  const FriendshipInfo({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendUsername,
    this.friendNickname,
    required this.status,
    required this.createdAt,
  });
}

/// 好友管理Cubit
class FriendshipCubit extends Cubit<FriendshipState> {
  final ApiClient _apiClient;

  FriendshipCubit()
    : _apiClient = ServiceLocatorConfig.get<ApiClient>(),
      super(const FriendshipInitial()) {
    _initialize();
  }

  /// 初始化好友数据
  Future<void> _initialize() async {
    emit(const FriendshipLoading());

    try {
      // 获取好友列表
      final friends = await _getFriends();

      // 获取好友请求
      final friendRequests = await _getFriendRequests();

      // 获取好友关系
      final friendships = await _getFriendships();

      // 检查是否有待处理请求
      final hasPendingRequests = friendRequests.any(
        (request) => request.status == FriendshipStatus.pending,
      );

      emit(
        FriendshipLoaded(
          friends: friends,
          friendRequests: friendRequests,
          friendships: friendships,
          hasPendingRequests: hasPendingRequests,
        ),
      );
    } catch (e) {
      Logger.error('好友数据初始化失败: $e');
      emit(FriendshipError('加载好友数据失败: $e'));
    }
  }

  /// 获取好友列表
  Future<List<FriendInfo>> _getFriends() async {
    try {
      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .getFriendsApiFriendshipsFriendsGet();

      if (response.statusCode == 200 && response.data != null) {
        return response.data!.map((user) {
          return FriendInfo(
            id: user.id.toString(),
            username: user.username,
            nickname: user.nickname,
            avatarUrl: null,
            isOnline: false,
            lastSeen: null,
            status: FriendshipStatus.accepted,
          );
        }).toList();
      }
    } catch (e) {
      Logger.error('获取好友列表失败: $e');
    }

    return [];
  }

  /// 获取好友请求
  Future<List<FriendRequestInfo>> _getFriendRequests() async {
    try {
      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .getFriendRequestsApiFriendshipsRequestsGet();

      if (response.statusCode == 200 && response.data != null) {
        return response.data!.items.map((friendship) {
          return FriendRequestInfo(
            id: friendship.id.toString(),
            senderId: friendship.userId.toString(),
            senderUsername: friendship.userId.toString(),
            senderNickname: null,
            message: null,
            createdAt: friendship.createdAt,
            status:
                friendship.status?.toCustomStatus() ?? FriendshipStatus.pending,
          );
        }).toList();
      }
    } catch (e) {
      Logger.error('获取好友请求失败: $e');
    }

    return [];
  }

  /// 获取好友关系
  Future<List<FriendshipInfo>> _getFriendships() async {
    try {
      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .getFriendshipsApiFriendshipsGet();

      if (response.statusCode == 200 && response.data != null) {
        return response.data!.items.map((friendship) {
          return FriendshipInfo(
            id: friendship.id.toString(),
            userId: friendship.userId.toString(),
            friendId: friendship.friendId.toString(),
            friendUsername: friendship.friendId.toString(),
            friendNickname: null,
            status:
                friendship.status?.toCustomStatus() ?? FriendshipStatus.pending,
            createdAt: friendship.createdAt,
          );
        }).toList();
      }
    } catch (e) {
      Logger.error('获取好友关系失败: $e');
    }

    return [];
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(String friendId, {String? message}) async {
    if (state is! FriendshipLoaded) return;

    try {
      // 获取当前用户信息
      final userResponse = await _apiClient.openapi
          .getUsersApi()
          .getCurrentUserInfoApiUsersMeGet();

      if (userResponse.statusCode != 200 || userResponse.data == null) {
        throw Exception('无法获取当前用户信息');
      }

      final currentUserId = userResponse.data!.id;

      final request = FriendshipCreate(
        (b) => b
          ..userId = currentUserId
          ..friendId = int.parse(friendId)
          ..status = AppSchemasFriendshipFriendshipStatus.pending,
      );

      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .createFriendRequestApiFriendshipsPost(friendshipCreate: request);

      if (response.statusCode == 201) {
        // 重新加载数据
        await _initialize();
        Logger.info('好友请求发送成功: $friendId');
      } else {
        throw Exception('发送好友请求失败: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('发送好友请求失败: $e');
      emit(FriendshipError('发送好友请求失败: $e'));
    }
  }

  /// 接受好友请求
  Future<void> acceptFriendRequest(String requestId) async {
    if (state is! FriendshipLoaded) return;

    try {
      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut(
            friendshipId: int.parse(requestId),
          );

      if (response.statusCode == 200) {
        // 重新加载数据
        await _initialize();
        Logger.info('好友请求已接受: $requestId');
      } else {
        throw Exception('接受好友请求失败: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('接受好友请求失败: $e');
      emit(FriendshipError('接受好友请求失败: $e'));
    }
  }

  /// 拒绝好友请求
  Future<void> rejectFriendRequest(String requestId) async {
    if (state is! FriendshipLoaded) return;

    try {
      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .rejectFriendRequestApiFriendshipsFriendshipIdRejectPut(
            friendshipId: int.parse(requestId),
          );

      if (response.statusCode == 200) {
        // 重新加载数据
        await _initialize();
        Logger.info('好友请求已拒绝: $requestId');
      } else {
        throw Exception('拒绝好友请求失败: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('拒绝好友请求失败: $e');
      emit(FriendshipError('拒绝好友请求失败: $e'));
    }
  }

  /// 删除好友
  Future<void> deleteFriend(String friendshipId) async {
    if (state is! FriendshipLoaded) return;

    try {
      final response = await _apiClient.openapi
          .getFriendshipsApi()
          .deleteFriendApiFriendshipsFriendshipIdDelete(
            friendshipId: int.parse(friendshipId),
          );

      if (response.statusCode == 204) {
        // 重新加载数据
        await _initialize();
        Logger.info('好友已删除: $friendshipId');
      } else {
        throw Exception('删除好友失败: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('删除好友失败: $e');
      emit(FriendshipError('删除好友失败: $e'));
    }
  }

  /// 搜索用户
  Future<List<FriendInfo>> searchUsers(String query) async {
    try {
      // 使用用户API搜索用户
      final response = await _apiClient.openapi
          .getUsersApi()
          .getUsersApiUsersGet();

      if (response.statusCode == 200 && response.data != null) {
        return response.data!
            .where(
              (user) =>
                  user.username.contains(query) ||
                  (user.nickname?.contains(query) ?? false),
            )
            .map((user) {
              return FriendInfo(
                id: user.id.toString(),
                username: user.username,
                nickname: user.nickname,
                avatarUrl: null,
                isOnline: false,
                lastSeen: null,
                status: FriendshipStatus.none,
              );
            })
            .toList();
      }
    } catch (e) {
      Logger.error('搜索用户失败: $e');
    }

    return [];
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _initialize();
  }

  /// 获取待处理请求数量
  int getPendingRequestCount() {
    if (state is FriendshipLoaded) {
      final currentState = state as FriendshipLoaded;
      return currentState.friendRequests
          .where((request) => request.status == FriendshipStatus.pending)
          .length;
    }
    return 0;
  }

  /// 获取在线好友数量
  int getOnlineFriendCount() {
    if (state is FriendshipLoaded) {
      final currentState = state as FriendshipLoaded;
      return currentState.friends.where((friend) => friend.isOnline).length;
    }
    return 0;
  }
}
