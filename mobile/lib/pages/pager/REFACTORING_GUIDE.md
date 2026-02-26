# 虚拟接线员拨号页面 - 重构指南

## 概述

本次重构在原有架构基础上，引入了以下核心创新功能：

1. **操作员人格系统** - 支持多个虚拟接线员，每个具有独特的人格、语音和台词
2. **极简初始态UI** - 精简的数字输入界面，提高用户体验
3. **智能文本处理** - 实时表情符号检测与过滤，支持文本编辑
4. **人格解锁机制** - 首次完成与接线员的对话后解锁，并在图鉴展示
5. **操作员图鉴系统** - 展示已解锁和未解锁的接线员，支持详情查看

## 新增文件

### 模型层 (Models)

#### `models/operator_model.dart`
定义操作员人格的数据结构：

- **OperatorPersonality** - 接线员人格实体，包含：
  - 基本信息：ID、名称、描述、立绘URL、首字母头像
  - 语音配置：TTS ID、语速
  - 台词配置：问候语、确认语、警告语、成功语等
  - 解锁状态：是否已解锁、解锁时间、对话次数

- **OperatorDialogues** - 接线员台词配置
- **OperatorFactory** - 预定义操作员工厂类，包含4个默认操作员：
  - 小红：专业型
  - 小美：温暖型
  - 小刚：活泼型
  - 小月：神秘型

### 服务层 (Services)

#### `services/operator_service.dart`
接线员管理服务，功能包括：

- 初始化并加载已解锁的操作员列表
- 解锁新操作员（首次完成对话时触发）
- 追踪每个操作员的对话次数
- 获取随机操作员（优先已解锁）
- 本地持久化存储（SharedPreferences）

```dart
final operatorService = OperatorService();
await operatorService.init();

// 获取随机操作员
final operator = operatorService.getRandomOperator();

// 解锁操作员
await operatorService.unlockOperator('op_001');

// 增加对话次数
await operatorService.incrementConversationCount('op_001');
```

#### `services/text_processor.dart`
文本处理和验证服务，功能包括：

- 检测文本中的表情符号（支持多种Unicode范围）
- 清理文本（移除表情符号）
- 文本长度验证（1-160字符）
- 生成TTS可用的文本
- 文本统计分析

```dart
final result = TextProcessor.processText('你好👋');
// result.hasEmoji == true
// result.cleanedText == '你好'
// result.detectedEmojis == ['👋']

// 检查是否包含表情符号
if (TextProcessor.containsEmoji(text)) {
  // 显示警告
}
```

### 页面层 (Pages)

#### `pages/dialing_prep_page_minimal.dart`
极简初始态页面（取代原有的复杂布局）：

- 中心灵动数字输入区域，带脉冲动画
- 圆形九键数字盘（视觉更简洁）
- 简化的删除/清空按钮
- 最小化的视觉元素，聚焦用户输入

**UI特点**：
- 输入区域带蓝色边框和脉冲动画
- 圆形数字键而非方形
- 整体白色背景，清爽简洁

#### `pages/operator_gallery_page_new.dart`
操作员图鉴页面（新增功能）：

- 网格显示所有操作员
- 已解锁：完整展示立绘、名称、描述、对话次数
- 未解锁：黑影占位符，显示锁定徽章
- 集合进度统计和进度条
- 点击操作员卡片查看详细信息

**功能特点**：
- 右上角快速入口在AppBar中
- 黑影Silhouette风格展示未解锁操作员
- 支持查看操作员详细信息和解锁日期

### 状态管理 (State)

#### `state/pager_state_machine.dart` - 更新

**DialingPrepState** 新增字段：
```dart
final OperatorPersonality? currentOperator;  // 当前选择的接线员
```

**InCallState** 新增字段：
```dart
final OperatorPersonality? operator;              // 当前接线员人格
final TextProcessingResult? textProcessingResult; // 文本处理结果
final bool hasEmojiDetected;                      // 是否检测到表情符号
final bool showEmojiWarning;                      // 是否显示表情符号警告
```

**FinalizeState** 新增字段：
```dart
final OperatorPersonality? operator;       // 当前接线员人格
final bool isEditing;                      // 是否处于编辑模式
final TextProcessingResult? textProcessingResult;
final bool isNewlyUnlocked;                // 是否新解锁
```

**新增状态**：
```dart
class OperatorUnlockedState extends PagerState {
  final OperatorPersonality operator;
  final String unlockMessage;
}
```

#### `state/pager_cubit.dart` - 更新

新增功能方法：

```dart
// 编辑消息相关
void startEditingMessage()
void updateEditingMessage(String newContent)
void finishEditingMessage()
void cancelEditingMessage()

// 播放警告语音
Future<void> _playEmojiWarning(OperatorPersonality? operator)
```

改进点：
- 自动选择随机操作员
- 使用操作员的TTS ID和语速进行语音合成
- 检测表情符号并播放警告语音
- 首次对话完成后自动解锁操作员
- 显示解锁提示对话框

### 主页面 (Main)

#### `pager_page_enhanced.dart`（新增）
增强版主页面，集成所有新功能：

```dart
// 使用新功能
const PagerPageEnhanced()
```

特点：
- AppBar右侧有"拨号员展示"入口
- 监听OperatorUnlockedState，弹出解锁提示
- 集成极简初始态页面
- 支持导航到图鉴页面

## 工作流程

### 完整交互流程

