/// Pager 页面状态枚举
enum PagerPhase {
  prep,           // 拨号准备
  connecting,     // 连接中
  inCall,         // 通话中（输入号码 + 录音）
  reviewing,      // 确认发送
}
