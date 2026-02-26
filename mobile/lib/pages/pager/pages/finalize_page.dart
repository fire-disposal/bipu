import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../widgets/waveform_animation_widget.dart';

/// 发送与结束页面 (State 3)
/// 显示"发送"按钮，发送消息后播放成功TTS，显示"挂断"按钮
class FinalizePage extends StatefulWidget {
  final PagerCubit cubit;

  const FinalizePage({super.key, required this.cubit});

  @override
  State<FinalizePage> createState() => _FinalizePageState();
}

class _FinalizePageState extends State<FinalizePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! FinalizeState) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // 背景
            _buildBackground(),

            // 主内容
            SafeArea(
              child: Column(
                children: [
                  // 顶部信息栏
                  _buildTopBar(state),

                  // 中间内容区
                  Expanded(child: _buildCenterContent(state)),

                  // 底部按钮区
                  _buildBottomButtons(state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建背景
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
      ),
    );
  }

  /// 构建顶部信息栏
  Widget _buildTopBar(FinalizeState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '消息准备',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '目标ID: ${state.targetId}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (state.sendSuccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已发送',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建中间内容区
  Widget _buildCenterContent(FinalizeState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 消息内容显示
            _buildMessageDisplay(state),
            const SizedBox(height: 24),

            // 发送状态
            if (!state.sendSuccess) _buildPreSendStatus(state),

            // 发送成功状态
            if (state.sendSuccess) _buildPostSendStatus(state),

            const SizedBox(height: 24),

            // 错误提示
            if (state.sendErrorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.sendErrorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 构建消息显示
  Widget _buildMessageDisplay(FinalizeState state) {
    if (state.isEditing) {
      return _buildMessageEditingArea(state);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '消息内容',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // 编辑按钮
              if (!state.sendSuccess)
                GestureDetector(
                  onTap: () => widget.cubit.startEditingMessage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '编辑',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.messageContent,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '字数: ${state.messageContent.length}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          // 表情符号警告
          if (state.textProcessingResult?.hasEmoji ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '检测到${state.textProcessingResult!.detectedEmojis.length}个表情符号，已自动移除',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建消息编辑区域
  Widget _buildMessageEditingArea(FinalizeState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '编辑消息',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => widget.cubit.cancelEditingMessage(),
                child: Icon(Icons.close, size: 18, color: Colors.blue.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            minLines: 3,
            controller: TextEditingController(text: state.messageContent),
            onChanged: (value) => widget.cubit.updateEditingMessage(value),
            decoration: InputDecoration(
              hintText: '输入消息内容...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '字数: ${state.messageContent.length}',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.cubit.cancelEditingMessage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => widget.cubit.finishEditingMessage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '确认',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 表情符号检测警告
          if (state.textProcessingResult?.hasEmoji ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_emotions, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '检测到表情符号，将被自动移除',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建发送前状态
  Widget _buildPreSendStatus(FinalizeState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 32),
              const SizedBox(height: 12),
              Text(
                '消息已准备就绪',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击下方"发送"按钮确认发送',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建发送后状态
  Widget _buildPostSendStatus(FinalizeState state) {
    return Column(
      children: [
        // 成功动画
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
              const SizedBox(height: 16),
              Text(
                '消息已发送',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '接线员已收到您的消息',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // TTS播放状态
        if (state.isPlayingSuccessTts)
          Column(
            children: [
              WaveformAnimationWidget(
                isActive: true,
                waveColor: Colors.green,
                height: 80,
              ),
              const SizedBox(height: 12),
              Text(
                '播放成功提示音...',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
              ),
            ],
          ),
      ],
    );
  }

  /// 构建底部按钮区
  Widget _buildBottomButtons(FinalizeState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 发送按钮（发送前显示）
          if (!state.sendSuccess)
            GestureDetector(
              onTap: state.isSending ? null : () => widget.cubit.sendMessage(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
                  child: state.isSending
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
                            Icon(Icons.send, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '发送',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // 挂断按钮（发送后显示）
          if (state.sendSuccess && state.showHangupButton) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.cubit.hangup(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_end, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '挂断',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 返回按钮
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => widget.cubit.cancelDialing(),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  '返回',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
