# 虚拟接线员拨号页面 - 快速参考卡片

## 🎯 一句话总结
多人格虚拟接线员拨号系统，带灵动气泡显示、TTS自动降级、人格解锁机制，支持无障碍。

---

## ⚡ 快速开始（3步）

```dart
// 1. 导入
import 'pages/pager/pager_page_enhanced.dart';

// 2. 使用
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const PagerPageEnhanced());
  }
}

// 3. 完成！🎉
```

---

## 📖 API 速查表

### 话语气泡
```dart
// 显示基础气泡
SpeechBubbleManager().showSpeech(text: '你好');

// 显示成功气泡
SpeechBubbleManager().showSuccess(text: '发送成功');

// 显示警告气泡
SpeechBubbleManager().showWarning(text: '检测到表情');

// 显示错误气泡
SpeechBubbleManager().showError(text: '发送失败');

// 自定义气泡
SpeechBubbleManager().showSpeech(
  text: '自定义内容',
  style: SpeechBubbleStyle.primary,
  position: SpeechBubblePosition.topRight,
  displayDuration: Duration(seconds: 5),
  hasAudio: true,
  isOperator: true,
);
```

### 语音服务
```dart
// 说话（自动降级）
final usedTts = await voiceService.speak(
  '欢迎使用',
  sid: 0,
  speed: 1.0,
);

// 顺序播放多句
await voiceService.speakSequence(['第一句', '第二句']);

// 停止播放
await voiceService.stop();

// 强制模式
voiceService.forceTtsDisabled();  // 仅气泡
voiceService.forceTtsEnabled();   // 仅音频
voiceService.resetTtsState();     // 重置

// 获取状态
print(voiceService.isTtsAvailable);
print(voiceService.isPlaying);
print(voiceService.getDiagnostics());
```

### 文本处理
```dart
// 检测表情符号
final result = TextProcessor.processText('你好👋');
result.hasEmoji;       // true
result.detectedEmojis; // ['👋']
result.cleanedText;    // '你好'
result.isValid;        // true/false

// 快速检查
if (TextProcessor.containsEmoji(text)) {
  print('包含表情符号');
}

// 获取长度
final length = TextProcessor.getTextLength(text);

// 清理文本
final clean = TextProcessor.sanitizeText(text);

// 文本统计
final stats = TextProcessor.analyzeText(text);
print('中文字符: ${stats.chineseCharCount}');
print('表情符号: ${stats.emojiCount}');
```

### 接线员管理
```dart
// 初始化
final operatorService = OperatorService();
await operatorService.init();

// 获取操作员
final operator = operatorService.getRandomOperator();
final byId = operatorService.getOperatorById('op_001');

// 获取列表
final all = operatorService.getAllOperators();
final unlocked = operatorService.getUnlockedOperators();
final locked = operatorService.getLockedOperators();

// 解锁操作员
await operatorService.unlockOperator('op_001');

// 增加对话计数
await operatorService.incrementConversationCount('op_001');

// 查看状态
print(operatorService.isOperatorUnlocked('op_001'));
print(operatorService.getUnlockedCount()); // 已解锁数量

// 管理状态
await operatorService.resetOperator('op_001');
await operatorService.clearAllUnlocks();
```

### Cubit 操作
```dart
// 初始化
final cubit = PagerCubit(operatorService: operatorService);
await cubit.initializeDialingPrep();

// 拨号
await cubit.startDialing('12345');

// 编辑消息
cubit.startEditingMessage();
cubit.updateEditingMessage('新内容');
cubit.finishEditingMessage();
cubit.cancelEditingMessage();

// 发送
await cubit.sendMessage();

// 挂断
await cubit.hangup();
await cubit.cancel();

// 清理
await cubit.close();
```

---

## 🎨 枚举值参考

### SpeechBubbleStyle
- `primary` - 普通（蓝色）
- `warning` - 警告（橙色）
- `success` - 成功（绿色）
- `error` - 错误（红色）

### SpeechBubblePosition
- `auto` - 自动选择
- `topLeft` - 左上
- `topRight` - 右上
- `bottomLeft` - 左下
- `bottomRight` - 右下
- `center` - 中心

