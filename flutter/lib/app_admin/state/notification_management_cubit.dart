import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/injection/service_locator.dart';

class NotificationManagementState {
  final List<NotificationResponse> notifications;
  final bool loading;
  final String? error;

  const NotificationManagementState({
    this.notifications = const [],
    this.loading = false,
    this.error,
  });

  NotificationManagementState copyWith({
    List<NotificationResponse>? notifications,
    bool? loading,
    String? error,
  }) {
    return NotificationManagementState(
      notifications: notifications ?? this.notifications,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class NotificationManagementCubit extends Cubit<NotificationManagementState> {
  final NotificationsApi _api;

  NotificationManagementCubit({NotificationsApi? api})
    : _api = api ?? ServiceLocatorConfig.get<Openapi>().getNotificationsApi(),
      super(const NotificationManagementState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await _api.getNotificationsApiNotificationsGet();
      final notifications = (res.data as List<NotificationResponse>? ?? []);
      emit(state.copyWith(notifications: notifications, loading: false));
    } catch (e) {
      emit(state.copyWith(error: '通知获取失败: $e', loading: false));
    }
  }
}
