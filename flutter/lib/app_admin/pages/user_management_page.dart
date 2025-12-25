import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/state/state.dart' as app_state;
import '../widgets/admin_data_table.dart';
import '../state/admin_state.dart';

/// 管理端-用户管理页面
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late final UserManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = UserManagementCubit();
    _cubit.loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showUserDetail(UserResponse user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户详情'),
        content: SingleChildScrollView(child: Text(user.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showUserForm({UserResponse? user}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.username ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final isActive = ValueNotifier<bool>(user?.isActive ?? true);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? '新增用户' : '编辑用户'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '用户名'),
                  validator: (v) => v?.isEmpty == true ? '请输入用户名' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  validator: (v) => v?.isEmpty == true ? '请输入邮箱' : null,
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isActive,
                  builder: (context, val, _) => CheckboxListTile(
                    title: const Text('激活状态'),
                    value: val,
                    onChanged: (v) => isActive.value = v ?? false,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (user == null) {
                  await _cubit.createUser(
                    username: nameController.text,
                    email: emailController.text,
                    password: 'default123',
                  );
                } else {
                  await _cubit.updateUser(
                    userId: user.id,
                    username: nameController.text,
                    email: emailController.text,
                    isActive: isActive.value,
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(UserResponse user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除用户 ${user.username} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cubit.deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增用户',
            onPressed: () => _showUserForm(),
          ),
        ],
      ),
      body: BlocBuilder<UserManagementCubit, app_state.ListState<UserResponse>>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          return AdminDataTable<UserResponse>(
            data: state.items,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('用户名')),
              DataColumn(label: Text('邮箱')),
              DataColumn(label: Text('状态')),
            ],
            buildRows: (data) => data
                .map(
                  (user) => DataRow(
                    cells: [
                      DataCell(Text('${user.id}')),
                      DataCell(Text(user.username)),
                      DataCell(Text(user.email)),
                      DataCell(Text(user.isActive == true ? '激活' : '禁用')),
                    ],
                  ),
                )
                .toList(),
            onView: (_, user) => _showUserDetail(user),
            onEdit: (_, user) => _showUserForm(user: user),
            onDelete: (_, user) => _confirmDelete(user),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cubit.refreshData(),
        tooltip: '刷新用户',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
