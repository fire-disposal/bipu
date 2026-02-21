import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../assistant/intent_driven_assistant_controller.dart';
import '../../core/services/toast_service.dart';
import 'enhanced_bottom_navigation.dart';

/// 重构后的主布局 - 使用意图驱动控制器
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final IntentDrivenAssistantController _assistant =
      IntentDrivenAssistantController();
  bool _isSpeechInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // 初始化语音命令中心
      await _assistant.init();
      if (mounted) {
        setState(() {
          _isSpeechInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
      if (mounted) {
        ToastService().showError('语音服务初始化失败: $e');
      }
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/pager')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    _onItemTappedAsync(index, context);
  }

  Future<void> _onItemTappedAsync(int index, BuildContext context) async {
    // 如果当前正在监听且导航离开传呼机页面，先停止监听
    if (_isListening && index != 1) {
      try {
        await _assistant.stopListening();
      } catch (_) {}
      setState(() => _isListening = false);
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/pager');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/profile');
        break;
      default:
        context.go('/home');
    }
  }

  Future<void> _onPagerLongPressed(BuildContext context) async {
    if (!_isSpeechInitialized) {
      if (mounted) {
        ToastService().showWarning('语音服务正在初始化或失败，请检查日志');
        _initSpeech();
      }
      return;
    }

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ToastService().showWarning('需要麦克风权限');
      }
      return;
    }

    try {
      setState(() => _isListening = true);

      // 使用意图驱动控制器开始监听
      await _assistant.startListening();

      ToastService().showInfo('正在监听...', duration: const Duration(minutes: 1));
    } on TimeoutException catch (e) {
      setState(() => _isListening = false);
      debugPrint('开始监听超时: $e');
      ToastService().showWarning('录音启动超时，请稍后重试');
    } catch (e) {
      setState(() => _isListening = false);
      debugPrint('开始录音失败: $e');
      ToastService().showError('开始录音失败: $e');
    }
  }

  Future<void> _onPagerLongPressEnd(BuildContext context) async {
    setState(() => _isListening = false);

    ToastService().scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

    // 使用意图驱动控制器停止监听
    await _assistant.stopListening();

    if (mounted) {
      if (context.mounted) {
        context.go('/pager');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: EnhancedBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        onPagerLongPress: () => _onPagerLongPressed(context),
        onPagerLongPressEnd: () => _onPagerLongPressEnd(context),
        isPagerListening: _isListening,
      ),
    );
  }
}
