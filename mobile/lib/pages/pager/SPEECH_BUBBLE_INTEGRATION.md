# 语音气泡和增强版语音服务集成指南

## 概述

本指南详细说明如何在虚拟接线员拨号页面中集成语音气泡显示系统和增强版语音服务（VoiceServiceEnhanced）。这两个组件协同工作，确保即使TTS服务异常，虚拟接线员也能通过视觉气泡与用户进行有效交互。

## 核心组件

### 1. SpeechBubble & SpeechBubbleContainer
- **位置**: `widgets/speech_bubble_widget.dart`
- **职责**: 显示单个话语气泡，管理气泡集合和位置
- **特性**: 灵动的入场/离场动画，自动位置计算，屏幕边界检测

### 2. VoiceServiceEnhanced
- **位置**: `services/voice_service_enhanced.dart`
- **职责**: 包装原始VoiceService，提供TTS失败时的自动降级
- **特性**: 失败计数、自动恢复、强制模式切换

### 3. SpeechBubbleManager
- **位置**: `widgets/speech_bubble_widget.dart`
- **职责**: 全局气泡管理接口
- **特性**: 单例模式，提供简洁的API

## 快速开始

### 1. 基础集成（5分钟）

#### 步骤1: 在页面中添加气泡容器

```dart
class InCallPage extends StatefulWidget {
  @override
  State<InCallPage> createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> {
  final GlobalKey _operatorDisplayKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要内容
        SafeArea(
          child: Column(
            children: [
              // 接线员立绘
              Container(
                key: _operatorDisplayKey,
                child: OperatorDisplayWidget(...)
              ),
              // ... 其他UI
            ]
          )
        ),

        // 话语气泡容器（浮层）
        SpeechBubbleContainer(
          targetKey: _operatorDisplayKey,
          containerSize: MediaQuery.of(context).size,
          containerOffset: Offset.zero,
        ),
      ],
    );
  }
}
```

#### 步骤2: 使用增强版语音服务

```dart
// 在PagerCubit中
class PagerCubit extends Cubit<PagerState> {
  final VoiceServiceEnhanced _voiceService;

  PagerCubit({VoiceServiceEnhanced? voiceService})
    : _voiceService = voiceService ?? VoiceServiceEnhanced();

  Future<void> _playGuidanceTts() async {
    const text = '您好，请说出您要传达的消息';
    
    // 自动处理TTS失败降级
    final usedTts = await _voiceService.speak(
      text,
      sid: 0,
      speed: 1.0,
    );
    
    print('Used TTS: $usedTts');  // true = 使用了音频, false = 仅显示气泡
  }
}
```

#### 步骤3: 手动显示气泡（可选）

```dart
// 获取全局管理器
final bubbleManager = SpeechBubbleManager();

// 显示基础气泡
bubbleManager.showSpeech(
  text: '你好，欢迎使用传呼服务',
  isOperator: true,
);

// 显示成功气泡
bubbleManager.showSuccess(text: '消息已发送');

// 显示警告气泡
bubbleManager.showWarning(text: '检测到表情符号');

// 显示错误气泡
bubbleManager.showError(text: '发送失败，请重试');
```

## 详细使用示例

### 示例1: 完整的拨号流程（带气泡）

```dart
Future<void> startDialing(String targetId) async {
  try {
    const operator = OperatorPersonality(...);
    
    // 显示问候语（自动处理TTS失败）
    await _voiceService.speak(
      '您好，欢迎使用传呼',
      sid: operator.ttsId,
      speed: operator.ttsSpeed,
    );
    
    // 等待用户输入
    emit(InCallState(targetId: targetId, operator: operator));
    
    // 播放请求消息
    await _voiceService.speak(
      '请说出您要传达的消息',
      sid: operator.ttsId,
    );
    
    // 启动ASR...
  } catch (e) {
    // 错误也会显示为气泡
    _bubbleManager.showError(text: '发生错误: $e');
  }
}
```

### 示例2: 处理表情符号警告

```dart
Future<void> detectAndWarnEmojis(String text) async {
  final result = TextProcessor.processText(text);
  
  if (result.hasEmoji) {
    // 使用气泡显示警告（自带警告样式）
    final usedTts = await _voiceService.speak(
      operator.dialogues.emojiWarning,
      sid: operator.ttsId,
    );
    
    // 如果TTS失败，气泡仍以警告样式显示
    if (!usedTts) {
      _bubbleManager.showWarning(
        text: operator.dialogues.emojiWarning,
      );
    }
  }
}
```

### 示例3: 无声模式（无障碍）

```dart
// 启用无声模式（仅显示气泡，不播放音频）
_voiceService.forceTtsDisabled();

// 之后所有speak()调用都只显示气泡
await _voiceService.speak('这只会显示为气泡');
// 气泡有 "无音频" 指示

// 恢复声音
_voiceService.forceTtsEnabled();
```

