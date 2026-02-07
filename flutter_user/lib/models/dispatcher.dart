import 'package:flutter/material.dart';

class Dispatcher {
  final String id;
  final String name;
  final String avatar;
  final String description;
  final bool isLocked;
  final Color themeColor;

  const Dispatcher({
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
    this.isLocked = false,
    this.themeColor = Colors.blue,
  });
}

final List<Dispatcher> mockDispatchers = [
  const Dispatcher(
    id: '1',
    name: '系统调度�?,
    avatar: '🤖',
    description: '默认系统调度，精准传达每一条指令�?,
    isLocked: false,
    themeColor: Colors.blue,
  ),
  const Dispatcher(
    id: '2',
    name: '灵梦',
    avatar: '⛩️',
    description: '博丽神社的巫女，随缘分传讯�?,
    isLocked: true,
    themeColor: Colors.red,
  ),
  const Dispatcher(
    id: '3',
    name: '魔理�?,
    avatar: '🧙‍♀�?,
    description: '普通的魔法使，传讯带有一点魔法气息�?,
    isLocked: true,
    themeColor: Colors.yellow,
  ),
  const Dispatcher(
    id: '4',
    name: '十六�?,
    avatar: '🔪',
    description: '完美而潇洒的从者，瞬间即达�?,
    isLocked: true,
    themeColor: Colors.blueGrey,
  ),
];
