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

/// 助手配置类
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

  /// 默认操作员列表
  List<VirtualOperator> get defaultOperators => [
    VirtualOperator(
      id: 'op_system',
      name: '系统',
      description: '系统默认操作员',
      themeColor: Colors.grey,
    ),
    VirtualOperator(
      id: 'op_001',
      name: '专业接线员青年男',
      description: '专业、亲切的接线员（青年男声）',
      themeColor: Colors.teal,
    ),
    VirtualOperator(
      id: 'op_002',
      name: '温柔接线员女声',
      description: '温柔、耐心的接线员（女声）',
      themeColor: Colors.pink,
    ),
  ];
}

/// 关键词组定义
const Map<String, List<String>> keywordGroups = {
  'greeting': ['你好', '您好', 'hello', 'hi', '嗨', '早上好', '下午好', '晚上好'],
  'farewell': ['再见', '拜拜', 'goodbye', 'bye', '下次见', '结束'],
  'confirm': ['是的', '对的', '正确', '确认', 'ok', '好的', '可以', '行'],
  'modify': ['修改', '更改', '调整', '改一下', '重新', '不对'],
  'cancel': ['取消', '不要了', '算了', '停止', '退出'],
  'send': ['发送', '发出', '发出去', '传送', '传递'],
  'start': ['开始', '启动', '开启', '出发'],
  'stop': ['停止', '暂停', '结束', '终止'],
  'rerecord': ['重录', '重新录', '再录一次', '重新说'],
  'recipient': ['收信人', '接收方', '对方', '给谁', '发给谁'],
  'message': ['消息', '信息', '内容', '说什么', '写什么'],
  'time': ['时间', '几点', '什么时候', '何时'],
  'weather': ['天气', '气温', '温度', '下雨', '晴天'],
  'news': ['新闻', '消息', '资讯', '头条'],
  'help': ['帮助', '帮忙', '怎么用', '如何使用', '说明'],
};

/// 操作员配置
const Map<String, Map<String, dynamic>> operatorConfigs = {
  'op_system': {
    'name': '系统',
    'description': '系统默认操作员',
    'themeColor': Colors.grey,
    'scripts': {
      'greeting': '您好，我是Bipupu语音助手。请问您需要什么帮助？',
      'askRecipientId': '请问您要发送给哪位用户？请提供对方的Bipupu ID。',
      'confirmRecipientId': '您要发送给用户{recipientId}，对吗？',
      'guideRecordMessage': '好的，现在请说出您要发送的消息内容。',
      'recording': '正在录音，请说话...',
      'transcribing': '正在转写您的语音...',
      'confirmMessage': '您说的是：{message}，对吗？',
      'sending': '正在发送消息...',
      'sent': '消息已成功发送！',
      'farewell': '感谢使用Bipupu语音助手，再见！',
      'error': '抱歉，出现了错误。请稍后再试。',
      'timeout': '等待超时，请重新开始。',
      'clarify': '抱歉，我没有听清楚。请您再说一遍。',
    },
  },
  'op_001': {
    'name': '专业接线员青年男',
    'description': '专业、亲切的接线员（青年男声）',
    'themeColor': Colors.teal,
    'scripts': {
      'greeting': '您好，我是Bipupu专业接线员。很高兴为您服务！',
      'askRecipientId': '请问您要联系哪位用户？请告诉我对方的Bipupu ID。',
      'confirmRecipientId': '确认一下，您要联系用户{recipientId}，对吗？',
      'guideRecordMessage': '好的，现在请您说出要发送的消息内容。',
      'recording': '正在录音，请开始说话...',
      'transcribing': '正在处理您的语音，请稍候...',
      'confirmMessage': '您说的是：{message}，请确认是否正确？',
      'sending': '正在为您发送消息...',
      'sent': '消息已成功送达！',
      'farewell': '感谢您的使用，祝您有美好的一天！',
      'error': '抱歉，系统出现了一点问题。请您稍后再试。',
      'timeout': '操作超时，请您重新开始。',
      'clarify': '抱歉，刚才没有听清楚。请您再重复一遍。',
    },
  },
  'op_002': {
    'name': '温柔接线员女声',
    'description': '温柔、耐心的接线员（女声）',
    'themeColor': Colors.pink,
    'scripts': {
      'greeting': '您好呀，我是Bipupu语音助手。有什么可以帮您的吗？',
      'askRecipientId': '请问您想发送消息给哪位朋友呢？请告诉我对方的Bipupu ID。',
      'confirmRecipientId': '您是要发送给{recipientId}这位用户，对吗？',
      'guideRecordMessage': '好的，现在请告诉我您想说的话吧。',
      'recording': '我在听，请慢慢说...',
      'transcribing': '正在理解您说的话，请稍等一下哦...',
      'confirmMessage': '您说的是：{message}，是这样吗？',
      'sending': '正在为您发送消息，请稍候...',
      'sent': '太好了，消息已经发送成功啦！',
      'farewell': '感谢您的使用，期待下次为您服务！',
      'error': '哎呀，好像出了点小问题。请您稍后再试试看。',
      'timeout': '等待时间有点长了，我们重新开始好吗？',
      'clarify': '不好意思，刚才没听清楚呢。请您再说一次好吗？',
    },
  },
};