### PagerState
- `DialingPrepState` - 拨号准备
- `InCallState` - 通话中
- `FinalizeState` - 消息准备
- `OperatorUnlockedState` - 解锁提示
- `PagerErrorState` - 错误
- `PagerInitialState` - 初始

---

## 🔌 常见代码片段

### 完整拨号流程
```dart
Future<void> completeDialingFlow(String targetId) async {
  // 1. 选择操作员
  final operator = operatorService.getRandomOperator();
  
  // 2. 检查是否首次
  final isFirstTime = !operatorService.isOperatorUnlocked(operator.id);
  
  // 3. 开始拨号
  await cubit.startDialing(targetId);
  
  // 4. 等待ASR（在InCallState中进行）
  // ...
  
  // 5. 检查表情符号
  final textResult = TextProcessor.processText(asrText);
  if (textResult.hasEmoji) {
    // 获取警告语言
    final warning = operator.dialogues.emojiWarning;
    await voiceService.speak(warning, sid: operator.ttsId);
  }
  
  // 6. 发送消息
  await cubit.sendMessage();
  
  // 7. 如果首次，自动解锁
  if (isFirstTime) {
    await operatorService.unlockOperator(operator.id);
  }
}
```

### TTS 失败处理
```dart
Future<void> handleTtsFailure() async {
  // 方式1：自动降级（推荐）
  final usedTts = await voiceService.speak(text);
  if (!usedTts) {
    print('TTS失败，已自动显示气泡');
  }
  
  // 方式2：手动检查
  if (!voiceService.isTtsAvailable) {
    // 永久禁用，仅使用气泡
    SpeechBubbleManager().showSpeech(text: text);
  }
  
  // 方式3：诊断信息
  final diag = voiceService.getDiagnostics();
  if (diag['ttsFailureCount'] >= 3) {
    print('连续失败，已禁用TTS');
  }
}
```

### 无障碍设置
```dart
// 启用无声模式（无障碍用户）
void enableAccessibilityMode() {
  voiceService.forceTtsDisabled();
  // 所有话语仅显示气泡，不播放音频
}

// 禁用动画（对动画敏感的用户）
bool shouldDisableAnimations(BuildContext context) {
  return MediaQuery.of(context).disableAnimations;
}

// 检查屏幕阅读器
bool isScreenReaderEnabled(BuildContext context) {
  return MediaQuery.of(context).highContrast;
}
```

### 表情符号处理
```dart
// 检测并清理
String filterEmojis(String text) {
  final result = TextProcessor.processText(text);
  
  if (result.hasEmoji) {
    // 显示警告
    SpeechBubbleManager().showWarning(
      text: '检测到${result.detectedEmojis.length}个表情符号'
    );
    
    // 返回清理后的文本
    return result.cleanedText;
  }
  
  return text;
}
```

---

## 🚨 常见问题速解

| 问题 | 解决方案 |
|------|---------|
| 气泡不显示 | 确保添加了`SpeechBubbleContainer`到Stack中 |
| TTS总是失败 | 检查`voiceService.isTtsAvailable`，手动调用`forceTtsEnabled()` |
| 气泡位置重叠 | 使用`SpeechBubblePosition.auto`让系统自动调整 |
| 表情符号未被检测 | 确保调用了`TextProcessor.processText()` |
| 操作员未解锁 | 需要完成完整拨号流程+消息发送才能解锁 |
| 屏幕阅读器无法识别 | 确保所有UI元素都有Semantics标签 |
| 动画卡顿 | 检查设备性能，减少并发气泡数量 |

---

## 📁 文件导航

```
pager/
├── models/operator_model.dart           # 操作员定义
├── services/
│   ├── operator_service.dart            # 操作员管理
│   ├── text_processor.dart              # 文本处理
│   ├── voice_service_enhanced.dart      # 增强语音服务
│   └── waveform_processor.dart          # 波形处理
├── widgets/speech_bubble_widget.dart    # 气泡显示
├── pages/
│   ├── dialing_prep_page_minimal.dart   # 初始态
│   ├── in_call_page.dart                # 通话页面
│   ├── finalize_page.dart               # 消息页面
│   └── operator_gallery_page_new.dart   # 图鉴页面
├── state/
│   ├── pager_state_machine.dart         # 状态定义
│   └── pager_cubit.dart                 # 业务逻辑
└── pager_page_enhanced.dart             # 主页面
```

