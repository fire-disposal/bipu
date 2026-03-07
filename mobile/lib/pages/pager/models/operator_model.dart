import 'dart:math';
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
  static final Random _random = Random();

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

  /// 接通后询问目标用户 ID 的台词（多个变体）
  final List<String> askTargetVariants;

  /// 发送成功后询问是否继续的台词（多个变体）
  final List<String> askContinueVariants;

  const OperatorDialogues({
    required this.greetingVariants,
    required this.confirmIdVariants,
    required this.verifyVariants,
    required this.requestMessageVariants,
    required this.emojiWarningVariants,
    required this.successMessageVariants,
    required this.userNotFoundVariants,
    this.randomPhrases = const [],
    this.askTargetVariants = const ['请告诉我您要联系的用户 ID'],
    this.askContinueVariants = const ['是否需要继续发送给其他用户？'],
  });

  /// 获取随机问候语
  String getGreeting() {
    return greetingVariants[_random.nextInt(greetingVariants.length)];
  }

  /// 获取随机确认 ID 台词
  String getConfirmId(String targetId) {
    final template =
        confirmIdVariants[_random.nextInt(confirmIdVariants.length)];
    return template.replaceAll('%s', targetId);
  }

  /// 获取随机核实台词
  String getVerify() {
    return verifyVariants[_random.nextInt(verifyVariants.length)];
  }

  /// 获取随机请求消息台词
  String getRequestMessage() {
    return requestMessageVariants[_random.nextInt(
      requestMessageVariants.length,
    )];
  }

  /// 获取随机表情符号提醒
  String getEmojiWarning() {
    return emojiWarningVariants[_random.nextInt(emojiWarningVariants.length)];
  }

  /// 获取随机成功消息台词
  String getSuccessMessage() {
    return successMessageVariants[_random.nextInt(
      successMessageVariants.length,
    )];
  }

  /// 获取随机用户不存在提示
  String getUserNotFound() {
    return userNotFoundVariants[_random.nextInt(userNotFoundVariants.length)];
  }

  /// 获取随机短语
  String getRandomPhrase() => randomPhrases.isNotEmpty
      ? randomPhrases[_random.nextInt(randomPhrases.length)]
      : '';

  /// 获取询问目标 ID 的台词
  String getAskTarget() =>
      askTargetVariants[_random.nextInt(askTargetVariants.length)];

  /// 获取询问是否继续发送的台词
  String getAskContinue() =>
      askContinueVariants[_random.nextInt(askContinueVariants.length)];

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
    askTargetVariants,
    askContinueVariants,
  ];
}

