import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../state/user_state.dart';

/// 传呼台 (B) - 四态切换，支持巨型按钮、声波动画、解锁卡片、图鉴列表
class CallTab extends StatelessWidget {
  const CallTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallCubit, CallState>(
      builder: (context, state) {
        switch (state.runtimeType) {
          case CallInitial:
          case CallOperatorSelection:
          case CallMessageCustomization:
            return _buildInitial(context, state);
          case CallConnecting:
            return _buildConnecting(context, state as CallConnecting);
          case CallSuccess:
            return _buildSuccess(context, state as CallSuccess);
          case CallGallery:
            return _buildGallery(context, state as CallGallery);
          case CallError:
            return _buildError(context, state as CallError);
          default:
            return _buildInitial(context, state);
        }
      },
    );
  }

  Widget _buildInitial(BuildContext context, CallState state) {
    final cubit = context.read<CallCubit>();
    String? selectedOperatorId;
    String? customMessage;
    bool enableLightEffect = false;
    bool enableVibration = true;
    bool enableSpecialEffect = false;

    if (state is CallOperatorSelection) {
      selectedOperatorId = state.selectedOperatorId;
    } else if (state is CallMessageCustomization) {
      selectedOperatorId = state.selectedOperatorId;
      customMessage = state.customMessage;
      enableLightEffect = state.enableLightEffect;
      enableVibration = state.enableVibration;
      enableSpecialEffect = state.enableSpecialEffect;
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：接线员选择区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final operators = state is CallOperatorSelection
                        ? state.operators
                        : [];
                    if (index >= operators.length) {
                      return const SizedBox.shrink();
                    }

                    final operator = operators[index];
                    return ChoiceChip(
                      label: Text(operator.name),
                      selected: selectedOperatorId == operator.id,
                      onSelected: (_) => cubit.selectOperator(operator.id),
                    );
                  },
                ),
              ),
            ),
            // 中部：消息自定义区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '自定义消息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: '请输入要发送的消息',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          controller: TextEditingController(
                            text: customMessage,
                          ),
                          onChanged: (value) =>
                              cubit.updateCustomMessage(value),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _EffectButton(
                              icon: Icons.light_mode,
                              label: '光效',
                              isEnabled: enableLightEffect,
                              onTap: () => cubit.toggleLightEffect(),
                            ),
                            _EffectButton(
                              icon: Icons.vibration,
                              label: '震动',
                              isEnabled: enableVibration,
                              onTap: () => cubit.toggleVibration(),
                            ),
                            _EffectButton(
                              icon: Icons.auto_awesome,
                              label: '特效',
                              isEnabled: enableSpecialEffect,
                              onTap: () => cubit.toggleSpecialEffect(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => cubit.sendMessage(),
                          icon: const Icon(Icons.send),
                          label: const Text('发送消息'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 底部：语音输入按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: GestureDetector(
                onLongPress: () => cubit.startVoiceInput(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting(BuildContext context, CallConnecting state) {
    return Scaffold(
      body: Stack(
        children: [
          // 动态渐变背景
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaveformAnimation(),
                const SizedBox(height: 32),
                Text(
                  state.message ?? '正在连接...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final cubit = context.read<CallCubit>();
                    if (state.isVoiceMode) {
                      cubit.backToMessageCustomization();
                    } else {
                      // 模拟成功
                      cubit.sendMessage();
                    }
                  },
                  child: Text(state.isVoiceMode ? '停止录音' : '模拟成功'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, CallSuccess state) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '解锁新搭档',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey,
                  child: Text(
                    state.unlockedPartnerName?.substring(0, 1) ?? '新',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '解锁新搭档: ${state.unlockedPartnerName ?? "新搭档"}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.read<CallCubit>().viewGallery(),
                      child: const Text('查看图鉴'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<CallCubit>().backToInitial(),
                      child: const Text('继续'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context, CallGallery state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('接收及图鉴'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<CallCubit>().backToInitial(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: state.partners.length,
          itemBuilder: (context, index) {
            final partner = state.partners[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: partner.isUnlocked
                        ? Colors.blue[100]
                        : Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      color: partner.isUnlocked
                          ? Colors.blue[700]
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    partner.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: partner.isUnlocked
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                  if (partner.isUnlocked && partner.unlockTime != null)
                    Text(
                      _formatUnlockTime(partner.unlockTime!),
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildError(BuildContext context, CallError state) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '出错了: ${state.message}',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<CallCubit>().backToInitial(),
            child: const Text('返回'),
          ),
        ],
      ),
    ),
  );
}

String _formatUnlockTime(DateTime unlockTime) {
  final now = DateTime.now();
  final difference = now.difference(unlockTime);

  if (difference.inDays > 0) {
    return '${difference.inDays}天前';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}小时前';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}分钟前';
  } else {
    return '刚刚';
  }
}

class _EffectButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _EffectButton({
    required this.icon,
    required this.label,
    this.isEnabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: isEnabled ? Colors.blue.shade100 : Colors.blue.shade50,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                icon,
                color: isEnabled ? Colors.blueAccent : Colors.blue[400],
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isEnabled ? Colors.blueAccent : Colors.black87,
            fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// 声波动画占位
class _WaveformAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (i) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 800 + i * 200),
              width: 60.0 + i * 20,
              height: 60.0 + i * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.2 - i * 0.05),
              ),
            );
          }),
          const Icon(Icons.mic, color: Colors.blue, size: 40),
        ],
      ),
    );
  }
}
