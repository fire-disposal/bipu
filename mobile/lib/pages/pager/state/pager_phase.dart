/// Pager 页面主状态枚举
enum PagerPhase {
  prep,           // 拨号准备
  connecting,     // 连接中
  inCall,         // 通话中（包含多个子阶段）
  reviewing,      // 最终确认发送
}

/// InCall 子状态枚举
/// 用于管理通话中复杂的交互流程
enum InCallSubPhase {
  inputTarget,      // 输入目标ID
  confirmTarget,    // 确认目标ID（调度员复诵后用户确认）
  recording,        // 录音录入消息
  confirmMessage,   // 确认消息内容（调度员播报后用户确认/调整）
}
