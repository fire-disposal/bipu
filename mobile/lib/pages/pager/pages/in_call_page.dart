import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/pager_state_machine.dart';
import '../state/pager_cubit.dart';
import '../widgets/operator_display_widget.dart';
import '../widgets/waveform_animation_widget.dart';

/// 通话中页面 (State 2)
/// 显示虚拟接线员立绘，播放TTS，进行ASR语音转写
class InCallPage extends StatefulWidget {
  final PagerCubit cubit;

  const InCallPage({super.key, required this.cubit});

  @override
  State<InCallPage> createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagerCubit, PagerState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is! InCallState) {
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

                  // 底部控制区
                  _buildBottomControls(state),
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
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
      ),
    );
  }

  /// 构建顶部信息栏
  Widget _buildTopBar(InCallState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 通话状态
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '通话中',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '目标ID: ${state.targetId}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          // 取消按钮
          GestureDetector(
            onTap: () => widget.cubit.cancel(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade100,
              ),
              child: Icon(Icons.close, color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建中间内容区
  Widget _buildCenterContent(InCallState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 虚拟接线员立绘
            SizedBox(
              height: 300,
              child: OperatorDisplayWidget(
                imageUrl: state.operatorImageUrl,
                isAnimating: state.isTtsPlaying || state.isAsrActive,
                scale: 1.0,
              ),
            ),
            const SizedBox(height: 24),

            // 声纹动效
            if (state.isAsrActive || state.isTtsPlaying)
              Column(
                children: [
                  WaveformAnimationWidget(
                    waveformData: state.waveformData,
                    isActive: state.isAsrActive || state.isTtsPlaying,
                    waveColor: Colors.blue,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // TTS文本显示
            if (state.currentTtsText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '接线员说',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentTtsText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ASR转写文本显示
            if (state.asrTranscript.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '您说',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (state.isAsrActive)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.green.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.asrTranscript,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 状态指示
            _buildStatusIndicator(state),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(InCallState state) {
    String statusText = '';
    Color statusColor = Colors.grey;

    if (state.isTtsPlaying) {
      statusText = '接线员正在说话...';
      statusColor = Colors.blue;
    } else if (state.isAsrActive) {
      statusText = '正在录音...';
      statusColor = Colors.orange;
    } else if (state.isSilenceDetected) {
      statusText = '检测到静默，准备发送';
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部控制区
  Widget _buildBottomControls(InCallState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 暂停/继续按钮
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: 实现暂停/继续逻辑
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  state.isAsrActive ? Icons.pause : Icons.play_arrow,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 挂断按钮
          Expanded(
            child: GestureDetector(
              onTap: () => widget.cubit.cancel(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Icon(Icons.call_end, color: Colors.red.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