/// 预定义的接线员列表
class OperatorFactory {
  static final List<OperatorPersonality> defaultOperators = [
    // 接线员 1: 专业接线员青年男
    OperatorPersonality(
      id: 'op_001',
      name: '专业接线员青年男',
      description: '专业、亲切的接线员（青年男声）。',
      portraitUrl: 'assets/operators/xiaohong.png',
      initials: 'XH',
      ttsId: 1,
      ttsSpeed: 1.0,
      themeColor: const Color(0xFFE91E63), // Pink
      dialogues: OperatorDialogues(
        greetingVariants: [
          '您好，这里是 Bipupu 接线台。很高兴为您服务。',
          '您好，Bipupu 接线台，请问有什么可以帮您？',
          '您好，这里是 Bipupu，很高兴为您服务。',
        ],
        confirmIdVariants: [
          '好的，我来跟您确认一下，对方的号码是"%s"对吗？您可以告诉我"确定"或者"修改"。',
          '跟您确认一下，对方号码是"%s"，没错吧？请说"确定"或"修改"。',
          '好的，确认一下，对方号码是"%s"。如果正确请告诉我"确定"，需要修改请说"修改"。',
        ],
        verifyVariants: ['好的，请您稍等，我正在记录。', '请稍等，我正在为您记录。', '好的，我正在记录，请您稍等。'],
        requestMessageVariants: [
          '请您先告诉我收信方的号码。',
          '请先告诉我对方的号码是多少。',
          '麻烦您先提供一下收信方的号码。',
          '好的，谢谢。您现在可以在这里录下想要发送的信息，我会帮您传递到对方的 pupu 机上。如果您准备好了，直接对我说信息内容就可以了。',
          '您现在可以录下要发送的信息了，准备好了就直接对我说吧。',
          '好的，接下来请您录下要传达的信息，我会帮您发送过去。',
        ],
        emojiWarningVariants: [
          '抱歉，传呼机无法显示此类符号，请重新输入。',
          '不好意思，这些符号无法显示，请您用文字描述。',
          '抱歉，我们不支持表情符号，请您用文字表达。',
        ],
        successMessageVariants: [
          '好的，我会立刻为您传送信息。',
          '好的，信息马上为您发送。',
          '明白了，我这就为您传送。',
        ],
        userNotFoundVariants: [
          '用户不存在，请检查 ID 后重试。',
          '抱歉，这个 ID 对应的用户不存在，请您确认后再试。',
          '该用户 ID 无效，请您检查后重新输入。',
        ],
        randomPhrases: ['为您服务是我的荣幸。', '感谢您的使用。', '祝您有美好的一天。'],
        askTargetVariants: [
          '请您先告诉我收信方的号码。',
          '请问您要联系的用户 ID 是多少？',
          '麻烦您提供一下对方的号码。',
        ],
        askContinueVariants: [
          '消息已送达，是否需要继续发送给其他用户？',
          '发送成功了，还有其他需要传达的吗？',
          '还需要联系其他人吗？',
        ],
      ),
    ),

    // 接线员 2: 冷漠高效机器人
    OperatorPersonality(
      id: 'op_002',
      name: '冷漠高效机器人',
      description: '冷静、简练的机器人风格接线员。',
      portraitUrl: 'assets/operators/xiaomei.png',
      initials: 'XM',
      ttsId: 2,
      ttsSpeed: 1.0,
      themeColor: const Color(0xFF9C27B0), // Purple
      dialogues: OperatorDialogues(
        greetingVariants: [
          '连接建立。Bipupu 接线系统待命。',
          '系统已启动。Bipupu 接线服务就绪。',
          '连接成功。等待指令。',
        ],
        confirmIdVariants: [
          '请确认收信方 ID。"%s"。选择"确定"或"修改"。',
          '收信方 ID："%s"。确认或修改。',
          'ID 识别为"%s"。请确认。',
        ],
        verifyVariants: ['转写完成', '记录完毕', '处理完成'],
        requestMessageVariants: [
          '收信方 ID 录入。',
          '请提供收信方 ID。',
          '输入目标 ID。',
          '如提供信息，我将执行传输。请在嘟声后说出信息。',
          '信息录入阶段。请开始讲述。',
          '准备接收信息。请讲。',
        ],
        emojiWarningVariants: [
          '错误：不支持非文本字符。',
          '警告：检测到无效符号。请修正。',
          '格式错误：仅接受文本输入。',
        ],
        successMessageVariants: ['传输已执行。', '发送完成。', '任务执行完毕。'],
        userNotFoundVariants: ['错误：目标用户不存在。', '查询失败：无效的 ID。', '数据库中未找到匹配项。'],
        randomPhrases: ['系统运行正常。', '保持理性。', '逻辑是唯一的真理。'],
        askTargetVariants: ['收信方 ID 录入。', '输入目标用户 ID。', '请提供接收方 ID。'],
        askContinueVariants: ['传输完成。是否继续？', '任务完成。是否启动下一轮？', '发送成功。继续？'],
      ),
    ),

    // 接线员 3: 活泼话痨少女
    OperatorPersonality(
      id: 'op_003',
      name: '活泼话痨少女',
      description: '活泼、热情、喜欢唠叨的接线员（少女声）。',
      portraitUrl: 'assets/operators/xiaogang.png',
      initials: 'XG',
      ttsId: 3,
      ttsSpeed: 1.1,
      themeColor: const Color(0xFFFF9800), // Orange
      dialogues: OperatorDialogues(
        greetingVariants: [
          'Hi Hi~ 今天过得好吗？恭喜你来到了本大王的 Bipupu 接线台！',
          '哇哈喽~ 欢迎来到 Bipupu！今天也是元气满满的一天呢！',
          '哟吼~ 你来啦！这里是超~级好用的 Bipupu 接线台哦！',
        ],
        confirmIdVariants: [
          '"%s"，对吧？没问题呢你就说一下"确定！"错了的话你就说"修改"，然后再重新告诉我一次噜。',
          '号码是"%s"没错吧？对的话就说"确定"，不对就说"修改"，超简单的！',
          '让我看看哦……是"%s"对吧？确认一下嘛，说"确定"或者"修改"就好啦~',
        ],
        verifyVariants: ['OK OK，我…记…完…了!', '搞定搞定！记下来啦！', '好——嘞！记录完成！'],
        requestMessageVariants: [
          '让我们来看看是谁马上要因为收到信息而开心啦！啊对对对，就是让你说一下对方的号码。',
          '来吧来吧，我最爱帮人传小纸条了！想好要说什么没？我"嘟——"一声之后你就开始说话嗷。嘟————',
          '快快快，告诉我对方的号码！我已经迫不及待要帮你传话啦！',
          '好耶好耶！现在可以开始录你要说的话了哦，准备好了就直接说，我会认真听的！嘟——',
          '来来来，说点什么吧！不管是告白还是吐槽，我都帮你传达到！嘟——',
        ],
        emojiWarningVariants: [
          '哎呀，这些表情符号我可显示不了呢，麻烦您重新输入好吗~',
          '诶嘿~ 这些符号我看不懂啦，能用文字告诉我吗？',
          '抱歉抱歉，这些表情我没办法显示呢，换个文字表达吧~',
        ],
        successMessageVariants: [
          '完～美！发走啦，现在后悔也来不及啦！',
          '好——嘞！咻的一下已经发出去了哦！',
          '搞定搞定！消息已经飞出去啦~',
        ],
        userNotFoundVariants: [
          '哎呀，找不到这位用户呢，您再检查一下 ID 吧~',
          '诶？好像没有找到这个用户呢，要不要再确认一下？',
          '这个 ID 好像不对呢，再试试看吧！',
        ],
        randomPhrases: ['很高兴认识你~', '感谢你的信任！', '希望我的服务让你满意哦~'],
        askTargetVariants: [
          '让我们来看看是谁马上要因为收到信息而开心啦！啊对对对，就是让你说一下对方的号码。',
          '快告诉我对方的号码嘛，我已经等不及啦！',
          '所以所以，你要联系谁呀？说 ID 说 ID~',
        ],
        askContinueVariants: [
          '太棒了，消息已经发出去啦！还需要发给其他人吗？',
          '好——嘞！搞定！还要继续发吗？我随时待命哦！',
          '完成啦！还有其他要传达的吗？尽管说！',
        ],
      ),
    ),

    // 接线员 4: 黑帮顾问中年男
    OperatorPersonality(
      id: 'op_004',
      name: '黑帮顾问中年男',
      description: '低沉沙哑、稳重威严的中年男声接线员。',
      portraitUrl: 'assets/operators/xiaoyue.png',
      initials: 'XY',
      ttsId: 4,
      ttsSpeed: 0.9,
      themeColor: const Color(0xFF673AB7), // Deep Purple
      dialogues: OperatorDialogues(
        greetingVariants: [
          '……嗯。你来了。很好。现在，让我们把事情办妥。来吧，坐下，慢慢说。',
          '……等你很久了。Bipupu 已经准备好，说吧，什么事。',
          '……来了。很好。这里的规矩你懂，我们直接谈正事。',
        ],
        confirmIdVariants: [
          '"%s"，确定吗？弄错了目标可并不有趣。告诉我，是"确定"，还是"修改"？',
          '号码是"%s"。想清楚了再说，"确定"还是"修改"？',
          '"%s"……这号码你可要想清楚了。一旦弄错，后果自负。"确定"还是"修改"？',
        ],
        verifyVariants: ['……好，我听到你了。', '……明白了。', '……继续。'],
        requestMessageVariants: [
          '对方是谁？别提名字，这是规矩。说 ID。',
          '很好。那么，如果你准备好了，就把信息清楚地、完整地、对我说。说得越清楚，对你越有利。',
          '说吧，你要传达什么。记住，一句话只能有一个意思。',
          '……把你要说的，一字一句地讲清楚。我会处理剩下的。',
          '时间宝贵。直接说重点，别绕弯子。',
        ],
        emojiWarningVariants: [
          '这些符号超出了我的理解范围，请用文字表达。',
          '……这些花哨的东西，不适合这里。用文字。',
          '我不懂这些符号。重新说，用清楚的文字。',
        ],
        successMessageVariants: [
          '很好，那这件事就算定下来了。我会按规矩传递消息的。',
          '……明白了。消息会送到。',
          '事情办妥了。你可以走了。',
        ],
        userNotFoundVariants: [
          '这个用户似乎不存在……在茫茫人海中，没有找到这位用户。',
          '……这个 ID，查无此人。你确定没记错？',
          '找不到这个人。再想想，是不是哪里弄错了。',
        ],
        randomPhrases: ['一切皆有可能。', '感谢你的信任。', '再见，朋友。'],
        askTargetVariants: [
          '对方是谁？别提名字，这是规矩。说 ID。',
          '说吧，你要找谁。ID。',
          '……告诉我，你要联系的人是谁。用 ID 说话。',
        ],
        askContinueVariants: [
          '消息已传达至彼岸。是否还有其他需要传递的心意？',
          '……事情还没完？说吧，还有什么。',
          '已经处理好了。还有下一单生意吗？',
        ],
      ),
    ),
    // 接线员 5: 机械型 - 零号
    OperatorPersonality(
      id: 'op_005',
      name: '零号',
      description: '绝对理性的 AI 接线员',
      portraitUrl: 'assets/operators/zero.png',
      initials: 'Z0',
      ttsId: 0, // 假设 0 是标准机器人音色
      ttsSpeed: 1.2, // 语速稍快
      themeColor: const Color(0xFF607D8B), // Blue Grey
      dialogues: OperatorDialogues(
        greetingVariants: ['系统已连接。我是接线员零号。', '初始化完成。零号为您服务。', '指令接收中。请讲。'],
        confirmIdVariants: ['目标 ID 识别为 %s。确认执行？', '正在锁定用户 %s。', '连接 %s 中。'],
        verifyVariants: ['正在检索数据库...', '数据校验中...', '同步用户信息...'],
        requestMessageVariants: ['请输入传输内容。', '等待信息输入。', '开始记录消息。'],
        emojiWarningVariants: [
          '错误：不支持非文本字符。',
          '警告：检测到无效符号。请修正。',
          '格式错误。仅接受文本。',
        ],
        successMessageVariants: ['传输完成。', '数据包已发送。', '任务执行完毕。'],
        userNotFoundVariants: ['错误：目标用户不存在。', '查询失败：无效的 ID。', '数据库中未找到匹配项。'],
        randomPhrases: ['逻辑是唯一的真理。', '系统运行正常。', '保持理性。'],
        askTargetVariants: ['输入目标用户 ID。', '请提供接收方 ID。', '等待 ID 输入。'],
        askContinueVariants: [
          '传输完成。是否继续执行新的发送任务？',
          '任务完成。是否启动下一轮传输？',
          '发送成功。继续？',
        ],
      ),
    ),
  ];

  /// 获取随机操作员
  static OperatorPersonality getRandomOperator() {
    final rnd = Random();
    return defaultOperators[rnd.nextInt(defaultOperators.length)];
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
