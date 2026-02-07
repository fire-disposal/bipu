import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // 显示调用栈的层数
    errorMethodCount: 8, // 错误时显示的调用栈层数
    lineLength: 120, // 行长度
    colors: true, // 启用颜色
    printEmojis: true, // 打印表情符号
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 打印时间
  ),
);
