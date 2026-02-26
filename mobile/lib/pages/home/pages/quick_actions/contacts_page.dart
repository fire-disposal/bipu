import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/im_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ImService _imService = ImService();

  @override
  void initState() {
    super.initState();
    _imService.addListener(_onImServiceChanged);
    // Start polling if not already
    // _imService.startPolling(); // usually called by main or on app start/resume
  }

  @override
  void dispose() {
    _imService.removeListener(_onImServiceChanged);
    super.dispose();
  }

  void _onImServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _imService.contacts;

    return Scaffold(
      appBar: AppBar(
        title: Text('contacts'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              context.push('/contacts/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _imService.refresh(),
          ),
        ],
      ),
      body: contacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      contact.remark?.substring(0, 1) ??
                          contact.contactBipupuId.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(contact.remark ?? contact.contactBipupuId),
                  subtitle: Text('ID: ${contact.contactBipupuId}'),
                  onTap: () {
                    context.push('/user/detail/${contact.contactBipupuId}');
                  },
                );
              },
            ),
    );
  }
}