### 示例4: 自定义气泡显示

```dart
// 系列话语（顺序播放）
await _voiceService.speakSequence([
  '第一句话',
  '第二句话',
  '第三句话',
], delayBetween: Duration(seconds: 1));

// 转换为气泡显示
_bubbleManager.showSpeech(
  text: '自定义话语内容',
  style: SpeechBubbleStyle.primary,      // 样式
  isOperator: true,                      // 是否为接线员
  hasAudio: false,                       // 是否有音频
  displayDuration: Duration(seconds: 5), // 显示时长
  position: SpeechBubblePosition.topRight, // 位置
);
```

### 示例5: 监听TTS状态

```dart
class PagerCubit extends Cubit<PagerState> {
  void _monitorTtsStatus() {
    // 在UI中展示TTS状态
    if (_voiceService.isTtsAvailable) {
      print('TTS: 可用');
    } else {
      print('TTS: 已禁用（仅使用气泡）');
    }
    
    // 获取诊断信息
    final diagnostics = _voiceService.getDiagnostics();
    print('失败计数: ${diagnostics['ttsFailureCount']}');
    print('正在播放: ${diagnostics['isPlaying']}');
  }
}
```

## 最佳实践

### 1. 气泡位置管理

**不推荐**: 气泡与关键UI元素重叠
```dart
// ❌ 不好
SpeechBubblePosition.center  // 可能遮挡输入框
```

**推荐**: 使用auto让系统自动选择最优位置
```dart
// ✅ 好
SpeechBubblePosition.auto  // 自动避开关键区域
```

### 2. 显示时长计算

**不推荐**: 固定时长
```dart
// ❌ 不好
displayDuration: Duration(seconds: 3)  // 短话语显示时间不够，长话语消失太快
```

**推荐**: 基于文本长度动态计算
```dart
// ✅ 好
Duration _calculateBubbleDuration(String text) {
  final baseSeconds = 2;
  final additionalSeconds = (text.length / 10).ceil();
  final totalSeconds = (baseSeconds + additionalSeconds).clamp(2, 10);
  return Duration(seconds: totalSeconds);
}
```

### 3. 错误处理

**不推荐**: 让TTS异常导致应用崩溃
```dart
// ❌ 不好
await _voiceService.speak(text);  // 如果失败会抛异常
```

**推荐**: 使用增强版语音服务的自动降级
```dart
// ✅ 好
final usedTts = await _voiceService.speak(text);
if (!usedTts) {
  print('TTS失败，已自动显示气泡');
}
```

### 4. 性能优化

**不推荐**: 一次显示太多气泡
```dart
// ❌ 不好
for (int i = 0; i < 100; i++) {
  _bubbleManager.showSpeech(text: '气泡 $i');
}
```

**推荐**: 限制同时显示的气泡数量
```dart
// ✅ 好
// 在SpeechBubbleContainer中限制
const maxBubblesOnScreen = 3;
if (_activeBubbles.length < maxBubblesOnScreen) {
  _activeBubbles.add(bubble);
}
```

### 5. 资源管理

**不推荐**: 忘记释放资源
```dart
// ❌ 不好
@override
void dispose() {
  super.dispose();
  // 忘记释放_voiceService
}
```

**推荐**: 正确释放所有资源
```dart
// ✅ 好
@override
Future<void> dispose() async {
  await _voiceService.dispose();
  // 其他清理...
  super.dispose();
}
```

## 故障排除

### 问题1: 气泡不显示

**症状**: `showSpeech()`被调用但没有气泡出现

**原因**: 可能未注册SpeechBubbleContainer

**解决方案**:
```dart
// 确保在build()方法中包含SpeechBubbleContainer
Stack(
  children: [
    // 主内容
    SafeArea(...),
    
    // ⚠️ 必须包含此容器
    SpeechBubbleContainer(
      targetKey: _operatorDisplayKey,
      containerSize: MediaQuery.of(context).size,
      containerOffset: Offset.zero,
    ),
  ],
);
```

### 问题2: 气泡显示位置不对

**症状**: 气泡覆盖了立绘或其他UI

**原因**: 位置计算逻辑有问题或targetKey没有正确绑定

**解决方案**:
```dart
// 确保立绘有正确的Key
Container(
  key: _operatorDisplayKey,  // ⚠️ 必须设置
  child: OperatorDisplayWidget(...),
)

// 使用auto位置让系统自动调整
position: SpeechBubblePosition.auto,
```

### 问题3: TTS总是失败

**症状**: `isTtsAvailable`始终为false

**原因**: 初始化失败或连续失败3次

**解决方案**:
```dart
// 诊断
final diagnostics = _voiceService.getDiagnostics();
print('TTS诊断: $diagnostics');

// 手动恢复
_voiceService.forceTtsEnabled();
_voiceService.resetTtsState();

// 检查日志
logger.i('TTS失败次数: ${diagnostics['ttsFailureCount']}');
```

