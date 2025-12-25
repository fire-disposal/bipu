import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';
import '../state/device_management_cubit.dart';

/// 管理端-设备管理页面
class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  late final DeviceManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DeviceManagementCubit();
    _cubit.loadDevices();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showDeviceDetail(DeviceResponse device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备详情'),
        content: SingleChildScrollView(child: Text(device.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
      body: BlocBuilder<DeviceManagementCubit, DeviceManagementState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          return AdminDataTable<DeviceResponse>(
            data: state.devices,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('设备标识')),
              DataColumn(label: Text('绑定用户')),
              DataColumn(label: Text('最后在线')),
              DataColumn(label: Text('操作')),
            ],
            buildRows: (data) => data
                .map(
                  (device) => DataRow(
                    cells: [
                      DataCell(Text('${device.id}')),
                      DataCell(Text(device.deviceIdentifier)),
                      DataCell(Text('${device.userId}')),
                      DataCell(Text('${device.lastSeen ?? '从未'}')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showDeviceDetail(device),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cubit.loadDevices(),
        tooltip: '刷新设备',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
