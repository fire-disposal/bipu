import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

/// 传唤台状态
enum PagerState {
  /// 空闲状态
  idle,

  /// 正在呼叫
  calling,

  /// 录音中（语音输入）
  recording,

  /// 手动模式（文本输入）
  manual,

  /// 通话中
  connected,
}

/// 传唤台模式
enum PagerMode {
  /// 模式 A：语音优先
  voice,

  /// 模式 B：手动优先
  manual,
}

/// 传唤台提供者
final pagerNotifierProvider = NotifierProvider<PagerNotifier, PagerState>(
  () => PagerNotifier(),
);

class PagerNotifier extends Notifier<PagerState> {
  @override
  PagerState build() {
    return PagerState.idle;
  }

  PagerMode _mode = PagerMode.voice;
  PagerMode get mode => _mode;

  /// 切换模式
  void toggleMode() {
    _mode = _mode == PagerMode.voice ? PagerMode.manual : PagerMode.voice;
    debugPrint('[Pager] 模式切换：${_mode == PagerMode.voice ? "语音" : "手动"}');
  }

  /// 开始呼叫
  void startCalling(String targetId) {
    debugPrint('[Pager] 开始呼叫：$targetId');
    state = PagerState.calling;
  }

  /// 开始录音
  void startRecording() {
    debugPrint('[Pager] 开始录音');
    state = PagerState.recording;
  }

  /// 停止录音
  void stopRecording() {
    debugPrint('[Pager] 停止录音');
    state = PagerState.connected;
  }

  /// 切换到手动模式
  void switchToManual() {
    debugPrint('[Pager] 切换到手动模式');
    state = PagerState.manual;
  }

  /// 重置为空闲
  void reset() {
    debugPrint('[Pager] 重置为空闲');
    state = PagerState.idle;
  }

  /// 发送消息（手动模式）
  Future<void> sendMessage(String content) async {
    debugPrint('[Pager] 发送消息：$content');
    // TODO: 调用消息发送 API
    state = PagerState.connected;
  }

  /// 挂断/结束
  void hangup() {
    debugPrint('[Pager] 挂断');
    state = PagerState.idle;
  }
}

/// 模式提供者
final pagerModeProvider = Provider<PagerMode>((ref) {
  return ref.read(pagerNotifierProvider.notifier).mode;
});