```
1. 初始态（DialingPrepState）
   ↓ 输入ID并拨号
   ↓
2. 通话中（InCallState）
   ├─ 播放接线员问候（使用其TTS语音）
   ├─ 启动ASR录音
   ├─ 实时转写用户话语
   ├─ 检测表情符号 → 播放警告语音
   └─ 检测静默 → 转移
   ↓
3. 消息准备（FinalizeState）
   ├─ 显示消息内容
   ├─ 支持编辑（删除/修改表情符号会被过滤）
   └─ 用户确认发送
   ↓
4. 发送消息 + 解锁检查
   ├─ 若为首次与该操作员对话 → 解锁操作员
   ├─ 增加对话计数
   ├─ 播放成功语音
   └─ 转移到解锁提示或返回初始态
```

### 表情符号处理流程

```
1. ASR转写文本
   ↓
2. TextProcessor.processText(text)
   ├─ 检测表情符号
   ├─ 清理文本（移除表情符号）
   └─ 返回处理结果
   ↓
3. 如果检测到表情符号
   ├─ 更新UI显示警告
   ├─ 播放接线员警告语音
   └─ 3秒后隐藏警告
   ↓
4. 最终发送清理后的文本
```

## 数据流

### 操作员解锁流程

```
接线员对话完成
   ↓
检查：是否为首次与该操作员对话？
   ├─ 是 → 调用 operatorService.unlockOperator()
   └─ 保存到 SharedPreferences
   ↓
增加对话次数：operatorService.incrementConversationCount()
   ↓
发送通知：emit(OperatorUnlockedState)
   ↓
UI显示：解锁提示对话框 + 查看图鉴入口
```

## 迁移指南

### 从旧版本升级

#### 1. 更新Import

```dart
// 旧
import 'pages/pager_page_refactored.dart';

// 新
import 'pages/pager_page_enhanced.dart';
```

#### 2. 初始化

```dart
// 新增初始化
final operatorService = OperatorService();
await operatorService.init();

// 传入Cubit
final cubit = PagerCubit(operatorService: operatorService);
```

#### 3. 使用新页面

```dart
// 替换主页面
// const PagerPageRefactored() →
const PagerPageEnhanced()
```

#### 4. 访问操作员数据

```dart
// 获取所有操作员
final operators = operatorService.getAllOperators();

// 检查是否已解锁
final unlocked = operatorService.isOperatorUnlocked('op_001');

// 获取解锁进度
final count = operatorService.getUnlockedCount();
```

## 扩展点

### 添加新的操作员

在 `operator_model.dart` 的 `OperatorFactory.defaultOperators` 中添加：

```dart
OperatorPersonality(
  id: 'op_005',
  name: '小王',
  description: '新的接线员人格',
  portraitUrl: 'assets/operators/xiaowang.png',
  initials: 'XW',
  ttsId: 4,
  ttsSpeed: 1.0,
  dialogues: OperatorDialogues(
    greeting: '你好，我是小王',
    confirmId: '确认ID：%s',
    verify: '正在核实...',
    requestMessage: '请说出你的想法',
    emojiWarning: '不支持表情符号',
    successMessage: '消息已发送',
    userNotFound: '用户不存在',
    randomPhrases: ['很高兴认识你'],
  ),
)
```

### 自定义文本处理规则

继承 `TextProcessor` 或修改 `_isInEmojiRange()` 方法以支持更多字符范围。

### 集成真实ASR

替换 `pager_cubit.dart` 中的 `_simulateAsrTranscription()` 方法，集成真实ASR引擎。

## 测试

### 基本测试用例

```dart
// 测试文本处理
test('emoji detection', () {
  final result = TextProcessor.processText('Hello 👋');
  expect(result.hasEmoji, true);
  expect(result.cleanedText, 'Hello ');
});

// 测试操作员管理
test('operator unlock', () async {
  await operatorService.unlockOperator('op_001');
  expect(operatorService.isOperatorUnlocked('op_001'), true);
});

// 测试状态转换
test('dialing state machine', () {
  final cubit = PagerCubit();
  cubit.initializeDialingPrep();
  expect(cubit.state, isA<DialingPrepState>());
});
```

## 依赖

新增依赖：
- `shared_preferences` - 本地存储操作员解锁状态
- `collection` - 提供扩展方法（firstWhereOrNull等）

## 性能注意事项

1. **表情符号检测** - 使用Unicode范围检查，O(n)时间复杂度
2. **本地存储** - 使用SharedPreferences缓存，避免反复加载
3. **动画优化** - 脉冲动画使用repeat()，无需手动管理
4. **内存管理** - 及时dispose动画控制器和Cubit

## 常见问题

### Q: 如何自定义操作员的语音速度？
A: 在操作员配置中修改 `ttsSpeed` 属性（0.5-2.0）

### Q: 表情符号警告语音支持哪些语言？
A: 当前支持中文，可在 `OperatorDialogues.emojiWarning` 中自定义

### Q: 如何重置所有解锁记录？
A: 调用 `operatorService.clearAllUnlocks()`

### Q: 能否同时显示多个操作员？
A: 当前设计为单一操作员会话，如需多人会议可扩展InCallPage

## 未来计划

- [ ] 支持操作员自定义配置文件（JSON导入）
- [ ] 操作员收藏系统
- [ ] 操作员对话记录和回放
- [ ] 实时语音识别集成（Sherpa ONNX）
- [ ] 操作员之间的对话推荐
- [ ] 成就系统（完成X次对话等）

## 更新日志

### v2.0.0 (2024-02-26)
- ✨ 新增操作员人格系统（4个默认操作员）
- ✨ 新增操作员图鉴和解锁机制
- ✨ 新增智能表情符号检测和过滤
- ✨ 新增文本编辑功能
- 🎨 重新设计初始态UI（极简风格）
- 📦 新增OperatorService和TextProcessor服务
- 🚀 支持本地持久化存储

### v1.0.0 (2024-02-20)
- 初始版本，包含基础拨号、通话、发送功能
