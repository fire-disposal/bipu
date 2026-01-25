import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_core/models/system_notification_create_model.dart';
import 'package:flutter_core/repositories/system_notification_repository.dart';

class SendSystemMessagePage extends StatefulWidget {
  const SendSystemMessagePage({super.key});

  @override
  State<SendSystemMessagePage> createState() => _SendSystemMessagePageState();
}

class _SendSystemMessagePageState extends State<SendSystemMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _notificationRepository = SystemNotificationRepository();
  final _userIdController = TextEditingController();
  final _patternController = TextEditingController();

  String _title = '';
  String _content = '';
  int _priority = 5;
  bool _sendToAll = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _patternController.dispose();
    super.dispose();
  }

  void _applyPatternPreset(String name) {
    Map<String, dynamic> preset;
    switch (name) {
      case 'Emergency Red':
        preset = {
          "rgb": {"r": 255, "g": 0, "b": 0},
          "vibe": {"intensity": 80, "duration": 2000}
        };
        break;
      case 'Success Green':
        preset = {
          "rgb": {"r": 0, "g": 255, "b": 0},
          "vibe": {"intensity": 30, "duration": 500}
        };
        break;
      case 'Info Blue':
        preset = {
          "rgb": {"r": 0, "g": 100, "b": 255},
          "vibe": {"intensity": 20, "duration": 300}
        };
        break;
      default:
        return;
    }
    _patternController.text = jsonEncode(preset);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      List<int>? targetUsers;
      
      if (!_sendToAll) {
        final userIdText = _userIdController.text;
        if (userIdText.trim().isEmpty) {
          throw Exception('请指定目标用户 ID');
        }
        targetUsers = userIdText
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .where((e) => e != null)
            .cast<int>()
            .toList();
            
        if (targetUsers.isEmpty) {
          throw Exception('未能解析出有效的用户 ID');
        }
      }

      Map<String, dynamic>? pattern;
      if (_patternController.text.trim().isNotEmpty) {
        try {
          pattern = jsonDecode(_patternController.text) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Pattern JSON 格式错误');
        }
      }

      final notification = SystemNotificationCreate(
        title: _title,
        content: _content,
        priority: _priority,
        targetUsers: targetUsers,
        pattern: pattern,
      );

      await _notificationRepository.createSystemNotification(notification);

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
              
              SwitchListTile(
                title: const Text('发送给所有活跃用户'),
                subtitle: const Text('关闭以指定特定用户 ID'),
                value: _sendToAll,
                onChanged: (val) => setState(() => _sendToAll = val),
                contentPadding: EdgeInsets.zero,
              ),
              
              if (!_sendToAll)
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: '目标用户ID (逗号分隔)',
                    border: OutlineInputBorder(),
                    hintText: '例如: 1, 2, 3',
                  ),
                  validator: (v) {
                    if (!_sendToAll && (v == null || v.trim().isEmpty)) {
                      return '请指定至少一个用户 ID';
                    }
                    return null;
                  },
                ),
                
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Text('快速样式: '),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('红 (紧急)'),
                    backgroundColor: Colors.red[100],
                    onPressed: () => _applyPatternPreset('Emergency Red'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('蓝 (信息)'),
                    backgroundColor: Colors.blue[100],
                    onPressed: () => _applyPatternPreset('Info Blue'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('绿 (成功)'),
                    backgroundColor: Colors.green[100],
                    onPressed: () => _applyPatternPreset('Success Green'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _patternController,
                decoration: const InputDecoration(
                  labelText: 'Pattern (JSON 配置)',
                  border: OutlineInputBorder(),
                  hintText: '自定义 JSON 配置...',
                ),
                maxLines: 3,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    try {
                      jsonDecode(v);
                    } catch (e) {
                      return '无效的 JSON 格式';
                    }
                  }
                  return null;
                },
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
