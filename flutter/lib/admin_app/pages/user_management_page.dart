import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../core/widgets/core_card.dart';
import '../../core/widgets/core_button.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_form_builder.dart';

/// 用户管理页面，展示用户列表和编辑功能
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  bool _showForm = false;
  int? _editingIndex;

  // 模拟用户数据
  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'username': 'admin',
      'email': 'admin@example.com',
      'phone': '13800138000',
      'status': 'active',
      'role': '管理员',
      'createdAt': '2024-01-01',
    },
    {
      'id': 2,
      'username': 'user1',
      'email': 'user1@example.com',
      'phone': '13900139000',
      'status': 'active',
      'role': '普通用户',
      'createdAt': '2024-01-02',
    },
    {
      'id': 3,
      'username': 'user2',
      'email': 'user2@example.com',
      'phone': '13700137000',
      'status': 'inactive',
      'role': '普通用户',
      'createdAt': '2024-01-03',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _buildFormPage();
    }
    return _buildListPage();
  }

  Widget _buildListPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('用户管理', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: AdminDataTable<Map<String, dynamic>>(
              title: Text('用户列表 (${_users.length}条记录)'),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('用户名')),
                DataColumn(label: Text('邮箱')),
                DataColumn(label: Text('手机号')),
                DataColumn(label: Text('状态')),
                DataColumn(label: Text('角色')),
                DataColumn(label: Text('创建时间')),
              ],
              data: _users,
              buildRows: (data) => data.map((user) {
                return DataRow(
                  cells: [
                    DataCell(Text(user['id'].toString())),
                    DataCell(Text(user['username'])),
                    DataCell(Text(user['email'])),
                    DataCell(Text(user['phone'])),
                    DataCell(
                      Chip(
                        label: Text(
                          user['status'] == 'active' ? '活跃' : '禁用',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: user['status'] == 'active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: user['status'] == 'active'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(Text(user['role'])),
                    DataCell(Text(user['createdAt'])),
                  ],
                );
              }).toList(),
              onEdit: (index, user) => _editUser(index),
              onDelete: (index, user) => _deleteUser(index),
              onView: (index, user) => _viewUser(index),
              onSearch: (query) {
                // 实现搜索逻辑
                setState(() {
                  // 这里应该更新_filteredData
                });
              },
              actions: [
                CoreButton(
                  label: '添加用户',
                  onPressed: _addUser,
                  icon: Icons.person_add,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showForm = false),
              ),
              const SizedBox(width: 8),
              Text(
                _editingIndex == null ? '添加用户' : '编辑用户',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          CoreCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AdminFormBuilder(
                formKey: _formKey,
                fields: [
                  FormFieldConfig(
                    name: 'username',
                    label: '用户名',
                    type: FormFieldType.text,
                    icon: Icons.person,
                    required: true,
                    initialValue: _editingIndex != null
                        ? _users[_editingIndex!]['username']
                        : '',
                  ),
                  FormFieldConfig(
                    name: 'email',
                    label: '邮箱',
                    type: FormFieldType.email,
                    icon: Icons.email,
                    required: true,
                    initialValue: _editingIndex != null
                        ? _users[_editingIndex!]['email']
                        : '',
                  ),
                  FormFieldConfig(
                    name: 'phone',
                    label: '手机号',
                    type: FormFieldType.text,
                    icon: Icons.phone,
                    required: true,
                    initialValue: _editingIndex != null
                        ? _users[_editingIndex!]['phone']
                        : '',
                  ),
                  FormFieldConfig(
                    name: 'role',
                    label: '角色',
                    type: FormFieldType.dropdown,
                    icon: Icons.badge,
                    required: true,
                    initialValue: _editingIndex != null
                        ? _users[_editingIndex!]['role']
                        : '普通用户',
                    options: const [
                      DropdownOption(value: '管理员', label: '管理员'),
                      DropdownOption(value: '普通用户', label: '普通用户'),
                      DropdownOption(value: '访客', label: '访客'),
                    ],
                  ),
                  FormFieldConfig(
                    name: 'status',
                    label: '状态',
                    type: FormFieldType.dropdown,
                    icon: Icons.toggle_on,
                    required: true,
                    initialValue: _editingIndex != null
                        ? _users[_editingIndex!]['status']
                        : 'active',
                    options: const [
                      DropdownOption(value: 'active', label: '活跃'),
                      DropdownOption(value: 'inactive', label: '禁用'),
                    ],
                  ),
                ],
                onSubmit: _submitForm,
                submitButtonText: _editingIndex == null ? '添加用户' : '保存修改',
                loading: _loading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addUser() {
    setState(() {
      _showForm = true;
      _editingIndex = null;
      _formKey.currentState?.reset();
    });
  }

  void _editUser(int index) {
    setState(() {
      _showForm = true;
      _editingIndex = index;
    });
  }

  void _viewUser(int index) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('查看用户详情功能开发中...')));
  }

  void _deleteUser(int index) {
    setState(() {
      _users.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('用户删除成功')));
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    _formKey.currentState!.save();
    final formData = _formKey.currentState!.value;

    // 模拟API调用
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      if (_editingIndex == null) {
        // 添加新用户
        _users.add({
          'id': _users.length + 1,
          ...formData,
          'createdAt': DateTime.now().toString().split(' ')[0],
        });
      } else {
        // 编辑现有用户
        _users[_editingIndex!] = {..._users[_editingIndex!], ...formData};
      }
      _loading = false;
      _showForm = false;
      _editingIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingIndex == null ? '用户添加成功' : '用户修改成功')),
    );
  }
}
