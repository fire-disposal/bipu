import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/toast_service.dart';
import '../../core/network/network.dart';
import '../../core/network/api_exception.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ToastService().showWarning('Please enter username and password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().login(username, password);
      // Navigate to home page after successful login
      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      // 认证异常：用户名或密码错误、Token 过期等
      if (mounted) {
        ToastService().showError('Authentication failed: ${e.message}');
      }
    } on ValidationException catch (e) {
      // 验证异常：输入格式错误等
      String errorMessage = 'Validation failed';
      if (e.errors != null && e.errors!.isNotEmpty) {
        errorMessage = e.errors!.entries
            .map((entry) => entry.value.toString())
            .join(', ');
      } else {
        errorMessage = e.message;
      }
      if (mounted) {
        ToastService().showError(errorMessage);
      }
    } on NetworkException catch (e) {
      // 网络异常：连接超时、网络不可用等
      if (mounted) {
        ToastService().showError('Network error: ${e.message}');
      }
    } on ServerException catch (e) {
      // 服务器异常：5xx 错误
      if (mounted) {
        ToastService().showError('Server error: ${e.message}');
      }
    } on ParseException catch (e) {
      // 解析异常：响应格式错误
      if (mounted) {
        ToastService().showError('Data parsing error: ${e.message}');
      }
    } on ApiException catch (e) {
      // 其他 API 异常
      if (mounted) {
        ToastService().showError('API error: ${e.message}');
      }
    } catch (e) {
      // 未知异常
      if (mounted) {
        ToastService().showError('Login failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Don\'t have an account? Register'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
