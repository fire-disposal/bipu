import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';

/// 极简拨号准备页面 (State 1 - Minimal)
/// 页面中心仅保留一个极简、灵动的数字输入区域
class DialingPrepPageMinimal extends StatefulWidget {
  final PagerCubit cubit;

  const DialingPrepPageMinimal({super.key, required this.cubit});

  @override
  State<DialingPrepPageMinimal> createState() => _DialingPrepPageMinimalState();
}

class _DialingPrepPageMinimalState extends State<DialingPrepPageMinimal>
    with SingleTickerProviderStateMixin {
  late TextEditingController _idController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();

    // 初始化脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleNumpadInput(String digit) {
    if (_idController.text.length < 20) {
      _idController.text += digit;
      widget.cubit.updateTargetId(_idController.text);
    }
  }

  void _handleBackspace() {
    if (_idController.text.isNotEmpty) {
      _idController.text = _idController.text.substring(
        0,
        _idController.text.length - 1,
      );
      widget.cubit.updateTargetId(_idController.text);
    }
  }

  void _handleClear() {
    _idController.clear();
    widget.cubit.updateTargetId('');
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! DialingPrepState) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 上方留白
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),

                      // 标题
                      const Text(
                        '传呼',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.06,
                      ),

                      // 数字输入显示区域（灵动脉冲设计）
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.grey.shade50,
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '目标ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _idController.text.isEmpty
                                    ? '---'
                                    : _idController.text,
                                style: TextStyle(
                                  fontSize: _idController.text.isEmpty
                                      ? 28
                                      : 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: Colors.blue.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.08,
                      ),

                      // 九键数字盘
                      _buildCompactNumpad(),

                      const SizedBox(height: 20),

                      // 功能按钮（删除和清空）
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleBackspace,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.orange.shade50,
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.backspace_outlined,
                                  color: Colors.orange.shade600,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleClear,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.red.shade50,
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.clear,
                                  color: Colors.red.shade600,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 拨号主按钮
                      GestureDetector(
                        onTap: state.isLoading ? null : _handleDial,
                        child: Container(
                          height: 64,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
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
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.call,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建紧凑的九键数字盘
  Widget _buildCompactNumpad() {
    const buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((digit) {
              return GestureDetector(
                onTap: () => _handleNumpadInput(digit),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
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
}
