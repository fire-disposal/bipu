import 'package:flutter/material.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/models/contact/contact.dart';
import '../../common/widgets/app_button.dart';

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final ImService _imService = ImService();

  // Target Selection
  bool _isDirectInput = false;
  Contact? _selectedContact;

  // Vibration
  String _selectedVibration = 'default';
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pager')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Target Selector
            Row(
              children: [
                const Text('To: '),
                DropdownButton<bool>(
                  value: _isDirectInput,
                  items: const [
                    DropdownMenuItem(value: false, child: Text('Contact')),
                    DropdownMenuItem(value: true, child: Text('Manual ID')),
                  ],
                  onChanged: (v) => setState(() => _isDirectInput = v!),
                ),
              ],
            ),
            if (_isDirectInput)
              TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'Bipupu ID'),
              )
            else
              DropdownButton<Contact>(
                hint: const Text('Select Contact'),
                value: _selectedContact,
                isExpanded: true,
                items: _imService.contacts
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.remark ?? c.contactBipupuId),
                      ),
                    )
                    .toList(),
                onChanged: (c) => setState(() => _selectedContact = c),
              ),

            const SizedBox(height: 20),

            // Message Input
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Vibration Selector (Mock)
            DropdownButton<String>(
              value: _selectedVibration,
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Default Buzz')),
                DropdownMenuItem(value: 'sos', child: Text('SOS')),
                DropdownMenuItem(value: 'heartbeat', child: Text('Heartbeat')),
              ],
              onChanged: (v) => setState(() => _selectedVibration = v!),
            ),

            const SizedBox(height: 30),

            AppButton(
              text: _isSending ? 'Sending...' : 'PAGE',
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter message')));
      return;
    }

    String? targetId;
    if (_isDirectInput) {
      targetId = _idController.text.trim();
    } else {
      targetId = _selectedContact?.contactBipupuId;
    }

    if (targetId == null || targetId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select target')));
      return;
    }

    setState(() => _isSending = true);

    try {
      await _imService.messageApi.sendMessage(
        receiverId: targetId,
        content: text,
        msgType: 'device', // Pager means 'device' type likely
        pattern: {'vibration': _selectedVibration},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Paged!')));
        _textController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fail: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
