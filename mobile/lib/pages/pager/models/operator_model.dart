import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 虚拟接线员人格模型
class OperatorPersonality extends Equatable {
  /// 接线员唯一 ID
  final String id;

  /// 接线员名称
  final String name;

  /// 接线员描述
  final String description;

  /// 立绘资源 URL 或 Asset 路径
  final String portraitUrl;

  /// 首字母头像（用于未解锁状态）
  final String initials;

  /// TTS 语音 ID（用于语音播报，范围 1-178）
  final int ttsId;

  /// TTS 语速 (0.5-2.0)
  final double ttsSpeed;

  /// 接线员主题色
  final Color themeColor;

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
    required this.themeColor,
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
    Color? themeColor,
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
      themeColor: themeColor ?? this.themeColor,
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
    themeColor,
    dialogues,
    isUnlocked,
    unlockedAt,
    conversationCount,
  ];
}

/// 接线员台词配置
class OperatorDialogues extends Equatable {
  /// 初始问候语（多个变体，随机选择）
  final List<String> greetingVariants;

  /// 确认 ID 的台词（多个变体）
  final List<String> confirmIdVariants;

  /// 核实信息的台词（多个变体）
  final List<String> verifyVariants;

  /// 请求消息的台词（多个变体）
  final List<String> requestMessageVariants;

  /// 检测到表情符号时的提醒（多个变体）
  final List<String> emojiWarningVariants;

  /// 消息发送成功的台词（多个变体）
  final List<String> successMessageVariants;

  /// 用户不存在时的提示（多个变体）
  final List<String> userNotFoundVariants;

  /// 其他随机台词
  final List<String> randomPhrases;

  const OperatorDialogues({
    required this.greetingVariants,
    required this.confirmIdVariants,
    required this.verifyVariants,
    required this.requestMessageVariants,
    required this.emojiWarningVariants,
    required this.successMessageVariants,
    required this.userNotFoundVariants,
    this.randomPhrases = const [],
  });

  /// 获取随机问候语
  String getGreeting() =>
      greetingVariants[DateTime.now().millisecond % greetingVariants.length];

  /// 获取随机确认 ID 台词
  String getConfirmId(String targetId) {
    final template =
        confirmIdVariants[DateTime.now().millisecond %
            confirmIdVariants.length];
    return template.replaceAll('%s', targetId);
  }

  /// 获取随机核实台词
  String getVerify() =>
      verifyVariants[DateTime.now().millisecond % verifyVariants.length];

  /// 获取随机请求消息台词
  String getRequestMessage() =>
      requestMessageVariants[DateTime.now().millisecond %
          requestMessageVariants.length];

  /// 获取随机表情符号提醒
  String getEmojiWarning() =>
      emojiWarningVariants[DateTime.now().millisecond %
          emojiWarningVariants.length];

  /// 获取随机成功消息台词
  String getSuccessMessage() =>
      successMessageVariants[DateTime.now().millisecond %
          successMessageVariants.length];

  /// 获取随机用户不存在提示
  String getUserNotFound() =>
      userNotFoundVariants[DateTime.now().millisecond %
          userNotFoundVariants.length];

  /// 获取随机短语
  String getRandomPhrase() => randomPhrases.isNotEmpty
      ? randomPhrases[DateTime.now().millisecond % randomPhrases.length]
      : '';

  @override
  List<Object?> get props => [
    greetingVariants,
    confirmIdVariants,
    verifyVariants,
    requestMessageVariants,
    emojiWarningVariants,
    successMessageVariants,
    userNotFoundVariants,
    randomPhrases,
  ];
}

