import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../assistant/assistant_controller.dart';
import '../../core/services/toast_service.dart';
import '../../core/state/app_state_management.dart';
import '../../core/voice/audio_resource_manager.dart';
import 'enhanced_bottom_navigation.dart';

/// 重构后的主布局
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AssistantController _assistant = AssistantController();
  bool _isSpeechInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _assistant.init();
      if (mounted) {
        setState(() {
          _isSpeechInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
      if (mounted) {
        ToastService().showError('Speech service init failed: $e');
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
    final uiCubit = StateProviders.getUiCubit(context);
    uiCubit.updateBottomNavIndex(index);

    // If currently listening and navigating away from pager, stop listening first
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
    }
  }

  Future<void> _onPagerLongPressed(BuildContext context) async {
    if (!_isSpeechInitialized) {
      if (mounted) {
        ToastService().showWarning(
          'Speech service initializing or failed. Check logs.',
        );
        _initSpeech();
      }
      return;
    }

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ToastService().showWarning('Microphone permission required');
      }
      return;
    }

    // 非阻塞地检查音频资源是否可用，避免长时间阻塞（若被TTS占用则放弃）
    final audioMgr = AudioResourceManager();
    VoidCallback? token;
    try {
      token = await audioMgr.tryAcquire();
      if (token == null) {
        if (mounted) {
          ToastService().showWarning('设备正忙，请稍后重试');
        }
        return;
      }
    } catch (e) {
      // 若检查失败则继续尝试启动，但用户应看到错误
    } finally {
      // 立即释放检查到的临时占用（真正的占用由 startListening 内部获取）
      try {
        token?.call();
      } catch (_) {}
    }

    try {
      setState(() => _isListening = true);
      // 给 startListening 一个短超时，避免长期阻塞
      await _assistant
          .startListening(messageFirst: true)
          .timeout(const Duration(seconds: 6));
      ToastService().showInfo(
        'Listening...',
        duration: const Duration(minutes: 1),
      );
    } on TimeoutException catch (e) {
      setState(() => _isListening = false);
      debugPrint('Start listening timed out: $e');
      ToastService().showWarning('录音启动超时，请稍后重试');
    } catch (e) {
      setState(() => _isListening = false);
      debugPrint('Failed to start recording: $e');
      ToastService().showError('Failed to start recording: $e');
    }
  }

  Future<void> _onPagerLongPressEnd(BuildContext context) async {
    setState(() => _isListening = false);

    ToastService().scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

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
