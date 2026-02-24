import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/models/contact_model.dart';
import '../logic/contact_provider.dart';

/// 联系人列表界面
class ContactsScreen extends HookConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactState = ref.watch(contactsProvider);
    final contactController = ref.read(contactControllerProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');

    // 初始化加载联系人
    useEffect(() {
      contactController.loadContacts();
      return null;
    }, []);

    // 过滤联系人列表
    final filteredContacts = contactState.contacts.where((contact) {
      if (searchQuery.value.isEmpty) return true;

      final query = searchQuery.value.toLowerCase();
      return contact.nickname?.toLowerCase().contains(query) == true ||
          contact.username.toLowerCase().contains(query) ||
          contact.contactBipupuId.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('联系人'), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ShadInput(
              controller: searchController,
              placeholder: const Text('搜索联系人...'),
              onChanged: (value) {
                searchQuery.value = value;
              },
            ),
          ),

          // 联系人列表
          Expanded(
            child: _buildContactList(
              context,
              contactState,
              filteredContacts,
              contactController,
              searchQuery.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(
    BuildContext context,
    ContactListState state,
    List<ContactResponse> contacts,
    ContactController controller,
    String searchQuery,
  ) {
    if (state.status == ContactStatus.initial ||
        state.status == ContactStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ContactStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '加载失败: ${state.error}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ShadButton(
              onPressed: controller.loadContacts,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              searchQuery.isEmpty ? '暂无联系人' : '未找到匹配的联系人',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadContacts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactItem(context, contact, controller);
        },
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    ContactResponse contact,
    ContactController controller,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 头像
              UserAvatar(bipupuId: contact.contactBipupuId, radius: 24),
              const SizedBox(width: AppSpacing.md),

              // 联系人信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.nickname ?? contact.username,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ID: ${contact.contactBipupuId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // 操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_outlined, size: 20),
                    onPressed: () {
                      // TODO: 跳转到聊天页面
                    },
                    tooltip: '发送消息',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('删除联系人'),
                          content: Text(
                            '确定要删除联系人 "${contact.nickname ?? contact.username}" 吗？',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                '删除',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await controller.deleteContact(contact.contactBipupuId);
                      }
                    },
                    tooltip: '删除联系人',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
