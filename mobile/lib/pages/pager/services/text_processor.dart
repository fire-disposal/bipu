import 'package:equatable/equatable.dart';

/// 文本处理结果
class TextProcessingResult extends Equatable {
  /// 是否包含表情符号
  final bool hasEmoji;

  /// 检测到的表情符号列表
  final List<String> detectedEmojis;

  /// 清理后的文本
  final String cleanedText;

  /// 是否为有效文本
  final bool isValid;

  /// 验证消息
  final String? validationMessage;

  const TextProcessingResult({
    required this.hasEmoji,
    required this.detectedEmojis,
    required this.cleanedText,
    required this.isValid,
    this.validationMessage,
  });

  @override
  List<Object?> get props => [
    hasEmoji,
    detectedEmojis,
    cleanedText,
    isValid,
    validationMessage,
  ];
}

/// 文本处理服务
/// 负责检测、验证和清理文本内容
class TextProcessor {
  // 表情符号范围（Unicode）
  static const int _emojiRangeStart1 = 0x1F300; // 杂项符号和象形文字
  static const int _emojiRangeEnd1 = 0x1F9FF;

  static const int _emojiRangeStart2 = 0x1F900; // 补充象形文字
  static const int _emojiRangeEnd2 = 0x1F9FF;

  static const int _emojiRangeStart3 = 0x2600; // 杂项符号
  static const int _emojiRangeEnd3 = 0x27BF;

  static const int _emojiRangeStart4 = 0x1F000; // 象形文字块
  static const int _emojiRangeEnd4 = 0x1F02F;

  // 特殊表情符号范围
  static const int _emojiRangeStart5 = 0x1F600; // 表情范围
  static const int _emojiRangeEnd5 = 0x1F64F;

  // 修饰符范围
  static const int _modifierStart = 0x1F300;
  static const int _modifierEnd = 0x1F9FF;

  /// 最大消息长度
  static const int maxMessageLength = 160;

  /// 最小消息长度
  static const int minMessageLength = 1;

  /// 处理文本：检测表情符号并进行验证
  static TextProcessingResult processText(String text) {
    if (text.isEmpty) {
      return TextProcessingResult(
        hasEmoji: false,
        detectedEmojis: [],
        cleanedText: text,
        isValid: false,
        validationMessage: '文本不能为空',
      );
    }

    // 检测表情符号
    final emojis = _detectEmojis(text);
    final hasEmoji = emojis.isNotEmpty;

    // 清理文本（移除表情符号）
    final cleanedText = _removeEmojis(text);

    // 验证清理后的文本
    final isValid = _validateText(cleanedText);
    String? validationMessage;

    if (hasEmoji) {
      validationMessage = '检测到${emojis.length}个表情符号，已自动移除';
    } else if (!isValid) {
      validationMessage = _getValidationMessage(cleanedText);
    }

    return TextProcessingResult(
      hasEmoji: hasEmoji,
      detectedEmojis: emojis,
      cleanedText: cleanedText,
      isValid: isValid,
      validationMessage: validationMessage,
    );
  }

  /// 检测文本中的表情符号
  static List<String> _detectEmojis(String text) {
    final emojis = <String>{};

    for (int i = 0; i < text.length; i++) {
      final codePoint = _getCodePoint(text, i);

      // 检查各个表情符号范围
      if (_isInEmojiRange(codePoint)) {
        // 提取表情符号（可能是多个代码单元）
        final emoji = _extractEmoji(text, i);
        if (emoji.isNotEmpty) {
          emojis.add(emoji);
          // 跳过多个代码单元的表情符号
          i += emoji.length - 1;
        }
      }
    }

    return emojis.toList();
  }

  /// 从文本中移除表情符号
  static String _removeEmojis(String text) {
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final codePoint = _getCodePoint(text, i);

      if (!_isInEmojiRange(codePoint)) {
        buffer.write(text[i]);
      } else {
        // 跳过表情符号的所有代码单元
        final emoji = _extractEmoji(text, i);
        i += emoji.length - 1;
      }
    }

