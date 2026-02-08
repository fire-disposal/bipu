import 'package:logger/logger.dart';

class ColoredSimplePrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level];
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = '$emoji ${event.level.name}: ${event.message}';
    return [color!(message)];
  }
}

final logger = Logger(printer: ColoredSimplePrinter());
