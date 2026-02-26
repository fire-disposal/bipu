import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';

/// 拨号准备页面 (State 1)
/// 用户输入目标ID，选择联系人，准备拨号
class DialingPrepPage extends StatefulWidget {
  final PagerCubit cubit;

  const DialingPrepPage({super.key, required this.cubit});

  @override
  State<DialingPrepPage> createState() => _DialingPrepPageState();
}

class _DialingPrepPageState extends State<DialingPrepPage> {
  late TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  /// 九键数字输入处理
  void _handleNumpadInput(String digit) {
    _idController.text += digit;
    widget.cubit.updateTargetId(_idController.text);
  }

  /// 删除最后一个字符
  void _handleBackspace() {
    if (_idController.text.isNotEmpty) {
      _idController.text = _idController.text.substring(
        0,
        _idController.text.length - 1,
      );
      widget.cubit.updateTargetId(_idController.text);
    }
  }

  /// 清空输入
  void _handleClear() {
    _idController.clear();
    widget.cubit.updateTargetId('');
  }

  /// 开始拨号
  void _handleDial() {
    final targetId = _idController.text.trim();
    if (targetId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入目标ID')));
      return;
    }

    widget.cubit.startDialing(targetId);
  }

  /// 打开联系人选择器
  void _handleSelectContact() {
    // TODO: 实现联系人选择逻辑
    // 可以弹出联系人列表，选择后自动填充ID
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('联系人功能开发中...')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! DialingPrepState) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                const Text(
                  '拨号',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // ID输入框
                _buildIdInputSection(state),
                const SizedBox(height: 24),

                // 九键数字盘
                _buildNumpad(),
                const SizedBox(height: 24),

                // 拨号按钮
                _buildDialButton(state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建ID输入区域
  Widget _buildIdInputSection(DialingPrepState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '目标ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _idController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '输入ID',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ),
              // 联系人按钮
              GestureDetector(
                onTap: _handleSelectContact,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                  ),
                  child: Icon(
                    Icons.contacts,
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),

          // 选中的联系人显示
          if (state.selectedContactName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '已选择: ${state.selectedContactName}',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建九键数字盘
  Widget _buildNumpad() {
    const buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: row.map((digit) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleNumpadInput(digit),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        digit,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// 构建拨号按钮区域
  Widget _buildDialButton(DialingPrepState state) {
    return Column(
      children: [
        // 功能按钮
        Row(
          children: [
            // 删除按钮
            Expanded(
              child: GestureDetector(
                onTap: _handleBackspace,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.shade100,
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Icon(
                    Icons.backspace_outlined,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 清空按钮
            Expanded(
              child: GestureDetector(
                onTap: _handleClear,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Icon(Icons.clear, color: Colors.red.shade600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 拨号按钮
        GestureDetector(
          onTap: state.isLoading ? null : _handleDial,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '拨号',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // 错误提示
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
