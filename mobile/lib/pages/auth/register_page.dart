import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/snackbar_manager.dart';
import '../../core/network/network.dart';
import '../../core/network/api_exception.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      SnackBarManager.showInputWarning('Please fill all required fields');
      return;
    }

    if (_passwordController.text.length < 6) {
      SnackBarManager.showInputWarning(
        'Password must be at least 6 characters',
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarManager.showInputWarning('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        username: _usernameController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text.isNotEmpty
            ? _nicknameController.text
            : null,
      );

      if (mounted) {
        SnackBarManager.showSuccess('Registration successful! Please login.');
        context.pop(); // Go back to login
      }
    } on AuthException catch (e) {
      // 认证异常：用户名已存在等
      if (mounted) {
        SnackBarManager.showError('Authentication failed: ${e.message}');
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
        SnackBarManager.showError(errorMessage);
      }
    } on NetworkException catch (e) {
      // 网络异常：连接超时、网络不可用等
      if (mounted) {
        SnackBarManager.showNetworkError(e.message);
      }
    } on ServerException catch (e) {
      // 服务器异常：5xx 错误
      if (mounted) {
        SnackBarManager.showServerError(e.message);
      }
    } on ParseException catch (e) {
      // 解析异常：响应格式错误
      if (mounted) {
        SnackBarManager.showError('Data parsing error: ${e.message}');
      }
    } on ApiException catch (e) {
      // 其他 API 异常
      if (mounted) {
        SnackBarManager.showError('API error: ${e.message}');
      }
    } catch (e) {
      // 未知异常
      if (mounted) {
        SnackBarManager.showError('Registration failed: $e');
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
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
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
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nickname (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.face_outlined),
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
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
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
