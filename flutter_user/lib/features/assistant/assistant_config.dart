import 'package:flutter/material.dart';

/// 虚拟操作员模型类
class VirtualOperator {
  final String id;
  final String name;
  final String description;
  final Color themeColor;

  const VirtualOperator({
    required this.id,
    required this.name,
    required this.description,
    this.themeColor = const Color(0xFF2196F3),
  });

  // Placeholder for equality check if needed
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirtualOperator &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 关键词配置（集中管理）
/// 用于语音交互中的意图识别和流程控制
/// 每个关键词组对应特定的业务操作意图
const Map<String, List<String>> keywordGroups = {
  // 取消/退出操作：终止当前流程
  'cancel': ['取消', '退出', '停止', '放弃'],

  // 重试操作：重新执行失败或取消的操作
  'retry': ['重试', '再试', 'retry'],

  // 收信方ID确认：确认输入的收信方ID正确性
  'confirm': ['确定', '是', '对', 'ok', '好的'],

  // 修改操作：重新输入或修改当前信息
  'modify': ['修改', '更改', '重说', '重新'],

  // 消息确认：确认消息内容并准备发送
  'send': ['发送', '发出', '确定', '好发'],

  // 消息重录：重新录制消息内容
  'rerecord': ['重录', '重新', '再说', '重来'],

  // 澄清请求：当系统无法理解用户输入时使用（预留扩展）
  'clarify': [],
};

/// 操作员配置 - 语音助手角色定义（贴近VirtualOperator类型化）
/// 每个操作员包含完整的语音交互配置，包括TTS语音、台词脚本和UI主题
const Map<String, Map<String, dynamic>> operatorConfigs = {
  'op_system': {
    // 系统级操作员：简洁高效，适合专业环境
    // 业务流程：连接建立 -> 收信方ID录入 -> 消息录制 -> 确认发送 -> 连接结束
    'name': 'System',
    'description': 'Minimalistic system interface.',
    'themeColor': Colors.grey, // UI主题色：灰色表示系统级
    'voicePackageId': 'voice_system', // 语音包标识（预留扩展用）
    'ttsSid': 0, // TTS语音合成器ID：系统默认语音
    'portrait': 'images/operators/op_system.png', // 操作员头像路径
    'scripts': {
      // 业务流程状态对应的台词配置
      'greeting': '连接建立。Bipupu接线系统待命。', // 流程开始：连接建立
      'askRecipientId': '收信方ID录入。', // 流程状态：请求收信方ID
      'confirmRecipientId':
          '请确认收信方ID。"{recipientId}"。选择"确定"或"修改"。', // 流程状态：确认收信方ID
      'guideRecordMessage': '如提供信息，我将执行传输。请在嘟声后说出信息。', // 流程状态：引导录制消息
      'transcribing': '转写完成', // 流程状态：语音转写中
      'waiting_effect': 'none', // 等待效果：无（系统风格）
      'confirmMessage':
          '请确认内容是否准确。待传输信息为"{message}"。选择"发送"或"重录"。', // 流程状态：确认消息内容
      'send': '传输已执行。', // 流程状态：消息发送完成
      'farewell': '连接结束。', // 流程结束：连接关闭
      'clarify': '抱歉，请再说一遍？', // 异常处理：未识别输入
      'timeout': '抱歉，请再说一遍？', // 异常处理：超时未响应
    },
  },
  'op_001': {
    // 专业接线员青年男：亲切专业，适合客服场景
    // 业务流程：友好问候 -> 引导输入ID -> 确认ID -> 录制消息 -> 确认发送 -> 礼貌结束
    'name': '专业接线员青年男',
    'description': '专业、亲切的接线员（青年男声）。',
    'themeColor': Colors.teal, // UI主题色：青色表示专业亲切
    'voicePackageId': 'voice_001', // 语音包标识
    'ttsSid': 0, // TTS语音合成器ID：青年男声
    'portrait': 'images/operators/op_001.png',
    'scripts': {
      'greeting': '您好，这里是 Bipupu 接线台，我是您的接线员。',
      'askRecipientId': '请告诉我收信方的号码。',
      'confirmRecipientId': '确认一下，收信方的号码是"{recipientId}"，请说"确定"或"修改"。',
      'guideRecordMessage': '请在嘟声后说出您要发送的内容，完成后说"好了"或者等待我提示结束。',
      'transcribing': '我在记录您的内容，请稍等。',
      'waiting_effect': 'keyboard_sound', // 等待效果：键盘打字声（模拟录入）
      'confirmMessage': '我记录的是"{message}"，是否发送？说"发送"或"重录"。',
      'send': '好的，消息已为您发送。',
      'farewell': '感谢使用，祝您愉快。',
      'clarify': '抱歉，我没有听清，请再说一遍。',
      'timeout': '抱歉，能再重复一次吗？',
    },
  },
  'op_002': {
    // 冷漠高效机器人：简洁直接，适合技术环境
    // 业务流程：系统连接 -> 输入编号 -> 确认编号 -> 转写消息 -> 确认发送 -> 连接结束
    'name': '冷漠高效机器人',
    'description': '冷静、简练的机器人风格接线员。',
    'themeColor': Colors.indigo, // UI主题色：靛蓝表示科技感
    'voicePackageId': 'voice_002', // 语音包标识
    'ttsSid': 1, // TTS语音合成器ID：机器人声
    'portrait': 'images/operators/op_002.png',
    'scripts': {
      'greeting': '系统连接。Bipupu 接线台。',
      'askRecipientId': '请输入收信方编号。',
      'confirmRecipientId': '编号"{recipientId}"确认，请回复"确定"或"修改"。',
      'guideRecordMessage': '请在提示音后开始说话，我将转写并发送。',
      'transcribing': '转写中，请稍候。',
      'waiting_effect': 'none', // 等待效果：无（机器人风格）
      'confirmMessage': '确认内容："{message}"。是否发送？',
      'send': '已执行发送操作。',
      'farewell': '连接结束。',
      'clarify': '未识别内容，请重试。',
      'timeout': '未检测到语音，请再说一次。',
    },
  },
  'op_003': {
    // 活泼话痨少女：热情友好，适合休闲场景
    // 业务流程：热情问候 -> 引导输入 -> 确认输入 -> 录制消息 -> 确认发送 -> 亲切结束
    'name': '活泼话痨少女',
    'description': '活泼、热情、喜欢唠叨的接线员（少女声）。',
    'themeColor': Colors.orange, // UI主题色：橙色表示活泼热情
    'voicePackageId': 'voice_003', // 语音包标识
    'ttsSid': 2, // TTS语音合成器ID：少女声
    'portrait': 'images/operators/op_003.png',
    'scripts': {
      'greeting': '嗨～欢迎来到 Bipupu 接线台，我好开心见到你～',
      'askRecipientId': '快告诉我收信方的号码吧~',
      'confirmRecipientId': '嗯……号码是"{recipientId}"？说"确定"或者"修改"啦～',
      'guideRecordMessage': '好了好了，说你要传的话吧，我会认真记下来的，嘟～',
      'transcribing': '嗯哼，我记下了，马上读给你听～',
      'waiting_effect': 'keyboard_sound', // 等待效果：键盘打字声（模拟记录）
      'confirmMessage': '我写的是"{message}"，没错吧？说"发送"就好了哦～',
      'send': '收到啦～已经帮你发出去了～',
      'farewell': '拜拜～下次再来玩～',
      'clarify': '诶？我没听清楚，可以再说一次吗～',
      'timeout': '抱歉，我没听到你说话，能再来一次吗～',
    },
  },
  'op_004': {
    // 黑帮顾问中年男：威严沉稳，适合严肃场合
    // 业务流程：简短问候 -> 要求输入 -> 确认输入 -> 转写消息 -> 确认发送 -> 结束通话
    'name': '黑帮顾问中年男',
    'description': '低沉沙哑、稳重威严的中年男声接线员。',
    'themeColor': Colors.brown, // UI主题色：棕色表示稳重威严
    'voicePackageId': 'voice_004', // 语音包标识
    'ttsSid': 3, // TTS语音合成器ID：中年男声
    'portrait': 'images/operators/op_004.png',
    'scripts': {
      'greeting': '喂，接线台已连接。说吧，你想传什么。',
      'askRecipientId': '告诉我收信方的号码。',
      'confirmRecipientId': '号码"{recipientId}"是吧？确认请说"确定"，否则说"修改"。',
      'guideRecordMessage': '开始说吧，我会为你转写并传出去。',
      'transcribing': '正在转写，请稍候。',
      'waiting_effect': 'none', // 等待效果：无（严肃风格）
      'confirmMessage': '内容为"{message}"。是否发送？',
      'send': '消息已发出，处理完毕。',
      'farewell': '结束通话。',
      'clarify': '我没有听清楚，请重复。',
      'timeout': '你没有说话，请再说一遍。',
    },
  },
};

/// 助手配置管理类
/// 负责管理语音助手的操作员配置、关键词匹配和脚本获取
/// 业务流程状态说明：
/// - greeting: 连接建立，开始交互
/// - askRecipientId: 请求收信方ID输入
/// - confirmRecipientId: 确认收信方ID是否正确
/// - guideRecordMessage: 引导用户录制消息内容
/// - transcribing: 语音转写处理中
/// - confirmMessage: 确认消息内容是否准确
/// - send: 执行消息发送
/// - farewell: 结束连接
/// - clarify: 处理未识别的输入
/// - timeout: 处理用户无响应超时
class AssistantConfig {
  static const AssistantConfig _instance = AssistantConfig._internal();
  const AssistantConfig._internal();
  factory AssistantConfig() => _instance;

