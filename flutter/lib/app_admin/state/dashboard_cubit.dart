import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/injection/service_locator.dart';

/// 仪表盘状态
class DashboardState {
  final List<UserResponse> recentUsers;
  final List<DeviceResponse> recentDevices;
  final List<MessageResponse> recentMessages;
  final bool loading;
  final String? error;

  const DashboardState({
    this.recentUsers = const [],
    this.recentDevices = const [],
    this.recentMessages = const [],
    this.loading = false,
    this.error,
  });

  DashboardState copyWith({
    List<UserResponse>? recentUsers,
    List<DeviceResponse>? recentDevices,
    List<MessageResponse>? recentMessages,
    bool? loading,
    String? error,
  }) {
    return DashboardState(
      recentUsers: recentUsers ?? this.recentUsers,
      recentDevices: recentDevices ?? this.recentDevices,
      recentMessages: recentMessages ?? this.recentMessages,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  /// 获取用户总数
  int get totalUsers => recentUsers.length;

  /// 获取设备总数
  int get totalDevices => recentDevices.length;

  /// 获取消息总数
  int get totalMessages => recentMessages.length;

  /// 获取活跃用户数量
  int get activeUsers =>
      recentUsers.where((user) => user.isActive == true).length;
}

/// 仪表盘Cubit
class DashboardCubit extends Cubit<DashboardState> {
  final UsersApi _usersApi;
  final DevicesApi _devicesApi;
  final MessagesApi _messagesApi;

  DashboardCubit({
    UsersApi? usersApi,
    DevicesApi? devicesApi,
    MessagesApi? messagesApi,
  }) : _usersApi =
           usersApi ?? ServiceLocatorConfig.get<Openapi>().getUsersApi(),
       _devicesApi =
           devicesApi ?? ServiceLocatorConfig.get<Openapi>().getDevicesApi(),
       _messagesApi =
           messagesApi ?? ServiceLocatorConfig.get<Openapi>().getMessagesApi(),
       super(const DashboardState());

  /// 加载仪表盘数据
  Future<void> loadDashboardData() async {
    emit(state.copyWith(loading: true, error: null));

    try {
      // 并行加载所有数据
      final usersResult = await _usersApi.adminGetAllUsersApiUsersAdminAllGet(
        skip: 0,
        limit: 5,
      );
      final devicesResult = await _devicesApi.getDevicesApiDevicesGet();
      final messagesResult = await _messagesApi
          .adminGetAllMessagesApiMessagesAdminAllGet();

      final users = (usersResult.data as List<UserResponse>? ?? []);
      final devices = (devicesResult.data as List<DeviceResponse>? ?? []);
      final messages = (messagesResult.data as List<MessageResponse>? ?? []);

      emit(
        state.copyWith(
          recentUsers: users,
          recentDevices: devices,
          recentMessages: messages.take(5).toList(),
          loading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: '仪表盘数据加载失败: $e'));
    }
  }

  /// 获取用户总数
  int get totalUsers => state.recentUsers.length;

  /// 获取设备总数
  int get totalDevices => state.recentDevices.length;

  /// 获取消息总数
  int get totalMessages => state.recentMessages.length;

  /// 获取活跃用户数量（简化计算，假设前5个用户都是活跃的）
  int get activeUsers =>
      state.recentUsers.where((user) => user.isActive == true).length;
}
