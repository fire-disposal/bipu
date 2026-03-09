# Pager 新架构业务逻辑检查清单

## ✅ 核心业务流程

### 1. 初始化流程
- [x] PagerVM 构造函数自动调用 `initializePrep()`
- [x] OperatorService 初始化
- [x] 随机选择接线员
- [x] VoiceService 延迟初始化

**状态**: `prep`

### 2. 开始连接流程
- [x] `startDialing()` 方法
- [x] 设置 phase 为 `connecting`
- [x] 2 秒连接动画延迟
- [x] 设置 phase 为 `inCall`
- [x] 自动调用 `_greetingFlow()`

**状态变化**: `prep` → `connecting` → `inCall`

### 3. 问候流程
- [x] 播放问候语 TTS
- [x] 400ms 延迟
- [x] 播放询问目标 ID TTS
- [x] 400ms 延迟

**TTS 台词**:
- `operator.dialogues.getGreeting()`
- `operator.dialogues.getAskTarget()`

### 4. 目标 ID 输入流程
- [x] `updateTargetId(String id)` 方法
- [x] 长度限制（12 字符）
- [x] 防止确认中修改
- [x] `clearTargetId()` 清空方法

**状态**: 保持 `inCall`

### 5. 确认目标 ID 流程
- [x] `confirmTargetId()` 方法
- [x] 防重复确认 (`_isConfirming`)
- [x] 播放确认台词 TTS
- [x] 300ms 延迟
- [x] API 检查用户是否存在
- [x] 成功：播放询问消息 TTS
- [x] 失败：播放错误提示 + 清空 ID

**API 调用**: `ApiClient.instance.api.users.getApiUsersUsersBipupuId()`

**TTS 台词**:
- `operator.dialogues.getConfirmId(targetId)`
- `operator.dialogues.getRequestMessage()` (成功)
- `operator.dialogues.getUserNotFound()` (失败)

### 6. 语音录音流程
- [x] `startVoiceRecording()` 方法
- [x] 停止正在播放的 TTS
- [x] 设置 `_isRecording = true`
- [x] 启动 ASR 录音
- [x] 监听识别结果
- [x] 收到结果后进入 `reviewing` 状态
- [x] 错误处理
- [x] `stopRecording()` 停止方法

**ASR**: `VoiceService.startListening(timeout: 30s)`

**状态变化**: `inCall` → `reviewing`

### 7. 文字输入切换
- [x] `switchToTextInput()` 方法
- [x] 停止 TTS 和 ASR
- [x] 切换到 `reviewing` 状态
- [x] `updateMessageContent(String)` 更新文字
- [x] `backToVoiceInput()` 返回语音输入

### 8. 发送消息流程
- [x] `sendMessage()` 方法
- [x] 防重复发送 (`_isSending`)
- [x] 调用 ImService.sendMessage()
- [x] 成功：记录历史 + TTS 提示
- [x] 成功：解锁接线员
- [x] 成功：播放询问继续 TTS
- [x] 失败：显示错误
- [x] 重置状态

**API 调用**: `ImService().sendMessage()`

**TTS 台词**:
- `operator.dialogues.getSuccessMessage()` (成功)
- `operator.dialogues.getAskContinue()` (成功)

**状态变化**: `reviewing` → `inCall` (继续) 或保持

### 9. 继续发送给另一人
- [x] `continueToNextRecipient()` 方法
- [x] 播放询问目标 ID TTS
- [x] 清空目标 ID 和消息内容
- [x] 返回 `inCall` 状态

**状态变化**: `inCall` → `inCall` (重置)

### 10. 挂断流程
- [x] `hangup()` 方法
- [x] 停止 TTS
- [x] 停止 ASR
- [x] 调用 `initializePrep()` 重置

**状态变化**: 任意 → `prep`

---

## 🎯 状态保护机制

### 防重复操作
- [x] `_isConfirming` - 防止重复确认
- [x] `_isSending` - 防止重复发送
- [x] `_isRecording` - 防止重复录音

### 状态检查
- [x] 每个异步方法检查 `_phase`
- [x] TTS 播放后检查 `_phase` 是否改变
- [x] API 调用后检查 `_phase` 是否改变

---

## 📦 依赖服务检查

### VoiceService
- [x] TTS 播放：`speak(text, sid, speed)`
- [x] TTS 停止：`stopSpeaking()`
- [x] ASR 开始：`startListening(timeout)`
- [x] ASR 停止：`stopListening()`
- [x] 资源清理：`dispose()`

### OperatorService
- [x] 初始化：`init()`
- [x] 随机选择：`getRandomOperator()`
- [x] 解锁接线员：`unlockOperator(id)`

### ApiClient
- [x] 检查用户：`getApiUsersUsersBipupuId(bipupuId)`

### ImService
- [x] 发送消息：`sendMessage(receiverId, content, messageType)`

---

## 🧪 UI 组件检查

### NewPrepView
- [x] 显示品牌标题
- [x] 显示视觉中心区
- [x] 显示服务说明
- [x] 呼叫按钮
- [x] 加载状态显示

### NewConnectingView
- [x] 连接动画
- [x] 加载提示文字

### NewInCallView
- [x] 顶部状态栏
- [x] 接线员立绘
- [x] 台词显示
- [x] 目标 ID 输入框
- [x] 确认按钮
- [x] 防重复点击
- [x] 确认中状态显示

### NewReviewingView
- [x] 目标号码显示
- [x] 消息内容显示
- [x] 消息内容滚动（长文本）
- [x] 重新录制按钮
- [x] 发送按钮
- [x] 发送中状态显示
- [x] 按钮禁用状态

---

## ⚠️ 错误处理

### 网络错误
- [x] 用户不存在 API 调用 catch
- [x] 消息发送 API 调用 catch
- [x] 显示错误提示

### TTS/ASR 错误
- [x] TTS 播放失败 try-catch
- [x] ASR 录音失败 try-catch
- [x] 错误日志打印

### 状态错误
- [x] 空操作符检查
- [x] 空目标 ID 检查
- [x] 空消息内容检查

---

## 📝 待优化项目

### 性能优化
- [ ] 接线员立绘缓存
- [ ] 列表优化（台词历史）
- [ ] 懒加载非关键资源

### 用户体验
- [ ] 波形动画可视化
- [ ] 错误提示优化（Toast/Snackbar）
- [ ] 加载状态优化
- [ ] 触觉反馈

### 测试
- [ ] 单元测试
- [ ] 集成测试
- [ ] 真实设备测试

---

**检查日期**: 2026-03-09
**检查状态**: ✅ 所有核心业务逻辑已实现
**可开始测试**: ✅ 是