  /// 获取操作员配置
  Map<String, dynamic>? getOperatorConfig(String operatorId) {
    return operatorConfigs[operatorId];
  }

  /// 获取操作员对象
  VirtualOperator? getOperator(String operatorId) {
    final config = getOperatorConfig(operatorId);
    if (config == null) return null;

    return VirtualOperator(
      id: operatorId,
      name: config['name'] as String? ?? 'Unknown',
      description: config['description'] as String? ?? '',
      themeColor: config['themeColor'] as Color? ?? Colors.blueAccent,
    );
  }

  /// 获取关键词列表
  List<String> getKeywords(String group) {
    return keywordGroups[group] ?? [];
  }

  /// 检查文本是否匹配关键词组
  bool matchesKeyword(String text, String group) {
    final keywords = getKeywords(group);
    return keywords.any(
      (keyword) => text.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  /// 获取所有操作员ID
  List<String> getOperatorIds() {
    return operatorConfigs.keys.toList();
  }

  /// 获取默认操作员
  String get defaultOperator => 'op_system';

  /// 获取操作员脚本
  String getOperatorScript(
    String operatorId,
    String scriptKey, [
    Map<String, String>? params,
  ]) {
    final config = getOperatorConfig(operatorId);
    if (config == null) return '';

    final scripts = config['scripts'] as Map<String, dynamic>?;
    if (scripts == null) return '';

    String script = scripts[scriptKey] ?? '';

    // 替换参数占位符
    if (params != null) {
      params.forEach((key, value) {
        script = script.replaceAll('{$key}', value);
      });
    }

    return script;
  }
}

/// 默认操作员列表（从配置动态生成）
final List<VirtualOperator> defaultOperators = operatorConfigs.entries.map((
  entry,
) {
  final config = entry.value;
  return VirtualOperator(
    id: entry.key,
    name: config['name'] as String,
    description: config['description'] as String,
    themeColor: config['themeColor'] as Color,
  );
}).toList();
