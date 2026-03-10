import 'package:flutter/material.dart';
import 'package:bipupu/core/services/im_service.dart';
import 'package:bipupu/core/api/models/message_type.dart';

/// 快速消息发送页面 - 单页简化版
///
/// 功能：
/// - 输入目标 ID
/// - 输入消息内容
/// - 发送消息
/// - 纯 UI，无复杂交互
class QuickSendPage extends StatefulWidget {
  const QuickSendPage({super.key});

  @override
  State<QuickSendPage> createState() => _QuickSendPageState();
}

class _QuickSendPageState extends State<QuickSendPage> {
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _targetIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// 验证目标 ID
  String? _validateTargetId(String value) {
    if (value.isEmpty) return '请输入目标 ID';
    if (value.length > 12) return '目标 ID 最多 12 位';
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return '目标 ID 只能包含字母、数字、下划线和连字符';
    }
    return null;
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    // 校验输入
    final targetId = _targetIdController.text.trim();
    final message = _messageController.text.trim();

    final targetIdError = _validateTargetId(targetId);
    if (targetIdError != null) {
      _showError(targetIdError);
      return;
    }

    if (message.isEmpty) {
      _showError('请输入消息内容');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 发送消息
      final result = await ImService().sendMessage(
        receiverId: targetId,
        content: message,
        messageType: MessageType.voice,
      );

      if (result != null && mounted) {
        // 清空表单
        _targetIdController.clear();
        _messageController.clear();

        // 显示成功提示
        _showSuccess('消息发送成功！');

        // 2秒后清空成功消息
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _successMessage = null);
        }
      } else if (mounted) {
        _showError('发送失败，请重试');
      }
    } catch (e) {
      debugPrint('[QuickSendPage] 发送异常: $e');
      if (mounted) {
        _showError('发送异常：${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  void _showSuccess(String message) {
    setState(() => _successMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardBottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速发送'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: keyboardBottomPadding),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 说明文字
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '输入接收方用户 ID 和消息内容，一键快速发送',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 目标 ID 输入框
                _buildInputField(
                  label: '接收方 ID',
                  hint: '请输入用户 ID（最多 12 位）',
                  controller: _targetIdController,
                  maxLength: 12,
                  colorScheme: colorScheme,
                  enabled: !_isSending,
                ),

                const SizedBox(height: 20),

                // 消息内容输入框
                _buildMessageField(
                  colorScheme: colorScheme,
                  enabled: !_isSending,
                ),

                const SizedBox(height: 28),

                // 错误提示
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 成功提示
                if (_successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 发送按钮
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? '发送中...' : '发送消息'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 清空按钮
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _targetIdController.clear();
                            _messageController.clear();
                            setState(() {
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('清空'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建输入框
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int? maxLength,
    required ColorScheme colorScheme,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  /// 构建消息输入框
  Widget _buildMessageField({
    required ColorScheme colorScheme,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '消息内容',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          enabled: enabled,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '请输入要发送的消息（最多 500 字）',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
