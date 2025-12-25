import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/injection/service_locator.dart';

class AdminLogState {
  final List<AdminLogResponse> logs;
  final bool loading;
  final String? error;

  const AdminLogState({this.logs = const [], this.loading = false, this.error});

  AdminLogState copyWith({
    List<AdminLogResponse>? logs,
    bool? loading,
    String? error,
  }) {
    return AdminLogState(
      logs: logs ?? this.logs,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class AdminLogCubit extends Cubit<AdminLogState> {
  final AdminLogsApi _api;

  AdminLogCubit({AdminLogsApi? api})
    : _api = api ?? ServiceLocatorConfig.get<Openapi>().getAdminLogsApi(),
      super(const AdminLogState());

  Future<void> loadLogs() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await _api.getAdminLogsApiAdminLogsGet();
      final logs = (res.data as List<AdminLogResponse>? ?? []);
      emit(state.copyWith(logs: logs, loading: false));
    } catch (e) {
      emit(state.copyWith(error: '日志获取失败: $e', loading: false));
    }
  }
}