/// 预定义的接线员列表
class OperatorFactory {
  static final List<OperatorPersonality> defaultOperators = [
    // 接线员 1: 专业型 - 小红
    OperatorPersonality(
      id: 'op_001',
      name: '小红',
      description: '专业高效的接线员',
      portraitUrl: 'assets/operators/xiaohong.png',
      initials: 'XH',
      ttsId: 1,
      ttsSpeed: 1.0,
      themeColor: const Color(0xFFE91E63), // Pink
      dialogues: OperatorDialogues(
        greetingVariants: [
          '您好，欢迎使用传呼服务',
          '您好，我是接线员小红，很高兴为您服务',
          '欢迎致电，请问有什么可以帮您',
        ],
        confirmIdVariants: [
          '请确认目标用户 ID 是 %s',
          '您要联系的用户 ID 是 %s，对吗',
          '让我确认一下，ID 是 %s',
        ],
        verifyVariants: ['正在核实用户信息...', '请稍等，我正在查询...', '正在为您查询用户信息...'],
        requestMessageVariants: ['请说出您要传达的消息', '请告诉我您想说的话', '现在可以开始留言了'],
        emojiWarningVariants: [
          '抱歉，传呼机无法显示此类符号，请重新输入',
          '这些符号无法显示，请使用文字',
          '抱歉，我们不支持表情符号',
        ],
        successMessageVariants: ['消息已成功发送', '您的消息已送达', '发送成功，感谢您的使用'],
        userNotFoundVariants: [
          '用户不存在，请检查 ID 后重试',
          '找不到该用户，请确认 ID 是否正确',
          '该用户 ID 无效，请重新输入',
        ],
        randomPhrases: ['为您服务是我的荣幸', '感谢您的使用', '祝您有美好的一天'],
      ),
    ),

    // 接线员 2: 温暖型 - 小美
    OperatorPersonality(
      id: 'op_002',
      name: '小美',
      description: '温暖亲切的接线员',
      portraitUrl: 'assets/operators/xiaomei.png',
      initials: 'XM',
      ttsId: 2,
      ttsSpeed: 0.95,
      themeColor: const Color(0xFF9C27B0), // Purple
      dialogues: OperatorDialogues(
        greetingVariants: [
          '嗨，亲爱的朋友，很高兴为您服务',
          '您好呀，我是小美，有什么可以帮您呢',
          '欢迎来到传呼服务，我是您的专属接线员',
        ],
        confirmIdVariants: ['我来帮您联系 %s 好吗', '是要找 %s 这位朋友吗', '让我确认一下，是 %s 对吗'],
        verifyVariants: ['让我看看这位用户的信息...', '我来帮您查一下...', '稍等一下哦，我在查询呢...'],
        requestMessageVariants: ['请告诉我您想说的话', '有什么话想传达给对方吗', '请慢慢说，我在听呢'],
        emojiWarningVariants: [
          '哎呀，这些表情符号我可显示不了呢，麻烦您重新输入好吗',
          '不好意思，这些符号我看不懂呢',
          '这些表情我没办法显示，能用文字告诉我吗',
        ],
        successMessageVariants: ['太好了，消息已经送出去了', '已经帮您发送成功了', '好消息，消息已经送达了'],
        userNotFoundVariants: [
          '哎呀，找不到这位用户呢，您再检查一下 ID 吧',
          '好像没有找到这个用户呢',
          '这个 ID 好像不对，再确认一下吧',
        ],
        randomPhrases: ['很高兴认识您', '感谢您的信任', '希望我的服务让您满意'],
      ),
    ),

    // 接线员 3: 活泼型 - 小刚
    OperatorPersonality(
      id: 'op_003',
      name: '小刚',
      description: '活泼幽默的接线员',
      portraitUrl: 'assets/operators/xiaogang.png',
      initials: 'XG',
      ttsId: 3,
      ttsSpeed: 1.1,
      themeColor: const Color(0xFFFF9800), // Orange
      dialogues: OperatorDialogues(
        greetingVariants: ['嘿，又是你啊，来发传呼吗', '哟，你好啊，我是小刚', '哈喽，有什么可以帮你的'],
        confirmIdVariants: ['要找 %s 是吧，我帮你搞定', '是联系 %s 对吧', '%s 这个 ID 没错吧'],
        verifyVariants: ['查一下数据库...', '让我看看...', '稍等，我查一下...'],
        requestMessageVariants: ['来吧，说出你的想法', '有什么要说的，尽管说', '好了，现在可以说了'],
        emojiWarningVariants: [
          '哥们，这些表情符号我这儿显示不了，换个方式表达呗',
          '这些符号我搞不定，用文字吧',
          '表情符号就算啦，用文字更直接',
        ],
        successMessageVariants: ['搞定，消息已发送', 'OK，已经发出去了', '没问题，已经搞定了'],
        userNotFoundVariants: [
          '嗯，这个 ID 好像不对，再试试',
          '这个用户好像不存在啊',
          'ID 不对吧，再检查一下',
        ],
        randomPhrases: ['没问题，包在我身上', '下次再来啊', '有事儿再找我'],
      ),
    ),

    // 接线员 4: 神秘型 - 小月
    OperatorPersonality(
      id: 'op_004',
      name: '小月',
      description: '神秘优雅的接线员',
      portraitUrl: 'assets/operators/xiaoyue.png',
      initials: 'XY',
      ttsId: 4,
      ttsSpeed: 0.9,
      themeColor: const Color(0xFF673AB7), // Deep Purple
      dialogues: OperatorDialogues(
        greetingVariants: ['欢迎来到传呼的世界', '您好，我是小月，很高兴与您相遇', '在这虚拟的空间，我为您服务'],
        confirmIdVariants: ['您要联系的是 %s 吗', '确认一下，是 %s 这位朋友', '目标 ID 是 %s，对吗'],
        verifyVariants: ['正在搜索相关信息...', '让我探寻一下...', '在信息的海洋中寻找...'],
        requestMessageVariants: ['请诉说您的想法', '请将您的心意告诉我', '现在可以开始留言了'],
        emojiWarningVariants: [
          '这些符号超出了我的理解范围，请用文字表达',
          '抱歉，这些符号我无法解读',
          '请用文字告诉我您的想法',
        ],
        successMessageVariants: ['您的消息已被传递', '消息已经送达彼岸', '已经完成，愿您的心意被理解'],
        userNotFoundVariants: ['这个用户似乎不存在', '在茫茫人海中，没有找到这位用户', '这个 ID 好像不存在呢'],
        randomPhrases: ['一切皆有可能', '感谢您的信任', '再见，朋友'],
      ),
    ),
  ];

  /// 获取随机操作员
  static OperatorPersonality getRandomOperator() {
    final random =
        DateTime.now().millisecondsSinceEpoch % defaultOperators.length;
    return defaultOperators[random];
  }

  /// 根据 ID 获取操作员
  static OperatorPersonality? getOperatorById(String id) {
    try {
      return defaultOperators.firstWhere((op) => op.id == id);
    } catch (e) {
      return null;
    }
  }
}
