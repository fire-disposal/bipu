import 'package:equatable/equatable.dart';

/// 虚拟接线员人格模型
class OperatorPersonality extends Equatable {
  /// 接线员唯一ID
  final String id;

  /// 接线员名称
  final String name;

  /// 接线员描述
  final String description;

  /// 立绘资源URL或Asset路径
  final String portraitUrl;

  /// 首字母头像（用于未解锁状态）
  final String initials;

  /// TTS语音ID（用于语音播报）
  final int ttsId;

  /// TTS语速 (0.5-2.0)
  final double ttsSpeed;

  /// 接线员台词配置
  final OperatorDialogues dialogues;

  /// 是否已解锁
  final bool isUnlocked;

  /// 解锁时间戳
  final DateTime? unlockedAt;

  /// 完成对话次数
  final int conversationCount;

  const OperatorPersonality({
    required this.id,
    required this.name,
    required this.description,
    required this.portraitUrl,
    required this.initials,
    required this.ttsId,
    this.ttsSpeed = 1.0,
    required this.dialogues,
    this.isUnlocked = false,
    this.unlockedAt,
    this.conversationCount = 0,
  });

  /// 复制并修改
  OperatorPersonality copyWith({
    String? id,
    String? name,
    String? description,
    String? portraitUrl,
    String? initials,
    int? ttsId,
    double? ttsSpeed,
    OperatorDialogues? dialogues,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? conversationCount,
  }) {
    return OperatorPersonality(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      portraitUrl: portraitUrl ?? this.portraitUrl,
      initials: initials ?? this.initials,
      ttsId: ttsId ?? this.ttsId,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      dialogues: dialogues ?? this.dialogues,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      conversationCount: conversationCount ?? this.conversationCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    portraitUrl,
    initials,
    ttsId,
    ttsSpeed,
    dialogues,
    isUnlocked,
    unlockedAt,
    conversationCount,
  ];
}

/// 接线员台词配置
class OperatorDialogues extends Equatable {
  /// 初始问候语
  final String greeting;

  /// 确认ID的台词
  final String confirmId;

  /// 核实信息的台词
  final String verify;

  /// 请求消息的台词
  final String requestMessage;

  /// 检测到表情符号时的提醒
  final String emojiWarning;

  /// 消息发送成功的台词
  final String successMessage;

  /// 用户不存在时的提示
  final String userNotFound;

  /// 其他随机台词
  final List<String> randomPhrases;

  const OperatorDialogues({
    required this.greeting,
    required this.confirmId,
    required this.verify,
    required this.requestMessage,
    required this.emojiWarning,
    required this.successMessage,
    required this.userNotFound,
    this.randomPhrases = const [],
  });

  @override
  List<Object?> get props => [
    greeting,
    confirmId,
    verify,
    requestMessage,
    emojiWarning,
    successMessage,
    userNotFound,
    randomPhrases,
  ];
}

/// 预定义的接线员列表
class OperatorFactory {
  static final List<OperatorPersonality> defaultOperators = [
    // 接线员1: 专业型
    OperatorPersonality(
      id: 'op_001',
      name: '小红',
      description: '专业高效的接线员',
      portraitUrl: 'assets/operators/xiaohong.png',
      initials: 'XH',
      ttsId: 0,
      ttsSpeed: 1.0,
      dialogues: OperatorDialogues(
        greeting: '您好，欢迎使用传呼服务',
        confirmId: '请确认目标用户ID是 %s',
        verify: '正在核实用户信息...',
        requestMessage: '请说出您要传达的消息',
        emojiWarning: '抱歉，传呼机无法显示此类符号，请重新输入',
        successMessage: '消息已成功发送',
        userNotFound: '用户不存在，请检查ID后重试',
        randomPhrases: ['为您服务是我的荣幸', '感谢您的使用', '祝您有美好的一天'],
      ),
    ),

    // 接线员2: 温暖型
    OperatorPersonality(
      id: 'op_002',
      name: '小美',
      description: '温暖亲切的接线员',
      portraitUrl: 'assets/operators/xiaomei.png',
      initials: 'XM',
      ttsId: 1,
      ttsSpeed: 0.95,
      dialogues: OperatorDialogues(
        greeting: '嗨，亲爱的朋友，很高兴为您服务',
        confirmId: '我来帮您联系 %s 好吗',
        verify: '让我看看这位用户的信息...',
        requestMessage: '请告诉我您想说的话',
        emojiWarning: '哎呀，这些表情符号我可显示不了呢，麻烦您重新输入好吗',
        successMessage: '太好了，消息已经送出去了',
        userNotFound: '哎呀，找不到这位用户呢，您再检查一下ID吧',
        randomPhrases: ['很高兴认识您', '感谢您的信任', '希望我的服务让您满意'],
      ),
    ),

    // 接线员3: 活泼型
    OperatorPersonality(
      id: 'op_003',
      name: '小刚',
      description: '活泼幽默的接线员',
      portraitUrl: 'assets/operators/xiaogang.png',
      initials: 'XG',
      ttsId: 2,
      ttsSpeed: 1.1,
      dialogues: OperatorDialogues(
        greeting: '嘿，又是你啊，来发传呼吗',
        confirmId: '要找 %s 是吧，我帮你搞定',
        verify: '查一下数据库...',
        requestMessage: '来吧，说出你的想法',
        emojiWarning: '哥们，这些表情符号我这儿显示不了，换个方式表达呗',
        successMessage: '搞定，消息已发送',
        userNotFound: '嗯，这个ID好像不对，再试试',
        randomPhrases: ['没问题，包在我身上', '下次再来啊', '有事儿再找我'],
      ),
    ),

    // 接线员4: 神秘型
    OperatorPersonality(
      id: 'op_004',
      name: '小月',
      description: '神秘优雅的接线员',
      portraitUrl: 'assets/operators/xiaoyue.png',
      initials: 'XY',
      ttsId: 3,
      ttsSpeed: 0.9,
      dialogues: OperatorDialogues(
        greeting: '欢迎来到传呼的世界',
        confirmId: '您要联系的是 %s 吗',
        verify: '正在搜索相关信息...',
        requestMessage: '请诉说您的想法',
        emojiWarning: '这些符号超出了我的理解范围，请用文字表达',
        successMessage: '您的消息已被传递',
        userNotFound: '这个用户似乎不存在',
        randomPhrases: ['一切皆有可能', '感谢您的信任', '再见，朋友'],
      ),
    ),
  ];

  /// 获取随机操作员
  static OperatorPersonality getRandomOperator() {
    final random = DateTime.now().microsecond % defaultOperators.length;
    return defaultOperators[random];
  }

  /// 根据ID获取操作员
  static OperatorPersonality? getOperatorById(String id) {
    try {
      return defaultOperators.firstWhere((op) => op.id == id);
    } catch (e) {
      return null;
    }
  }
}
