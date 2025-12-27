import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../repositories/message_repository.dart';

class SendSystemMessagePage extends StatefulWidget {
  const SendSystemMessagePage({super.key});

  @override
  State<SendSystemMessagePage> createState() => _SendSystemMessagePageState();
}

class _SendSystemMessagePageState extends State<SendSystemMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _messageRepository = MessageRepository();

  String _title = '';
  String _content = '';
  int _priority = 5;
  String? _targetUsersStr;
  String? _patternJsonStr;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      List<int>? targetUsers;
      if (_targetUsersStr != null && _targetUsersStr!.trim().isNotEmpty) {
        targetUsers = _targetUsersStr!
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .where((e) => e != null)
            .cast<int>()
            .toList();
      }

      Map<String, dynamic>? pattern;
      if (_patternJsonStr != null && _patternJsonStr!.trim().isNotEmpty) {
        try {
          pattern = jsonDecode(_patternJsonStr!);
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Pattern JSON 格式错误: $e')));
          setState(() => _isLoading = false);
          return;
        }
      }

      await _messageRepository.createSystemNotification(
        title: _title,
        content: _content,
        priority: _priority,
        targetUsers: targetUsers,
        pattern: pattern,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('系统消息发送成功')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发送系统消息')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? '请输入标题' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (v) => v?.isEmpty == true ? '请输入内容' : null,
                onSaved: (v) => _content = v ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('优先级 (0-10): '),
                  Expanded(
                    child: Slider(
                      value: _priority.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: _priority.toString(),
                      onChanged: (v) => setState(() => _priority = v.toInt()),
                    ),
                  ),
                  Text(_priority.toString()),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '目标用户ID (逗号分隔，留空发送给所有人)',
                  border: OutlineInputBorder(),
                  hintText: '例如: 1, 2, 3',
                ),
                onSaved: (v) => _targetUsersStr = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Pattern (JSON)',
                  border: OutlineInputBorder(),
                  hintText: '{"rgb": {"r": 255, "g": 0, "b": 0}}',
                ),
                maxLines: 3,
                onSaved: (v) => _patternJsonStr = v,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('发送'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
