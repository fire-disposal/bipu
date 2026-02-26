import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'state/pager_state_machine.dart';
import 'state/pager_cubit.dart';
import 'pages/dialing_prep_page_minimal.dart';
import 'pages/in_call_page.dart';
import 'pages/finalize_page.dart';
import 'pages/operator_gallery_page_new.dart';
import 'services/operator_service.dart';

/// 增强版拨号页面 - 包含所有新功能
/// 使用状态机管理三个状态的转换，支持操作员人格系统、文本编辑和解锁机制
class PagerPageEnhanced extends StatefulWidget {
  const PagerPageEnhanced({super.key});

  @override
  State<PagerPageEnhanced> createState() => _PagerPageEnhancedState();
}

class _PagerPageEnhancedState extends State<PagerPageEnhanced> {
  late PagerCubit _pagerCubit;
  late OperatorService _operatorService;

  @override
  void initState() {
    super.initState();
    _operatorService = OperatorService();
    _pagerCubit = PagerCubit();
    _pagerCubit.initializeDialingPrep();
  }

  @override
  void dispose() {
    _pagerCubit.close();
    super.dispose();
  }

  /// 显示操作员图鉴
  void _showOperatorGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OperatorGalleryPageNew(operatorService: _operatorService),
      ),
    );
  }

  /// 显示解锁提示对话框
  void _showUnlockDialog(OperatorUnlockedState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 庆祝图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow.shade100,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),

              // 标题
              Text(
                state.unlockMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 操作员信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    // 小立绘
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: state.operator.portraitUrl.startsWith('http')
                          ? Image.network(
                              state.operator.portraitUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.person, size: 30),
                            )
                          : Image.asset(
                              state.operator.portraitUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.person, size: 30),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.operator.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.operator.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: Navigator.of(context).pop,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      child: Text(
                        '继续拨号',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showOperatorGallery();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.blue.shade400,
                      ),
                      child: const Text(
                        '查看图鉴',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PagerCubit>(
      create: (context) => _pagerCubit,
      child: BlocListener<PagerCubit, PagerState>(
        bloc: _pagerCubit,
        listener: (context, state) {
          // 监听操作员解锁事件
          if (state is OperatorUnlockedState) {
            _showUnlockDialog(state);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('虚拟接线员'),
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              // 操作员展示入口
              BlocBuilder<PagerCubit, PagerState>(
                bloc: _pagerCubit,
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: '拨号员展示',
                      child: IconButton(
                        icon: const Icon(Icons.collections),
                        onPressed: _showOperatorGallery,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<PagerCubit, PagerState>(
            bloc: _pagerCubit,
            builder: (context, state) {
              // 根据状态显示不同的页面
              if (state is DialingPrepState) {
                return DialingPrepPageMinimal(cubit: _pagerCubit);
              } else if (state is InCallState) {
                return InCallPage(cubit: _pagerCubit);
              } else if (state is FinalizeState) {
                return FinalizePage(cubit: _pagerCubit);
              } else if (state is PagerErrorState) {
                return _buildErrorPage(state);
              } else if (state is OperatorUnlockedState) {
                // 解锁状态由 BlocListener 处理
                return const SizedBox.shrink();
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  /// 构建错误页面
  Widget _buildErrorPage(PagerErrorState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
            const SizedBox(height: 16),
            Text(
              '出错了',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _pagerCubit.initializeDialingPrep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('重试', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 原始 PagerPage 保留（向后兼容）
/// 可以逐步迁移到新的 PagerPageEnhanced
class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  @override
  Widget build(BuildContext context) {
    // 使用新的增强页面
    return const PagerPageEnhanced();
  }
}