    return buffer.toString();
  }

  /// 提取单个表情符号
  static String _extractEmoji(String text, int startIndex) {
    if (startIndex >= text.length) return '';

    final codePoint = _getCodePoint(text, startIndex);

    // 检查是否为代理对（表情符号通常是代理对）
    if (startIndex + 1 < text.length) {
      final nextCodePoint = _getCodePoint(text, startIndex + 1);
      final isHighSurrogate = codePoint >= 0xD800 && codePoint <= 0xDBFF;
      final isLowSurrogate = nextCodePoint >= 0xDC00 && nextCodePoint <= 0xDFFF;

      if (isHighSurrogate && isLowSurrogate) {
        return text.substring(startIndex, startIndex + 2);
      }
    }

    return text[startIndex];
  }

  /// 获取代码点
  static int _getCodePoint(String text, int index) {
    if (index >= text.length) return 0;
    return text.codeUnitAt(index);
  }

  /// 检查代码点是否在表情符号范围内
  static bool _isInEmojiRange(int codePoint) {
    return (codePoint >= _emojiRangeStart1 && codePoint <= _emojiRangeEnd1) ||
        (codePoint >= _emojiRangeStart2 && codePoint <= _emojiRangeEnd2) ||
        (codePoint >= _emojiRangeStart3 && codePoint <= _emojiRangeEnd3) ||
        (codePoint >= _emojiRangeStart4 && codePoint <= _emojiRangeEnd4) ||
        (codePoint >= _emojiRangeStart5 && codePoint <= _emojiRangeEnd5) ||
        (codePoint >= _modifierStart && codePoint <= _modifierEnd) ||
        _isSpecialEmoji(codePoint);
  }

  /// 检查特殊表情符号
  static bool _isSpecialEmoji(int codePoint) {
    // 组合字符和修饰符
    return (codePoint >= 0x200D && codePoint <= 0x200F) || // 零宽度连接符
        (codePoint >= 0xFE00 && codePoint <= 0xFE0F) || // 变体选择器
        codePoint == 0x20E3 || // 组合数字标记
        codePoint == 0x1F1E6; // 区域指示符开始
  }

  /// 验证文本
  static bool _validateText(String text) {
    if (text.isEmpty || text.length > maxMessageLength) {
      return false;
    }

    // 检查是否全为空格或特殊字符
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    return true;
  }

  /// 获取验证消息
  static String _getValidationMessage(String text) {
    if (text.isEmpty) {
      return '文本不能为空';
    }

    if (text.length > maxMessageLength) {
      return '文本长度不能超过 $maxMessageLength 个字符';
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '文本不能只包含空格';
    }

    return '文本有效';
  }

  /// 检查文本是否包含表情符号
  static bool containsEmoji(String text) {
    return _detectEmojis(text).isNotEmpty;
  }

  /// 获取文本长度（不包括表情符号）
  static int getTextLength(String text) {
    return _removeEmojis(text).length;
  }

  /// 清理文本（移除首尾空格和多余表情符号）
  static String sanitizeText(String text) {
    final cleaned = _removeEmojis(text);
    return cleaned.trim();
  }

  /// 生成用于TTS播报的文字
  /// 去掉特殊字符和表情符号，保留可读内容
  static String generateSpeakableText(String text) {
    final cleaned = sanitizeText(text);

    // 移除特殊符号但保留标点
    return cleaned.replaceAll(RegExp(r'[^\u4e00-\u9fa5a-zA-Z0-9\s，。！？；：]'), '');
  }

  /// 格式化消息显示
  /// 在过长的消息中添加省略号
  static String formatForDisplay(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// 统计文本统计信息
  static TextStats analyzeText(String text) {
    final chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(text).length;
    final englishChars = RegExp(r'[a-zA-Z]').allMatches(text).length;
    final digits = RegExp(r'[0-9]').allMatches(text).length;
    final spaces = RegExp(r'\s').allMatches(text).length;
    final emojis = _detectEmojis(text).length;

    return TextStats(
      totalLength: text.length,
      chineseCharCount: chineseChars,
      englishCharCount: englishChars,
      digitCount: digits,
      spaceCount: spaces,
      emojiCount: emojis,
    );
  }
}

/// 文本统计信息
class TextStats extends Equatable {
  final int totalLength;
  final int chineseCharCount;
  final int englishCharCount;
  final int digitCount;
  final int spaceCount;
  final int emojiCount;

  const TextStats({
    required this.totalLength,
    required this.chineseCharCount,
    required this.englishCharCount,
    required this.digitCount,
    required this.spaceCount,
    required this.emojiCount,
  });

  /// 获取可显示的文本长度（不包括表情符号和空格）
  int get displayLength => totalLength - emojiCount - spaceCount;

  @override
  List<Object> get props => [
    totalLength,
    chineseCharCount,
    englishCharCount,
    digitCount,
    spaceCount,
    emojiCount,
  ];
}