### 问题4: 气泡动画卡顿

**症状**: 气泡入场/离场动画方式不流畅

**原因**: 动画时长设置不当或设备性能不足

**解决方案**:
```dart
// 检查是否启用了"减弱动画"
final mediaQuery = MediaQuery.of(context);
if (mediaQuery.disableAnimations) {
  // 禁用SpeechBubble中的所有动画
}

// 减少活跃气泡数量
const maxBubblesOnScreen = 2;  // 减少并发
```

### 问题5: 屏幕阅读器无法识别气泡

**症状**: 视障用户无法听到气泡内容

**原因**: 缺少Semantics标记

**解决方案**:
```dart
// 在SpeechBubble中添加Semantics
Semantics(
  label: '接线员说话',
  button: false,
  enabled: true,
  onTap: () {},
  child: Container(...),
)
```

## 性能优化建议

### 1. 气泡缓存

```dart
// 复用气泡Widget而不是每次创建新的
@override
Widget build(BuildContext context) {
  return CacheProvider(
    cacheKey: 'speech_bubble_${data.id}',
    builder: (_) => SpeechBubble(data: data),
  );
}
```

### 2. 动画优化

```dart
// 使用RepaintBoundary减少重绘
RepaintBoundary(
  child: SpeechBubble(...),
)
```

### 3. 内存管理

```dart
// 强制清理过期气泡
void _cleanupExpiredBubbles() {
  _activeBubbles.removeWhere((bubble) {
    return DateTime.now().difference(bubble.createdAt).inSeconds > 15;
  });
}
```

### 4. 取消不必要的TTS请求

```dart
// 如果新请求来临，取消旧的TTS
if (_voiceService.isPlaying) {
  await _voiceService.stop();
}
await _voiceService.speak(newText);
```

## 配置选项

### VoiceServiceEnhanced配置

```dart
// 创建时自定义
final service = VoiceServiceEnhanced(
  voiceService: MyCustomVoiceService(),  // 使用自定义VoiceService
);

// 初始化
await service.init();

// 强制模式
service.forceTtsDisabled();   // 仅气泡
service.forceTtsEnabled();    // 仅音频
service.resetTtsState();      // 恢复正常

// 获取状态
print(service.isTtsAvailable);  // true/false
print(service.isPlaying);       // 是否正在播放
print(service.getDiagnostics());  // 完整诊断
```

### SpeechBubbleManager配置

```dart
final manager = SpeechBubbleManager();

// 显示各种类型
manager.showSpeech(...);     // 基础
manager.showSuccess(...);    // 成功
manager.showWarning(...);    // 警告
manager.showError(...);      // 错误
```

## 测试指南

### 单元测试

```dart
test('voice service fallback', () async {
  final service = VoiceServiceEnhanced();
  await service.init();
  
  // 模拟TTS失败
  final result = await service.speak('test', forceBubble: true);
  
  expect(result, false);  // 应返回false
});
```

### Widget测试

```dart
testWidgets('speech bubble appears', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            SpeechBubbleContainer(...),
          ],
        ),
      ),
    ),
  );
  
  // 验证气泡是否显示
  expect(find.byType(SpeechBubble), findsOneWidget);
});
```

### 集成测试

```dart
test('complete flow with bubbles', () async {
  // 1. 启动拨号
  // 2. 验证问候气泡显示
  // 3. 输入ID
  // 4. 验证确认气泡显示
  // 5. 等待ASR
  // 6. 验证消息气泡显示
  // 7. 发送消息
  // 8. 验证成功气泡显示
});
```

## 常见问题

**Q: 气泡和TTS可以同时显示吗？**
A: 可以。VoiceServiceEnhanced会同时显示气泡和播放TTS（如果可用）。气泡中会显示"有音频"图标。

**Q: 如何自定义气泡外观？**
A: 修改SpeechBubble中的颜色、尺寸和字体。所有样式都在`_getBackgroundColor()`等方法中定义。

**Q: 气泡支持图片或其他媒体吗？**
A: 当前仅支持文本。如需扩展，可继承SpeechBubble并添加媒体支持。

**Q: 如何处理很长的话语？**
A: 气泡会自动截断超过3行的文本并显示省略号。建议将长话语分成多条短气泡。

**Q: TTS失败后会自动恢复吗？**
A: 会。如果TTS失败少于3次，下一次请求时会重新尝试。如果连续失败3次，会永久切换到气泡模式，直到手动调用`forceTtsEnabled()`。

## 更新日志

### v2.1.0 (2024-02-27)
- ✨ 新增完整的集成指南
- ✨ 添加性能优化建议
- ✨ 提供测试用例
- 🔧 改进气泡位置计算
- 📝 添加常见问题解答

### v2.0.0 (2024-02-26)
- 新增语音气泡显示系统
- 新增TTS失败降级机制
- 新增增强版语音服务
