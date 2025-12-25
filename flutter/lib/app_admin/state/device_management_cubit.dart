import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/injection/service_locator.dart';

class DeviceManagementState {
  final List<DeviceResponse> devices;
  final bool loading;
  final String? error;

  const DeviceManagementState({
    this.devices = const [],
    this.loading = false,
    this.error,
  });

  DeviceManagementState copyWith({
    List<DeviceResponse>? devices,
    bool? loading,
    String? error,
  }) {
    return DeviceManagementState(
      devices: devices ?? this.devices,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class DeviceManagementCubit extends Cubit<DeviceManagementState> {
  final DevicesApi _api;

  DeviceManagementCubit({DevicesApi? api})
    : _api = api ?? ServiceLocatorConfig.get<Openapi>().getDevicesApi(),
      super(const DeviceManagementState());

  Future<void> loadDevices() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await _api.getDevicesApiDevicesGet();
      final devices = (res.data as List<DeviceResponse>? ?? []);
      emit(state.copyWith(devices: devices, loading: false));
    } catch (e) {
      emit(state.copyWith(error: '设备获取失败: $e', loading: false));
    }
  }
}
