import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          ValueListenableBuilder<AuthStatus>(
            valueListenable: AuthService().authState,
            builder: (context, status, _) {
              if (status == AuthStatus.authenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () => AuthService().logout(),
                );
              }
              return IconButton(
                icon: const Icon(Icons.login),
                tooltip: 'Login',
                onPressed: () => context.push('/login'),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Bipupu!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/speech_test'),
              child: const Text('Test Speech Recognition'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/bluetooth'),
              child: const Text('Bluetooth Message Test'),
            ),
          ],
        ),
      ),
    );
  }
}