---

## 🎯 关键概念图解

### 气泡显示流程
```
TTS播报
  ↓
生成气泡数据
  ↓
计算显示位置
  ↓
显示气泡 + 入场动画
  ↓
上浮 + 渐隐
  ↓
消失 + 离场动画
```

### TTS失败降级
```
speak() 调用
  ↓
TTS失败？
  ├─ 否 → 显示气泡 + 播放音频 ✅
  └─ 是 → 失败计数 +1
       ↓
       连续失败3次？
       ├─ 否 → 重试 speak()
       └─ 是 → 永久禁用TTS
            ↓
            显示气泡（仅视觉）✅
```

### 解锁流程
```
拨号 → 通话 → 消息 → 发送
                         ↓
                    是否首次？
                   ├─ 否 → 返回初始态
                   └─ 是 → 自动解锁
                        ↓
                    显示解锁提示
                        ↓
                    保存到本地
```

---

## 🔑 快捷操作

| 操作 | 代码 |
|------|------|
| 显示气泡 | `SpeechBubbleManager().showSpeech(text: '...')` |
| 说话 | `await voiceService.speak('...')` |
| 发送消息 | `await cubit.sendMessage()` |
| 获取随机操作员 | `operatorService.getRandomOperator()` |
| 检测表情 | `TextProcessor.containsEmoji(text)` |
| 禁用TTS | `voiceService.forceTtsDisabled()` |
| 查看状态 | `cubit.state` |
| 清理资源 | `await cubit.close()` |

---

## 📚 文档链接

- 🏗️ 架构设计 → `ARCHITECTURE.md`
- 🔄 重构指南 → `REFACTORING_GUIDE.md`
- ♿ 无障碍 → `ACCESSIBILITY_GUIDE.md`
- 💬 气泡集成 → `SPEECH_BUBBLE_INTEGRATION.md`
- 📊 功能总结 → `FEATURE_SUMMARY.md`

---

## ⚙️ 依赖版本

```yaml
flutter_bloc: ^8.1.0
equatable: ^2.0.0
cached_network_image: ^3.2.0
sound_stream: ^0.8.0
just_audio: ^0.9.0
shared_preferences: ^2.0.0
collection: ^1.17.0
```

---

## 🎓 学习路径

### 初级开发者
1. 了解基本UI布局（初始态、通话页）
2. 学习如何显示气泡
3. 操作状态机

### 中级开发者
1. 学习TTS失败处理
2. 集成无障碍支持
3. 自定义操作员

### 高级开发者
1. 优化性能（气泡池化、动画帧率）
2. 扩展ASR引擎集成
3. 添加多语言支持

---

## 🐛 调试技巧

```dart
// 1. 查看当前状态
print('当前状态: ${cubit.state}');

// 2. 监听状态变化
cubit.stream.listen((state) => print('新状态: $state'));

// 3. 查看TTS诊断
print('TTS诊断: ${voiceService.getDiagnostics()}');

// 4. 打印操作员信息
final ops = operatorService.getAllOperators();
ops.forEach((op) => print('${op.name}: 已解锁=${op.isUnlocked}'));

// 5. 查看文本处理结果
final result = TextProcessor.processText(text);
print('表情: ${result.detectedEmojis}');
print('清理: ${result.cleanedText}');
```

---

## 💡 最佳实践

✅ **推荐**
- 总是使用增强版语音服务（自动降级）
- 在Stack中包含SpeechBubbleContainer
- 使用位置auto让系统自动选择最优位置
- 定期检查TTS状态和诊断

❌ **不推荐**
- 忘记初始化服务
- 假设TTS总是可用
- 重复创建SpeechBubbleContainer
- 忽视表情符号检测

---

## 📞 获取帮助

1. 查看对应文档
2. 搜索FAQ
3. 检查日志输出
4. 提交Issue

---

**版本**: v2.1.0  
**最后更新**: 2024-02-27  
**状态**: ✅ 生产就绪
