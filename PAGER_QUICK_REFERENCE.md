# Pager 页面快速参考 - 用户交互指南

## 🎯 核心功能快速查询

### 挂断功能位置
| 阶段 | UI位置 | 操作 |
|------|--------|------|
| **Prep** (准备) | - | 无挂断（初始状态） |
| **Connecting** (连接中) | 顶部右角 | 红色电话图标 |
| **InCall** (输入中) | 顶部右角 | 红色电话图标 |
| **Reviewing** (确认中) | 标题右侧 | 红色电话图标 |

### 返回手势处理
- **系统返回键** (Android) ✅ 支持
- **侧滑返回** (iOS) ✅ 支持
- **确认流程**: 挂断确认对话框
- **Prep阶段**: 直接返回（无确认）

---

## 📱 用户流程速览

### 快乐路径 (Happy Path)
```
呼叫 → 输入ID → 用户存在 → 录音 → 确认 → 发送 → 成功
```

### 异常处理路径
```
用户不存在
  ↓
TTS播报错误
  ↓
ID 清空
  ↓
返回输入阶段重试

挂断 (任何阶段)
  ↓
确认对话框
  ↓
挂断 → 返回准备阶段
```

---

## 🔧 状态机流转图

```
┌─────────┐
│  prep   │  ← 初始状态
└────┬────┘
     │ 点击"呼叫接线员"
     ↓
┌──────────────┐
│ connecting   │  ← 2秒连接动画
└────┬─────────┘
     │ 自动转入
     ↓
┌────────┐
│ inCall │  ← 输入目标ID
└────┬───┘
     │ ID验证成功
     ↓
┌────────────┐
│ reviewing  │  ← 确认消息
└────┬───────┘
     │ 发送成功
     ↓
     └──→ 返回 inCall → 再次输入 → ...
           或 → 返回 prep
```

---

## 🎨 UI 变更汇总

### new_in_call_view.dart
**顶部吧 (TopBar)**
```
[●信号] 通话中 [信号图标] [📞红色挂断]
```
- 左: 在线指示器 + 文本
- 右: 信号强度 + 挂断按钮
- 点击挂断 → 确认对话框

### new_reviewing_view.dart
**标题栏**
```
[📞红色挂断] 确认消息 [空白]
```
- 左: 挂断按钮（红色）
- 中: 标题
- 右: 间距
- 功能: 同上

---

## 🛡️ 容错机制

### 输入验证
- ✅ 长度限制: 最多12位
- ✅ 重复点击保护: isConfirming 标志
- ✅ 网络错误处理: TTS 反馈 + 状态重置

### 状态保护
- ✅ 关键操作前 phase 检查
- ✅ 网络中断时的状态恢复
- ✅ 挂断后完全重置（7个状态变量）

### 手势保护
- ✅ 通话中返回需确认
- ✅ Prep 阶段直接返回
- ✅ 连续手势点击去重

---

## 📊 关键状态变量

| 变量 | 类型 | 用途 | 重置时机 |
|------|------|------|---------|
| `phase` | enum | 当前阶段 | hangup |
| `targetId` | String | 目标用户ID | confirmFail / hangup / backToVoiceInput |
| `messageContent` | String | 待发送消息 | sendSuccess / hangup / backToVoiceInput |
| `isConfirming` | bool | 确认状态锁 | confirmTargetId finally |
| `isSending` | bool | 发送状态锁 | sendMessage finally |
| `errorMessage` | String? | 错误提示 | 各阶段重置 |
| `asrTranscript` | String | ASR临时文本 | 进入reviewing时清空 |

---

## 🔍 调试技巧

### 查看状态日志
```dart
debugPrint('[PagerVM] 目标用户存在');
debugPrint('[NewInCallView] targetId changed: $v');
debugPrint('[PagerVM] 确认结果 "${_asrTranscript}"');
```

### 常见问题排查
| 问题 | 原因 | 解决 |
|------|------|------|
| 挂断按钮不响应 | 看不到按钮 | 检查topBar高度 |
| 返回不挂断 | 逻辑错误 | 检查WillPopScope |
| 状态污染 | 挂断不彻底 | hangup()检查所有变量 |
| InputController失步 | 返回后未清空 | didUpdateWidget同步 |

---

## 📞 流程详解

### 目标ID输入流程
```
用户输入 → onChanged 回调
    ↓
vm.updateTargetId(v)
    ├─ 长度检查 (≤12)
    ├─ 状态更新
    └─ 清空错误消息

用户点击"确认号码"
    ↓
confirmTargetId() async
    ├─ 检查 isConfirming (防重复)
    ├─ 检查 phase == inCall
    ├─ TTS 播报确认台词
    ├─ API 验证用户
    ├─ 成功: TTS 请求消息 → 等待录音
    └─ 失败: TTS 错误提示 → 清空ID → 等待重试
```

### 挂断流程
```
用户点击挂断图标 或 返回键
    ↓
_showHangupDialog() 或 _handleBack()
    ├─ Prep 阶段: 直接返回
    └─ 其他阶段: 显示确认
    
用户确认
    ↓
vm.hangup() async
    ├─ 停止 TTS/ASR
    ├─ 重置7个状态变量
    ├─ phase = prep
    ├─ notifyListeners()
    └─ initializePrep() 重新初始化
```

---

## 🚀 性能优化

### 已应用
- ✅ AnimatedSwitcher 页面转换
- ✅ SingleChildScrollView 防止布局溢出
- ✅ Provider watch 选择性更新
- ✅ FadeTransition + ScaleTransition 流畅动画

### 可继续优化
- [ ] 添加页面缓存
- [ ] 减少 TTS 库加载时间
- [ ] 优化列表滚动性能

---

**最后更新**: 2026-03-09  
**版本**: 1.0  
**状态**: ✅ 可用
