import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ShadApp(
        title: 'Bipupu - 宇宙传讯',
        debugShowCheckedModeBanner: false,
        home: MainApp(),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
