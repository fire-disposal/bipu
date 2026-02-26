import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'state/pager_state_machine.dart';
import 'state/pager_cubit.dart';
import 'pages/dialing_prep_page.dart';
import 'pages/in_call_page.dart';
import 'pages/finalize_page.dart';

/// 拨号页面主框架
/// 使用状态机管理三个状态的转换
class PagerPageRefactored extends StatefulWidget {
  const PagerPageRefactored({super.key});

  @override
  State<PagerPageRefactored> createState() => _PagerPageRefactoredState();
}

class _PagerPageRefactoredState extends State<PagerPageRefactored> {
  late PagerCubit _pagerCubit;

  @override
  void initState() {
    super.initState();
    _pagerCubit = PagerCubit();
    _pagerCubit.initializeDialingPrep();
  }

  @override
  void dispose() {
    _pagerCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PagerCubit>(
      create: (context) => _pagerCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('虚拟接线员拨号'),
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocBuilder<PagerCubit, PagerState>(
          bloc: _pagerCubit,
          builder: (context, state) {
            // 根据状态显示不同的页面
            if (state is DialingPrepState) {
              return DialingPrepPage(cubit: _pagerCubit);
            } else if (state is InCallState) {
              return InCallPage(cubit: _pagerCubit);
            } else if (state is FinalizeState) {
              return FinalizePage(cubit: _pagerCubit);
            } else if (state is PagerErrorState) {
              return _buildErrorPage(state);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
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
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 原始PagerPage保留（向后兼容）
/// 可以逐步迁移到新的PagerPageRefactored
class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  @override
  Widget build(BuildContext context) {
    // 使用新的重构页面
    return const PagerPageRefactored();
  }
}
