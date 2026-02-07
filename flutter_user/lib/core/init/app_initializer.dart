import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _startInit();
  }

  void _startInit() {
    _initFuture = AuthService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('初始化失败，请重试'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _startInit();
                        });
                      },
                      child: const Text('重试'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // 允许以游客身份继续
                        AuthService().loginAsGuest();
                      },
                      child: const Text('以游客身份继续'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 初始化成功，展示应用主体（router 等）
        return widget.child;
      },
    );
  }
}
